import SwiftUI
import CoreGraphics
import UserNotifications
import Combine
import os

class FocusViewModel: ObservableObject {
    @Published var appState: AppState = .active
    @Published var currentView: AppView = .dashboard
    @Published var workTime: Int = 0 
    @Published var config = AppConfig()
    
    @Published var minuteActivity: [Int] = Array(repeating: 0, count: 60)
    @Published var fatigueHeat: [Double] = Array(repeating: 0, count: 60)
    @Published var notificationState: NotificationPermissionState = NotificationAvailability.isAvailable ? .unknown : .unsupported
    @Published var isScreenOff = false
    @Published var dailyActivities: [String: DailyActivityData] = [:]  // Date string -> daily data
    @Published var selectedDate: Date = Date()  // For analytics view
    
    private var screenOffTimestamp: Date?
    private var lastSaveTimestamp: Date = Date()
    var restStartTime: Date? // Internal for AnalyticsView access
    private var currentDayString: String = ""
    
    private var timer: Timer?
    private var lastTickHour: Int = Calendar.current.component(.hour, from: Date())
    private var hasDispatchedWarningNotification = false
    private var notificationStatusObserver: NSObjectProtocol?
    private let persistenceQueue = DispatchQueue(label: "com.MinTik.persistence", qos: .utility)
    private var cancellables: Set<AnyCancellable> = []
    private let defaults = UserDefaults.standard
    private let kDuration = "config.duration"
    private let kActiveThreshold = "config.activeThreshold"
    private let kRestDuration = "config.restDuration"
    private lazy var persistenceURL: URL = {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.homeDirectoryForCurrentUser
        let dir = base.appendingPathComponent("MinTik", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("activity.json")
    }()

    static let shared = FocusViewModel()
    
    private init() {
        loadPersistedConfig()
        loadPersistedActivity()
        loadDailyActivities()
        initializeTodayData()
        notifyStatusBar()
        observeNotificationStatusChanges()
        setupSleepObservers()
        refreshNotificationPermission()
        startLoop()
        $config
            .dropFirst()
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] cfg in
                self?.persistConfig(cfg)
            }
            .store(in: &cancellables)
        
        // Observe launch at login changes
        $config
            .map { $0.launchAtLogin }
            .removeDuplicates()
            .dropFirst()
            .sink { enabled in
                LaunchAtLoginManager.shared.setEnabled(enabled)
            }
            .store(in: &cancellables)
    }
    
    deinit {
        if let observer = notificationStatusObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }
    
    func startLoop() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }
    
    func tick() {
        var didMutate = false
        
        // 0. Check Screen Off / Sleep State
        if isScreenOff {
            if let start = screenOffTimestamp {
                let duration = Date().timeIntervalSince(start)
                if duration >= config.restDuration {
                    if appState != .idle {
                        let focusDuration = workTime
                        let focusStartTime = Date().addingTimeInterval(-Double(focusDuration))
                        dailyActivities[currentDayString]?.recordFocusSession(startTime: focusStartTime, duration: focusDuration)
                        
                        // Don't record rest session here - it will be recorded when user becomes active again
                        // This avoids double-counting rest time
                        restStartTime = screenOffTimestamp // Rest started when screen went off
                        appState = .idle
                        Logger.focus.notice("State changed to IDLE (Screen Off). WorkTime: \(self.workTime)")
                        workTime = 0
                        didMutate = true
                        hasDispatchedWarningNotification = false
                        triggerPeriodicSave()
                        lastSaveTimestamp = Date()
                    }
                } else {
                    // Screen off but not yet idle -> Paused
                    if appState == .active || appState == .warning {
                        appState = .paused
                        Logger.focus.notice("State changed to PAUSED (Screen Off)")
                    }
                }
            }
            notifyStatusBar()
            return
        }
        
        let anyInputEventType = CGEventType(rawValue: ~0)!
        let systemIdleSeconds = CGEventSource.secondsSinceLastEventType(.hidSystemState, eventType: anyInputEventType)
        
        let currentHour = Calendar.current.component(.hour, from: Date())
        let currentMinute = Calendar.current.component(.minute, from: Date())
        let limitSeconds = max(1, Int(config.duration * 60))
        
        if currentHour != lastTickHour {
            // Save last hour's data before resetting
            let totalSecondsLastHour = minuteActivity.reduce(0, +)
            if totalSecondsLastHour > 0 {
                dailyActivities[currentDayString]?.updateHour(lastTickHour, seconds: totalSecondsLastHour)
                dailyActivities[currentDayString]?.minuteHistory[lastTickHour] = minuteActivity
            }
            
            minuteActivity = Array(repeating: 0, count: 60)
            fatigueHeat = Array(repeating: 0, count: 60)
            lastTickHour = currentHour
            didMutate = true
        }
        
        if systemIdleSeconds >= config.restDuration {
            if appState != .idle {
                // End of focus session
                if restStartTime != nil {
                     // This case handles if we were already tracking a rest, but appState wasn't idle (shouldn't happen often)
                     // Actually, if we are entering idle, the previous state was active/warning/paused (Focus)
                }
                
                // Calculate focus duration (approximate based on workTime or time since last rest end)
                // For simplicity, we'll use the current time as the end of focus.
                // Ideally we should track focusStartTime. But for now let's assume focus ends now.
                // Wait, we need focus duration. `workTime` is the accumulated work time.
                // But `workTime` resets on idle. So `workTime` IS the duration of the current focus session.
                let focusDuration = workTime
                let focusStartTime = Date().addingTimeInterval(-Double(focusDuration))
                dailyActivities[currentDayString]?.recordFocusSession(startTime: focusStartTime, duration: focusDuration)
                
                // Rest started when user stopped input
                restStartTime = Date().addingTimeInterval(-systemIdleSeconds)
                appState = .idle
                Logger.focus.notice("State changed to IDLE (User Inactive). WorkTime: \(self.workTime)")
                workTime = 0
                didMutate = true
                hasDispatchedWarningNotification = false
                triggerPeriodicSave()
                lastSaveTimestamp = Date()
            }
            notifyStatusBar()
            return 
        }
        
        if systemIdleSeconds < config.activeThreshold {
            if appState == .idle {
                // End of rest session
                if let start = restStartTime {
                    let actualDuration = Int(Date().timeIntervalSince(start))
                    // Cap rest duration at reset duration to avoid counting long sleep/shutdown as rest
                    let cappedDuration = min(actualDuration, Int(config.restDuration))
                    dailyActivities[currentDayString]?.recordRestSession(startTime: start, duration: cappedDuration)
                    restStartTime = nil
                    didMutate = true
                    triggerPeriodicSave()
                    lastSaveTimestamp = Date()
                }
                appState = .active
                Logger.focus.notice("State changed to ACTIVE (User Active)")
            }
            if appState == .paused { 
                appState = (Double(workTime) >= config.duration * 60) ? .warning : .active 
                Logger.focus.notice("State changed from PAUSED to \(self.appState == .warning ? "WARNING" : "ACTIVE")")
            }
            
            if appState == .active || appState == .warning {
                workTime += 1
                if currentMinute < 60 {
                    minuteActivity[currentMinute] = min(60, minuteActivity[currentMinute] + 1)
                    didMutate = true
                }
                
                if workTime >= limitSeconds {
                    if appState != .warning {
                        appState = .warning
                        Logger.focus.warning("State changed to WARNING (Time Limit Reached)")
                    }
                    if currentMinute < 60 {
                        let overrun = max(0, workTime - limitSeconds)
                        let severity = min(1.0, Double(overrun) / Double(limitSeconds))
                        let newLevel = max(fatigueHeat[currentMinute], severity)
                        if fatigueHeat[currentMinute] != newLevel {
                            fatigueHeat[currentMinute] = newLevel
                            didMutate = true
                        }
                    }
                    dispatchWarningNotificationIfNeeded()
                } else {
                    hasDispatchedWarningNotification = false
                    // Fix: If duration threshold is increased, recover from warning state
                    if appState == .warning {
                        appState = .active
                        Logger.focus.notice("State recovered to ACTIVE (Limit Increased)")
                    }
                }
            }
        } else {
            if appState == .active || appState == .warning {
                appState = .paused
                Logger.focus.notice("State changed to PAUSED (User Inactive but < RestDuration)")
            }
        }
        
        // Update current hour with latest minute activity data
        syncCurrentHourFromMinuteActivity()
        
        if didMutate {
            let now = Date()
            if now.timeIntervalSince(lastSaveTimestamp) >= 300 { // Save every 5 minutes
                triggerPeriodicSave()
                lastSaveTimestamp = now
            }
        }
        
        notifyStatusBar()
    }
    
    var formattedTime: String {
        let mins = workTime / 60
        let secs = workTime % 60
        return String(format: "%02d:%02d", mins, secs)
    }
    
    func refreshNotificationPermission() {
        print("🔄 Refreshing notification permission...")
        guard NotificationAvailability.isAvailable else {
            print("❌ Notification availability check failed")
            notificationState = .unsupported
            return
        }
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            print("📊 Notification settings received: \(settings.authorizationStatus.rawValue)")
            DispatchQueue.main.async {
                self?.notificationState = NotificationPermissionState(status: settings.authorizationStatus)
                print("✅ State updated to: \(self?.notificationState ?? .unknown)")
            }
        }
    }
    
    func requestNotificationPermission() {
        print("🚀 Requesting notification permission...")
        guard NotificationAvailability.isAvailable else { 
            print("❌ Cannot request: Notifications unavailable")
            return 
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { [weak self] granted, error in
            print("📝 Authorization result: granted=\(granted), error=\(String(describing: error))")
            DispatchQueue.main.async {
                self?.refreshNotificationPermission()
            }
        }
    }
    
    func openNotificationPreferences() {
        guard NotificationAvailability.isAvailable else { return }
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func completeOnboarding() {
        config.isFirstLaunch = false
        saveConfig()
        NotificationCenter.default.post(name: Notification.Name("MinTikOnboardingCompleted"), object: nil)
    }
    
    // MARK: - Public Save Method
    
    private func triggerPeriodicSave() {
        Logger.persistence.debug("Triggering periodic save")
        syncCurrentHourFromMinuteActivity()
        persistActivity()
        saveDailyActivities()
    }
    
    /// Save all data immediately (called on app exit, sleep, shutdown)
    func saveAllData() {
        // Sync current hour data from minute activity
        syncCurrentHourFromMinuteActivity()
        
        // Save both files synchronously to ensure data is written
        persistActivity()
        saveDailyActivities()
        
        // Wait for persistence queue to finish
        persistenceQueue.sync {}
        
        Logger.persistence.notice("All data saved successfully (Synchronous)")
        print("All data saved successfully")
    }
    
    // MARK: - Activity Persistence
    
    private func loadPersistedActivity() {
        guard let data = try? Data(contentsOf: persistenceURL),
              let snapshot = try? JSONDecoder().decode(ActivitySnapshot.self, from: data) else { return }
        minuteActivity = snapshot.minuteActivity.count == 60 ? snapshot.minuteActivity : Array(repeating: 0, count: 60)
        workTime = snapshot.workTime
        lastTickHour = snapshot.lastTickHour
        fatigueHeat = snapshot.fatigueHeat.count == 60 ? snapshot.fatigueHeat : Array(repeating: 0, count: 60)
    }

    private func persistActivity() {
        let snapshot = ActivitySnapshot(
            minuteActivity: minuteActivity,
            workTime: workTime,
            lastTickHour: lastTickHour,
            fatigueHeat: fatigueHeat
        )
        let url = persistenceURL
        persistenceQueue.async {
            guard let data = try? JSONEncoder().encode(snapshot) else { return }
            try? data.write(to: url, options: .atomic)
        }
    }

    private func saveConfig() {
        guard let encoded = try? JSONEncoder().encode(config) else { return }
        defaults.set(encoded, forKey: "appConfig")
    }

    private func loadPersistedConfig() {
        // Try loading from new JSON storage first
        if let data = defaults.data(forKey: "appConfig"),
           let decoded = try? JSONDecoder().decode(AppConfig.self, from: data) {
            config = decoded
            return
        }
        
        // Fallback to legacy individual keys for migration (if needed)
        var newConfig = AppConfig()
        if defaults.object(forKey: kDuration) != nil {
            newConfig.duration = defaults.double(forKey: kDuration)
        }
        if defaults.object(forKey: kActiveThreshold) != nil {
            newConfig.activeThreshold = defaults.double(forKey: kActiveThreshold)
        }
        if defaults.object(forKey: kRestDuration) != nil {
            newConfig.restDuration = defaults.double(forKey: kRestDuration)
        }
        
        // Check if it's really first launch (legacy check)
        if defaults.object(forKey: kDuration) != nil {
            newConfig.isFirstLaunch = false
        }
        
        
        config = newConfig
    }

    private func persistConfig(_ cfg: AppConfig) {
        persistenceQueue.async { [defaults] in
            if let data = try? JSONEncoder().encode(cfg) {
                defaults.set(data, forKey: "appConfig")
                defaults.synchronize()
            }
        }
    }
    
    // MARK: - Notifications
    
    private func notifyStatusBar() {
        let minutes = max(workTime / 60, 0)
        let state: String
        switch appState {
        case .warning:
            state = "warning"
        case .paused:
            state = "paused"
        case .idle:
            state = "idle"
        default:
            state = "active"
        }
        NotificationCenter.default.post(
            name: .MinTikStatusUpdate,
            object: nil,
            userInfo: ["minutes": minutes, "state": state]
        )
    }
    
    private func observeNotificationStatusChanges() {
        guard NotificationAvailability.isAvailable else { return }
        notificationStatusObserver = NotificationCenter.default.addObserver(forName: .MinTikNotificationStatusChanged, object: nil, queue: .main) { [weak self] notification in
            guard let raw = notification.userInfo?["status"] as? Int,
                  let status = UNAuthorizationStatus(rawValue: raw) else { return }
            self?.notificationState = NotificationPermissionState(status: status)
        }
        
        // Refresh permission when app becomes active (e.g. returning from System Settings)
        NotificationCenter.default.addObserver(forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refreshNotificationPermission()
            self?.syncLaunchAtLoginStatus()
        }
    }
    
    /// Sync launch at login status from system
    private func syncLaunchAtLoginStatus() {
        let actualStatus = LaunchAtLoginManager.shared.syncStatus()
        if config.launchAtLogin != actualStatus {
            config.launchAtLogin = actualStatus
        }
    }
    
    private func dispatchWarningNotificationIfNeeded() {
        guard NotificationAvailability.isAvailable else { return }
        guard !hasDispatchedWarningNotification else { return }
        hasDispatchedWarningNotification = true
        let minutes = max(workTime / 60, Int(config.duration))
        let content = UNMutableNotificationContent()
        content.title = "该休息一下啦"
        content.body = "已连续专注 \(minutes) 分钟，起身活动一下吧。"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "MinTik.warning.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    // MARK: - Sleep / Screen Observers
    
    private func setupSleepObservers() {
        let nc = NSWorkspace.shared.notificationCenter
        nc.addObserver(self, selector: #selector(handleScreenSleep), name: NSWorkspace.screensDidSleepNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleScreenWake), name: NSWorkspace.screensDidWakeNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleSystemSleep), name: NSWorkspace.willSleepNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleSystemWake), name: NSWorkspace.didWakeNotification, object: nil)
        nc.addObserver(self, selector: #selector(handleSystemPowerOff), name: NSWorkspace.willPowerOffNotification, object: nil)
    }
    
    @objc private func handleScreenSleep() {
        Logger.lifecycle.notice("Screen Sleep Detected")
        print("Screen Sleep Detected")
        isScreenOff = true
        screenOffTimestamp = Date()
        // Save data before screen sleeps
        saveAllData()
    }
    
    @objc private func handleScreenWake() {
        Logger.lifecycle.notice("Screen Wake Detected")
        print("Screen Wake Detected")
        checkSleepDuration()
        isScreenOff = false
        screenOffTimestamp = nil
    }
    
    @objc private func handleSystemSleep() {
        Logger.lifecycle.notice("System Sleep Detected")
        print("System Sleep Detected")
        // Save data before system sleeps
        saveAllData()
        isScreenOff = true
        screenOffTimestamp = Date()
    }
    
    @objc private func handleSystemWake() {
        Logger.lifecycle.notice("System Wake Detected")
        print("System Wake Detected")
        checkSleepDuration()
        isScreenOff = false
        screenOffTimestamp = nil
    }
    
    @objc private func handleSystemPowerOff() {
        Logger.lifecycle.notice("System Power Off Detected")
        print("System Power Off Detected - Saving all data")
        // Save data before system shuts down
        saveAllData()
    }
    
    private func checkSleepDuration() {
        guard let start = screenOffTimestamp else { return }
        let sleptTime = Date().timeIntervalSince(start)
        if sleptTime >= config.restDuration {
            if appState != .idle {
                let focusDuration = workTime
                let focusStartTime = Date().addingTimeInterval(-Double(focusDuration))
                dailyActivities[currentDayString]?.recordFocusSession(startTime: focusStartTime, duration: focusDuration)
                
                // Don't record rest session here - it will be recorded when user becomes active again
                // This avoids double-counting rest time
                restStartTime = screenOffTimestamp
                appState = .idle
                workTime = 0
                triggerPeriodicSave()
                lastSaveTimestamp = Date()
                notifyStatusBar()
            }
        }
    }
    
    // MARK: - Data Access Helpers
    
    func getMinuteHistory(for hour: Int) -> [Int] {
        // If requesting current hour, return live data
        let currentHour = Calendar.current.component(.hour, from: Date())
        if hour == currentHour {
            return minuteActivity
        }
        
        // Otherwise return historical data
        return dailyActivities[currentDayString]?.minuteHistory[hour] ?? Array(repeating: 0, count: 60)
    }
    
    var earliestRecordedHour: Int {
        let currentHour = Calendar.current.component(.hour, from: Date())
        guard let history = dailyActivities[currentDayString]?.minuteHistory else { return currentHour }
        let recordedHours = history.keys
        return recordedHours.min() ?? currentHour
    }
    
    // MARK: - Daily Activity Tracking
    
    private func initializeTodayData() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        currentDayString = formatter.string(from: Date())
        
        if dailyActivities[currentDayString] == nil {
            dailyActivities[currentDayString] = DailyActivityData(dateString: currentDayString)
        }
        
        // Sync current hour with existing minuteActivity data
        syncCurrentHourFromMinuteActivity()
    }
    
    private func syncCurrentHourFromMinuteActivity() {
        let currentHour = Calendar.current.component(.hour, from: Date())
        // Sum up the minuteActivity to get total seconds active this hour
        let totalSecondsThisHour = minuteActivity.reduce(0, +)
        if totalSecondsThisHour > 0 {
            dailyActivities[currentDayString]?.updateHour(currentHour, seconds: totalSecondsThisHour)
        }
    }
    
    private func loadDailyActivities() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.homeDirectoryForCurrentUser
        let dir = base.appendingPathComponent("MinTik", isDirectory: true)
        let dailyURL = dir.appendingPathComponent("daily_activities.json")
        
        guard let data = try? Data(contentsOf: dailyURL),
              let loaded = try? JSONDecoder().decode([String: DailyActivityData].self, from: data) else {
            return
        }
        
        // Load all data permanently - no retention limit
        dailyActivities = loaded
    }
    
    private func saveDailyActivities() {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.homeDirectoryForCurrentUser
        let dir = base.appendingPathComponent("MinTik", isDirectory: true)
        let dailyURL = dir.appendingPathComponent("daily_activities.json")
        
        persistenceQueue.async { [dailyActivities] in
            guard let data = try? JSONEncoder().encode(dailyActivities) else { return }
            try? data.write(to: dailyURL, options: .atomic)
        }
    }
    
    func getDailyData(for date: Date) -> DailyActivityData? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return dailyActivities[dateString]
    }
    
    // MARK: - Data Management
    
    func clearAllData() {
        // 1. Reset in-memory state
        minuteActivity = Array(repeating: 0, count: 60)
        fatigueHeat = Array(repeating: 0, count: 60)
        workTime = 0
        dailyActivities = [:]
        appState = .active // Reset to active state
        
        // Re-initialize today's empty data
        initializeTodayData()
        
        // 2. Clear persistence files
        persistenceQueue.async { [weak self] in
            guard let self = self else { return }
            let fm = FileManager.default
            
            // Delete activity.json
            try? fm.removeItem(at: self.persistenceURL)
            
            // Delete daily_activities.json
            let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.homeDirectoryForCurrentUser
            let dir = base.appendingPathComponent("MinTik", isDirectory: true)
            let dailyURL = dir.appendingPathComponent("daily_activities.json")
            try? fm.removeItem(at: dailyURL)
            
            // 3. Clear UserDefaults (Config) to trigger onboarding on next launch
            self.defaults.removeObject(forKey: "appConfig")
            self.defaults.synchronize()
            
            print("🧹 All data cleared. Quitting app...")
            
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }
}
