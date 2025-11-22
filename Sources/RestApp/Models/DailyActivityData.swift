import Foundation

struct DailyActivityData: Codable, Identifiable {
    var id: String { dateString }
    let dateString: String  // Format: "yyyy-MM-dd"
    var hourlyActivity: [Int]  // 24 elements, seconds active per hour
    var minuteHistory: [Int: [Int]] = [:] // Hour (0-23) -> [60 elements] (seconds active per minute)
    var peakHour: Int?  // 0-23, hour with most activity
    var totalActiveTime: Int  // Total seconds active in the day
    
    var focusSessionCount: Int = 0
    var restSessionCount: Int = 0
    var totalRestTime: Int = 0 // Seconds
    
    init(date: Date) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        self.dateString = formatter.string(from: date)
        self.hourlyActivity = Array(repeating: 0, count: 24)
        self.minuteHistory = [:]
        self.peakHour = nil
        self.totalActiveTime = 0
        self.focusSessionCount = 0
        self.restSessionCount = 0
        self.totalRestTime = 0
    }
    
    init(dateString: String) {
        self.dateString = dateString
        self.hourlyActivity = Array(repeating: 0, count: 24)
        self.minuteHistory = [:]
        self.peakHour = nil
        self.totalActiveTime = 0
        self.focusSessionCount = 0
        self.restSessionCount = 0
        self.totalRestTime = 0
    }
    
    mutating func updateHour(_ hour: Int, seconds: Int) {
        guard hour >= 0 && hour < 24 else { return }
        hourlyActivity[hour] = seconds
        recalculate()
    }
    
    // MARK: - Session Tracking
    
    struct ActivitySession: Codable, Identifiable {
        var id: Date { startTime }
        let startTime: Date
        let duration: Int // Seconds
        let type: SessionType
        
        enum SessionType: String, Codable {
            case focus
            case rest
        }
    }
    
    var sessions: [ActivitySession] = []
    
    mutating func recordFocusSession(startTime: Date, duration: Int) {
        focusSessionCount += 1
        sessions.append(ActivitySession(startTime: startTime, duration: duration, type: .focus))
    }
    
    mutating func recordRestSession(startTime: Date, duration: Int) {
        restSessionCount += 1
        totalRestTime += duration
        sessions.append(ActivitySession(startTime: startTime, duration: duration, type: .rest))
    }
    
    private mutating func recalculate() {
        // Update total
        totalActiveTime = hourlyActivity.reduce(0, +)
        
        // Find peak hour
        if let maxIndex = hourlyActivity.enumerated().max(by: { $0.element < $1.element })?.offset {
            peakHour = hourlyActivity[maxIndex] > 0 ? maxIndex : nil
        } else {
            peakHour = nil
        }
    }
    
    func peakTime() -> String? {
        guard let peak = peakHour else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:00 a"
        formatter.locale = Locale(identifier: "zh_CN")
        
        var components = DateComponents()
        components.hour = peak
        if let date = Calendar.current.date(from: components) {
            return formatter.string(from: date)
        }
        return nil
    }
    
    // MARK: - Rhythm Metrics
    
    var cumulativeFocusTime: Int {
        totalActiveTime
    }
    
    var cumulativeRestTime: Int {
        totalRestTime
    }
    
    var focusRestRatio: Double {
        guard totalRestTime > 0 else { return Double(totalActiveTime > 0 ? 99 : 0) }
        return Double(totalActiveTime) / Double(totalRestTime)
    }
}
