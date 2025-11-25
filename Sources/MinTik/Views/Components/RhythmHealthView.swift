import SwiftUI

struct RhythmHealthView: View {
    let data: DailyActivityData?
    let currentSession: DailyActivityData.ActivitySession?
    let config: AppConfig // New input
    var textPrimary: Color
    var textSecondary: Color
    var inactiveBlock: Color
    var accent: Color
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var cumulativeFocus: String {
        guard let d = data, d.cumulativeFocusTime > 0 else { return "--" }
        return formatDuration(d.cumulativeFocusTime)
    }
    
    private var cumulativeRest: String {
        guard let d = data, d.cumulativeRestTime > 0 else { return "--" }
        return formatDuration(d.cumulativeRestTime)
    }
    
    private var ratio: String {
        guard let d = data, d.totalRestTime > 0 else { return "--" }
        return String(format: "%.1f", d.focusRestRatio)
    }
    
    private var status: (text: String, color: Color) {
        guard let d = data, d.totalRestTime > 0 else {
            return ("暂无数据", textSecondary)
        }
        
        let actualRatio = d.focusRestRatio
        let restDurationMinutes = config.restDuration / 60.0
        // Calculate base ratio: Focus Duration / Rest Duration
        let baseRatio = restDurationMinutes > 0 ? (config.duration / restDurationMinutes) : 5.0
        
        if actualRatio > 1.5 * baseRatio {
            return ("注意休息", Color(hex: "FF6B6B")) // Red (Coral)
        } else if actualRatio >= 1.2 * baseRatio {
            return ("节奏良好", Color(hex: "FFC107")) // Amber
        } else if actualRatio >= 0.8 * baseRatio {
            return ("节奏极佳", Color(hex: "4CAF50")) // Green
        } else if actualRatio >= 0.5 * baseRatio {
            return ("节奏良好", Color(hex: "FFC107")) // Amber
        } else {
            return ("正在努力", Color(hex: "2196F3")) // Blue
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 13))
                    .foregroundColor(accent)
                
                Text("节奏健康度")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(textSecondary)
                
                Spacer()
                
                // Status Badge
                Text(status.text)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(status.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(status.color.opacity(0.15))
                    .cornerRadius(4)
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(status.color.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Metrics Grid
            HStack(spacing: 0) {
                // Cumulative Focus
                VStack(alignment: .center, spacing: 4) {
                    Text("累积专注")
                        .font(.system(size: 10))
                        .foregroundColor(textSecondary.opacity(0.7))
                    Text(cumulativeFocus)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(textPrimary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 20)
                    .background(textSecondary.opacity(0.2))
                
                // Cumulative Rest
                VStack(alignment: .center, spacing: 4) {
                    Text("累积休息")
                        .font(.system(size: 10))
                        .foregroundColor(textSecondary.opacity(0.7))
                    Text(cumulativeRest)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(textPrimary)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 20)
                    .background(textSecondary.opacity(0.2))
                
                // Ratio
                VStack(alignment: .center, spacing: 4) {
                    Text("专注休息比")
                        .font(.system(size: 10))
                        .foregroundColor(textSecondary.opacity(0.7))
                    HStack(spacing: 2) {
                        Text(ratio)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(accent)
                        Text(":")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(textSecondary)
                            .padding(.bottom, 1)
                        Text("1")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(textSecondary)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(inactiveBlock.opacity(0.65))
            )
            
            // Recent Cycle Timeline
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("近期循环 (近4小时)")
                        .font(.system(size: 11))
                        .foregroundColor(textSecondary.opacity(0.7))
                    Spacer()
                    Text("旧 → 新")
                        .font(.system(size: 10))
                        .foregroundColor(textSecondary.opacity(0.5))
                }
                
                // Timeline Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(inactiveBlock.opacity(0.65))
                        
                        // Sessions
                        let sessions = (data?.sessions ?? []) + (currentSession != nil ? [currentSession!] : [])
                        if !sessions.isEmpty {
                            let now = Date()
                            let fourHoursAgo = now.addingTimeInterval(-4 * 3600)
                            let totalDuration: Double = 4 * 3600
                            
                            ForEach(sessions.filter { $0.startTime.addingTimeInterval(Double($0.duration)) > fourHoursAgo }) { session in
                                let start = max(session.startTime, fourHoursAgo)
                                let end = min(session.startTime.addingTimeInterval(Double(session.duration)), now)
                                let duration = end.timeIntervalSince(start)
                                
                                if duration > 0 {
                                    let offset = start.timeIntervalSince(fourHoursAgo) / totalDuration * geo.size.width
                                    let width = duration / totalDuration * geo.size.width
                                    
                                    if session.type == .focus {
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(accent)
                                            .frame(width: max(2, width), height: 12)
                                            .offset(x: offset)
                                    } else {
                                        // Striped pattern for rest (simulated with opacity/overlay)
                                        RoundedRectangle(cornerRadius: 4)
                                            .fill(textSecondary.opacity(0.3))
                                            .frame(width: max(2, width), height: 12)
                                            .offset(x: offset)
                                            .overlay(
                                                HatchPattern()
                                                    .stroke(textSecondary.opacity(0.2), lineWidth: 1)
                                                    .frame(width: max(2, width), height: 12)
                                                    .offset(x: offset)
                                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                                            )
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(height: 12)
                
                // Legend
                HStack(spacing: 16) {
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(accent)
                            .frame(width: 8, height: 8)
                        Text("专注")
                            .font(.system(size: 10))
                            .foregroundColor(textSecondary)
                    }
                    HStack(spacing: 4) {
                        Circle()
                            .fill(textSecondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                        Text("休息")
                            .font(.system(size: 10))
                            .foregroundColor(textSecondary)
                    }
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(inactiveBlock.opacity(0.8))
        )
    }
}

struct HatchPattern: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 4
        for x in stride(from: 0, to: rect.width + rect.height, by: spacing) {
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x - rect.height, y: rect.height))
        }
        return path
    }
}
