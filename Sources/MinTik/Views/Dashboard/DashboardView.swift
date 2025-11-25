import SwiftUI

struct FocusDashboardView: View {
    @ObservedObject var vm: FocusViewModel
    var isDarkMode: Bool
    var textPrimary: Color
    var textSecondary: Color
    var inactiveBlock: Color
    var accent: Color
    var warningColor: Color
    var pausedColor: Color
    var primaryColor: Color
    var alertColor: Color
    
    @State private var isHoveringTag = false
    @State private var displayHour: Int? = nil
    @State private var hoveredMinute: Int? = nil
    @State private var pendingHoverClear: DispatchWorkItem? = nil
    private var matrixHeaderHeight: CGFloat { 24 }
    private var navButtonSize: CGFloat { 20 }
    
    // 10列布局，间距更小
    let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 10) // Reduced spacing 4->2
    
    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }
    
    private var activeDisplayHour: Int {
        displayHour ?? currentHour
    }
    
    private var matrixData: [Int] {
        vm.getMinuteHistory(for: activeDisplayHour)
    }
    
    private var timeRangeString: String {
        let start = activeDisplayHour
        let end = (start + 1) % 24
        return String(format: "%02d:00 - %02d:00", start, end)
    }

    private var hoveredInfoText: String? {
        guard let m = hoveredMinute, matrixData.indices.contains(m) else { return nil }
        let seconds = matrixData[m]
        return String(format: "%02d:%02d · %d秒", activeDisplayHour, m, seconds)
    }
    
    private var canGoBack: Bool {
        activeDisplayHour > vm.earliestRecordedHour
    }
    
    private var canGoNext: Bool {
        activeDisplayHour < currentHour
    }
    
    private func prevPage() {
        withAnimation {
            displayHour = activeDisplayHour - 1
        }
    }
    
    private func nextPage() {
        withAnimation {
            let next = activeDisplayHour + 1
            if next >= currentHour {
                displayHour = nil // Reset to live view
            } else {
                displayHour = next
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Timer Area
            VStack(alignment: .leading, spacing: 4) { // Reduced spacing 8->4
                HStack(alignment: .top, spacing: 8) {
                    Text(vm.formattedTime)
                        .font(.system(size: vm.workTime / 60 >= 100 ? 42 : 58, weight: .bold, design: .monospaced)) 
                        .monospacedDigit()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundColor(
                            vm.appState == .warning ? warningColor.opacity(0.9) : 
                            (vm.appState == .idle ? Color.green.opacity(0.7) : 
                            (vm.appState == .paused ? pausedColor.opacity(0.75) : textPrimary.opacity(0.9)))
                        )
                        .tracking(vm.workTime / 60 >= 100 ? 0.5 : 2)
                        .kerning(vm.workTime / 60 >= 100 ? 0.5 : 1.2)
                        .animation(.easeOut(duration: 0.5), value: vm.appState == .active)
                        .shadow(color: (vm.appState == .warning ? warningColor : 
                                       (vm.appState == .idle ? Color.green : 
                                       (vm.appState == .paused ? pausedColor : accent))).opacity(0.15), 
                                radius: 12, x: 0, y: 4)
                        .frame(height: 80)

                    Spacer()

                    ZStack {
                        Text("\(Int(vm.config.duration))分钟")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .opacity(0)
                        Text(isHoveringTag ? "设置" : "\(Int(vm.config.duration))分钟")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(isHoveringTag ? textPrimary : textSecondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isHoveringTag ? textSecondary.opacity(0.2) : inactiveBlock)
                    )
                    .onHover { hovering in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isHoveringTag = hovering
                        }
                        if hovering {
                            NSCursor.pointingHand.push()
                        } else {
                            NSCursor.pop()
                        }
                    }
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                            vm.currentView = .settings
                        }
                    }
                    .offset(y: 20)
                }
            }
            .padding(.bottom, 10) // Reduced padding 25->10
            
            // Matrix Header with Pagination
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Group {
                        if canGoBack {
                            Button(action: prevPage) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(textSecondary)
                                    .frame(width: navButtonSize, height: navButtonSize)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity)
                        } else {
                            Rectangle().fill(Color.clear).frame(width: navButtonSize, height: navButtonSize)
                        }
                    }
                    Text(timeRangeString)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(textSecondary)
                        .monospacedDigit()
                    Group {
                        if canGoNext {
                            Button(action: nextPage) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(textSecondary)
                                    .frame(width: navButtonSize, height: navButtonSize)
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .transition(.opacity)
                        } else {
                            Rectangle().fill(Color.clear).frame(width: navButtonSize, height: navButtonSize)
                        }
                    }
                }
                Spacer()
                if let info = hoveredInfoText {
                    Text(info)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(inactiveBlock.opacity(0.8))
                        .cornerRadius(4)
                        .lineLimit(1)
                        .transition(.opacity)
                }
            }
            .frame(height: matrixHeaderHeight)
            .padding(.bottom, 4) // Reduced padding 8->4
            .animation(.easeInOut(duration: 0.2), value: displayHour)
            
            // Heatmap Grid
            LazyVGrid(columns: columns, spacing: 2) { // Reduced spacing 4->2
                ForEach(0..<60, id: \.self) { index in
                    let activeSeconds = matrixData[index]
                    
                    let currentMinute = Calendar.current.component(.minute, from: Date())
                    // Only dim future minutes if we are viewing the current hour
                    let isFuture = (activeDisplayHour == currentHour) && (index > currentMinute)
                    let isCurrent = (activeDisplayHour == currentHour) && (index == currentMinute)
                    
                    let opacity = Double(activeSeconds) / 60.0
                    let activeColor = primaryColor
                    // Fatigue heat is only relevant for current hour in current implementation
                    // (unless we persist fatigue heat too, but plan didn't include that. So only show fatigue for current hour)
                    let fatigueLevel = (activeDisplayHour == currentHour && vm.fatigueHeat.indices.contains(index)) ? vm.fatigueHeat[index] : 0
                    let isFatigueMinute = fatigueLevel > 0 && !isFuture
                    
                    let fillColor: Color = {
                        if isFuture {
                            return inactiveBlock.opacity(0.6)
                        } else if isFatigueMinute {
                            let t = min(1.0, max(0.0, fatigueLevel))
                            return alertColor.opacity(0.3 + 0.7 * t)
                        } else if activeSeconds > 0 {
                            return activeColor.opacity(0.25 + 0.75 * opacity)
                        } else {
                            return inactiveBlock
                        }
                    }()
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(fillColor)
                            .aspectRatio(1, contentMode: .fit)
                        
                        if activeSeconds > 0 && !isFuture {
                            let strokeColor = isFatigueMinute
                                ? alertColor.opacity(0.9)
                                : activeColor.opacity(0.6 * opacity)
                            let shadowColor = isFatigueMinute
                                ? alertColor.opacity(0.6 * max(opacity, 0.3))
                                : activeColor.opacity(0.5 * opacity)
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(strokeColor, lineWidth: 1)
                                .shadow(color: shadowColor, radius: 3 * max(opacity, 0.2), x: 0, y: 0)
                        }
                        
                        if isCurrent && vm.appState != .idle {
                             RoundedRectangle(cornerRadius: 3)
                                .strokeBorder(textPrimary.opacity(0.3), lineWidth: 1)
                        }
                    }
                    .animation(.easeOut(duration: 0.2), value: activeSeconds)
                    .onHover { hovering in
                        if hovering {
                            pendingHoverClear?.cancel()
                            pendingHoverClear = nil
                            hoveredMinute = index
                        } else {
                            let task = DispatchWorkItem {
                                if hoveredMinute == index {
                                    hoveredMinute = nil
                                }
                            }
                            pendingHoverClear?.cancel()
                            pendingHoverClear = task
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: task)
                        }
                    }
                    .help("\(activeDisplayHour):\(String(format: "%02d", index)) · 频率 - \(activeSeconds)")
                }
            }
            Spacer()
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 8)
    }
    
    private func fatigueFillColor(level: Double) -> Color {
        let t = min(1.0, max(0.0, level))
        return alertColor.opacity(0.3 + 0.7 * t)
    }
}
