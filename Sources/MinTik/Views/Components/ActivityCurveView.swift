import SwiftUI
import Charts

struct ActivityCurveView: View {
    let vm: FocusViewModel  // Changed from hourlyData to vm for accessing minute history
    let isToday: Bool
    var textPrimary: Color
    var textSecondary: Color
    var inactiveBlock: Color
    var accent: Color
    
    @State private var chartDataState: [MinuteDataPoint] = []
    @State private var xLabelsState: [Int] = []
    @State private var xStartState: Int = 0
    @State private var xEndState: Int = 0
    @State private var isComputing: Bool = false
    @State private var chartId: UUID = UUID()  // Add chart ID for forcing re-render
    
    // Data model for the chart - now using minutes
    struct MinuteDataPoint: Identifiable {
        var id: Int { minute }  // Use minute as ID instead of UUID for stability
        let minute: Int  // Absolute minute from 0 (00:00) to 1439 (23:59)
        let seconds: Int
    }
    
    private var selectedDayData: DailyActivityData? {
        vm.getDailyData(for: vm.selectedDate)
    }
    
    // Find first minute with activity
    private func compute() {
        guard !isComputing else { return }
        isComputing = true
        let date = vm.selectedDate
        let isTodayFlag = Calendar.current.isDateInToday(date)
        let viewModel = vm  // Capture vm reference
        
        DispatchQueue.global(qos: .userInitiated).async {
            // Get data for the selected date inside the async closure
            let dayData = viewModel.getDailyData(for: date)
            let history = dayData?.minuteHistory
            
            var first = 0
            var last = 1439
            if let history = history {
                outer: for hour in 0..<24 {
                    if let minuteData = history[hour] {
                        if let idx = minuteData.enumerated().first(where: { $0.element > 0 })?.offset {
                            first = hour * 60 + idx
                            break outer
                        }
                    }
                }
                outer2: for hour in (0..<24).reversed() {
                    if let minuteData = history[hour] {
                        if let idx = minuteData.enumerated().reversed().first(where: { $0.element > 0 })?.offset {
                            last = hour * 60 + idx
                            break outer2
                        }
                    }
                }
            }
            let startHour = first / 60
            let xStart = startHour * 60
            var xEnd: Int
            if isTodayFlag {
                let currentHour = Calendar.current.component(.hour, from: Date())
                let currentMinute = Calendar.current.component(.minute, from: Date())
                let currentAbsoluteMinute = currentHour * 60 + currentMinute
                xEnd = max(currentAbsoluteMinute, xStart + 120)
            } else {
                let endHour = (last / 60) + 1
                xEnd = min(endHour * 60, 1439)
            }
            
            let startH = xStart / 60
            let endH = (xEnd + 59) / 60  // Round up to include the hour containing xEnd
            var labels: [Int] = []
            let range = endH - startH
            let gap: Int
            if range <= 2 { gap = 1 } else if range <= 6 { gap = 2 } else if range <= 12 { gap = 3 } else { gap = 4 }
            var cur = startH
            while cur <= endH { labels.append(cur * 60); cur += gap }
            if labels.last != endH * 60 { labels.append(endH * 60) }
            var points: [MinuteDataPoint] = []
            if let history = history {
                // Get the current hour from the actual current time for real-time data
                let currentHour = Calendar.current.component(.hour, from: Date())
                
                for hour in startH...endH {
                    let minuteData: [Int]
                    // Use real-time minuteActivity only for today AND the current hour
                    if isTodayFlag && hour == currentHour {
                        minuteData = viewModel.minuteActivity
                    } else {
                        minuteData = history[hour] ?? Array(repeating: 0, count: 60)
                    }
                    for minute in 0..<60 {
                        let absoluteMinute = hour * 60 + minute
                        if absoluteMinute >= xStart && absoluteMinute <= xEnd {
                            points.append(MinuteDataPoint(minute: absoluteMinute, seconds: minuteData[minute]))
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.xStartState = xStart
                self.xEndState = xEnd
                self.xLabelsState = labels
                self.chartDataState = points
                self.chartId = UUID()  // Generate new ID to force chart re-render
                self.isComputing = false
            }
        }
    }
    
    // Find last minute with activity
    private var lastActiveMinute: Int {
        guard let history = selectedDayData?.minuteHistory else { return 1439 }
        
        for hour in (0..<24).reversed() {
            if let minuteData = history[hour] {
                if let lastMinute = minuteData.enumerated().reversed().first(where: { $0.element > 0 })?.offset {
                    return hour * 60 + lastMinute
                }
            }
        }
        return 1439
    }
    
    // Calculate dynamic X-axis range (in minutes)
    private var xAxisStart: Int { xStartState }
    private var xAxisEnd: Int { xEndState }
    
    // Generate smart axis labels (in minutes, but display as hours)
    private var xAxisLabels: [Int] { xLabelsState }
    
    private var chartData: [MinuteDataPoint] { chartDataState }
    
    private var maxY: Int {
        max(chartData.map { $0.seconds }.max() ?? 0, 1)
    }
    
    private var chartColor: Color { accent }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                // Chart Content
                Chart(chartData) { point in
                    // Gradient Area
                    AreaMark(
                        x: .value("Minute", point.minute),
                        y: .value("Activity", point.seconds)
                    )
                    .interpolationMethod(.catmullRom)  // Smooth curve for minute-level data
                    .foregroundStyle(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                chartColor.opacity(0.35),
                                chartColor.opacity(0.06)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Line
                    LineMark(
                        x: .value("Minute", point.minute),
                        y: .value("Activity", point.seconds)
                    )
                    .interpolationMethod(.catmullRom)  // Smooth curve for minute-level data
                    .lineStyle(StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .foregroundStyle(chartColor.opacity(0.85))
                }
                .chartXScale(domain: xAxisStart...xAxisEnd)
                .chartYScale(domain: 0...Double(maxY) * 1.5)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: xAxisLabels) { value in
                        AxisValueLabel(collisionResolution: .greedy) {
                            if let intValue = value.as(Int.self) {
                                let hour = intValue / 60
                                Text(String(format: "%02d:00", hour))
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(textSecondary.opacity(0.6))
                            }
                        }
                    }
                }
                .id(chartId)  // Force chart to re-render when chartId changes
                .padding(.top, 20)
                .padding(.horizontal, 10)
                .padding(.bottom, 5)
                .onAppear { compute() }
                .onChange(of: vm.selectedDate) { _ in compute() }
            }
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(inactiveBlock.opacity(0.85))
            )
            .overlay(
                HStack(spacing: 6) {
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textSecondary.opacity(0.7))
                    
                    Text("系统活跃曲线")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textSecondary.opacity(0.7))
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 10),
                alignment: .topLeading
            )
        }
    }
}



