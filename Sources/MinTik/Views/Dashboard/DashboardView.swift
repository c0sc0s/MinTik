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
                    MatrixCellView(
                        index: index,
                        activeSeconds: matrixData[index],
                        activeDisplayHour: activeDisplayHour,
                        currentHour: currentHour,
                        fatigueHeat: vm.fatigueHeat,
                        appState: vm.appState,
                        primaryColor: primaryColor,
                        inactiveBlock: inactiveBlock,
                        activeColor: primaryColor,
                        textPrimary: textPrimary,
                        isDarkMode: isDarkMode,
                        hoveredMinute: $hoveredMinute,
                        pendingHoverClear: $pendingHoverClear
                    )
                }
            }
            Spacer()
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 8)
    }
}

private struct MatrixCellView: View {
    let index: Int
    let activeSeconds: Int
    let activeDisplayHour: Int
    let currentHour: Int
    let fatigueHeat: [Double]
    let appState: AppState
    let primaryColor: Color
    let inactiveBlock: Color
    let activeColor: Color
    let textPrimary: Color
    let isDarkMode: Bool
    @Binding var hoveredMinute: Int?
    @Binding var pendingHoverClear: DispatchWorkItem?
    
    var body: some View {
        let currentMinute = Calendar.current.component(.minute, from: Date())
        let isFuture = (activeDisplayHour == currentHour) && (index > currentMinute)
        let isCurrent = (activeDisplayHour == currentHour) && (index == currentMinute)
        
        let opacity = Double(activeSeconds) / 60.0
        
        let fatigueLevel = (activeDisplayHour == currentHour && fatigueHeat.indices.contains(index)) ? fatigueHeat[index] : 0
        let isFatigueMinute = fatigueLevel > 0 && !isFuture
        
        let fillColor: Color = {
            if isFuture {
                return inactiveBlock.opacity(0.6)
            } else if isFatigueMinute {
                return fatigueFillColor(level: fatigueLevel)
            } else if activeSeconds > 0 {
                return activeColor.opacity(0.25 + 0.75 * opacity)
            } else {
                return inactiveBlock
            }
        }()
        
        let (strokeColor, shadowColor): (Color, Color) = {
            if isFatigueMinute {
                let baseColor = fatigueFillColor(level: fatigueLevel)
                // Premium glow effect for high fatigue
                let glowIntensity = max(0.0, (fatigueLevel - 0.5) * 2.0)
                return (
                    baseColor.opacity(0.8 + 0.2 * glowIntensity),
                    baseColor.opacity(0.4 + 0.4 * glowIntensity)
                )
            } else {
                return (activeColor.opacity(0.6 * opacity), activeColor.opacity(0.5 * opacity))
            }
        }()
        
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(fillColor)
                .aspectRatio(1, contentMode: .fit)
            
            if activeSeconds > 0 && !isFuture {
                RoundedRectangle(cornerRadius: 3)
                    .stroke(strokeColor, lineWidth: 1)
                    .shadow(color: shadowColor, radius: isFatigueMinute ? (3 + 3 * fatigueLevel) : (3 * max(opacity, 0.2)), x: 0, y: 0)
            }
            
            if isCurrent && appState != .idle {
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
    
    private func fatigueFillColor(level: Double) -> Color {
        // Premium Palette
        // Dark Mode: Gold (#FCD34D) -> Soft Rose (#FB7185) -> Deep Crimson (#E11D48)
        // Light Mode: Amber (#F59E0B) -> Rose (#F43F5E) -> Dark Rose (#BE123C)
        
        let t = min(1.0, max(0.0, level))
        
        // Define RGB values for start, mid, and end colors
        let startColor: (r: Double, g: Double, b: Double)
        let midColor: (r: Double, g: Double, b: Double)
        let endColor: (r: Double, g: Double, b: Double)
        
        if isDarkMode {
            startColor = (0.99, 0.83, 0.30) // #FCD34D
            midColor = (0.98, 0.44, 0.52)   // #FB7185
            endColor = (0.88, 0.11, 0.28)   // #E11D48
        } else {
            startColor = (0.96, 0.62, 0.04) // #F59E0B
            midColor = (0.96, 0.25, 0.37)   // #F43F5E
            endColor = (0.75, 0.07, 0.24)   // #BE123C
        }
        
        if t < 0.5 {
            // Interpolate Start -> Mid
            let localT = t * 2.0
            return Color(
                red: startColor.r + (midColor.r - startColor.r) * localT,
                green: startColor.g + (midColor.g - startColor.g) * localT,
                blue: startColor.b + (midColor.b - startColor.b) * localT
            ).opacity(0.7 + 0.3 * localT)
        } else {
            // Interpolate Mid -> End
            let localT = (t - 0.5) * 2.0
            return Color(
                red: midColor.r + (endColor.r - midColor.r) * localT,
                green: midColor.g + (endColor.g - midColor.g) * localT,
                blue: midColor.b + (endColor.b - midColor.b) * localT
            ).opacity(0.9 + 0.1 * localT)
        }
    }
}
