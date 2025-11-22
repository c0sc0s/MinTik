import SwiftUI

struct AnalyticsView: View {
    @ObservedObject var vm: FocusViewModel
    var textPrimary: Color
    var textSecondary: Color
    var accent: Color
    var inactiveBlock: Color
    
    private var selectedDayData: DailyActivityData? {
        vm.getDailyData(for: vm.selectedDate)
    }
    
    private var hourlyData: [Int] {
        selectedDayData?.hourlyActivity ?? Array(repeating: 0, count: 24)
    }
    // Compute earliest date with activity data
    private var earliestAvailableDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dates = vm.dailyActivities.keys.compactMap { formatter.date(from: $0) }
        return dates.min()
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 8) { // Reduced spacing        
                // Date Selector
                DateSelector(
                    selectedDate: $vm.selectedDate,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    inactiveBlock: inactiveBlock,
                    earliestDate: earliestAvailableDate
                )
                .padding(.horizontal, 25)
                .padding(.top, 4)
                
                // Activity Curve
                ActivityCurveView(
                    vm: vm,
                    isToday: Calendar.current.isDateInToday(vm.selectedDate),
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    inactiveBlock: inactiveBlock,
                    accent: accent
                )
                .padding(.horizontal, 25)
                
                // Rhythm Health
            RhythmHealthView(
                data: selectedDayData,
                currentSession: currentSession,
                config: vm.config,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                inactiveBlock: inactiveBlock,
                accent: accent
            )
            .padding(.horizontal, 25)
            
            Spacer()
        }
        .padding(.bottom, 20) // Add some bottom padding for scrolling
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var currentSession: DailyActivityData.ActivitySession? {
        // Only show current session if viewing today
        guard Calendar.current.isDateInToday(vm.selectedDate) else { return nil }
        
        if vm.appState == .idle {
            // Currently resting
            if let start = vm.restStartTime {
                let duration = Int(Date().timeIntervalSince(start))
                return DailyActivityData.ActivitySession(startTime: start, duration: duration, type: .rest)
            }
        } else {
            // Currently focusing (active, warning, paused)
            // We approximate focus start by subtracting workTime from now.
            // Note: workTime is accumulated active time, so this visualizes "how much work done" 
            // ending at "now", which is a reasonable representation for the timeline.
            if vm.workTime > 0 {
                let duration = vm.workTime
                let start = Date().addingTimeInterval(-Double(duration))
                return DailyActivityData.ActivitySession(startTime: start, duration: duration, type: .focus)
            }
        }
        return nil
    }
}
