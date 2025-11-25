import SwiftUI

struct ModernFocusUI: View {
    @ObservedObject var vm: FocusViewModel
    @State private var isQuitHovered = false
    @State private var isAppearing = false  // For custom entrance animation
    
    private let isDarkMode = true
    private var baseHeight: CGFloat { 360 }
    private var bannerExtraHeight: CGFloat { vm.notificationState.bannerContent == nil ? 0 : 70 }
    private var currentHeight: CGFloat { baseHeight + bannerExtraHeight }
    
    var cardBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                isDarkMode ? Color(hex: "1A1A1A") : Color(hex: "FFFFFF"),
                isDarkMode ? Color(hex: "121212") : Color(hex: "F8F8F8")
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var textPrimary: Color { isDarkMode ? .white : Color(hex: "171717") }
    var textSecondary: Color { isDarkMode ? Color(hex: "737373") : Color(hex: "a3a3a3") }
    var inactiveBlock: Color { isDarkMode ? Color(hex: "262626") : Color(hex: "f5f5f5") }
    var accent: Color { Color(hex: vm.config.primaryColorHex) }
    var warningColor: Color { alertColor(from: accent) }
    var pausedColor: Color { isDarkMode ? Color(hex: "facc15") : Color(hex: "eab308") }
    var borderColor: Color { isDarkMode ? Color.white.opacity(0.1) : Color.black.opacity(0.05) }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                // Quit button
                Button(action: { NSApp.terminate(nil) }) {
                    ZStack {
                        Circle()
                            .fill(isQuitHovered ? Color.red.opacity(0.6) : Color(hex: "737373").opacity(0.3))
                            .frame(width: 14, height: 14)
                        
                        if isQuitHovered {
                            Image(systemName: "xmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .transition(.opacity)
                        }
                    }
                    .scaleEffect(isQuitHovered ? 1.15 : 1.0)
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isQuitHovered = hovering
                    }
                }
                
                Spacer()
                
                // Tab switcher (right side)
                if vm.currentView != .settings {
                    HStack(spacing: 0) {
                        // Dashboard tab
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                vm.currentView = .dashboard
                            }
                        }) {
                            Image(systemName: "square.grid.2x2.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(vm.currentView == .dashboard ? textPrimary : textSecondary.opacity(0.5))
                                .frame(width: 32, height: 32)
                                .background(vm.currentView == .dashboard ? inactiveBlock : Color.clear)
                                .cornerRadius(8)
                                .frame(width: 42, height: 40)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        // Analytics tab
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                vm.currentView = .analytics
                            }
                        }) {
                            Image(systemName: "chart.xyaxis.line")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(vm.currentView == .analytics ? textPrimary : textSecondary.opacity(0.5))
                                .frame(width: 32, height: 32)
                                .background(vm.currentView == .analytics ? inactiveBlock : Color.clear)
                                .cornerRadius(8)
                                .frame(width: 42, height: 40)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        
                        // Data Repository tab
                        Button(action: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                vm.currentView = .debug
                            }
                        }) {
                            Image(systemName: "cylinder.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(vm.currentView == .debug ? textPrimary : textSecondary.opacity(0.5))
                                .frame(width: 32, height: 32)
                                .background(vm.currentView == .debug ? inactiveBlock : Color.clear)
                                .cornerRadius(8)
                                .frame(width: 42, height: 40)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .background(Color.black.opacity(0.35))
                    .cornerRadius(10)
                } else {
                    // Back button when in settings
                    Button(action: { withAnimation { vm.currentView = .dashboard } }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("返回")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(textSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .frame(height: 56)
            
            if let banner = vm.notificationState.bannerContent {
                NotificationPermissionBanner(
                    title: banner.title,
                    detail: banner.detail,
                    actionTitle: banner.actionTitle,
                    backgroundColor: inactiveBlock.opacity(0.7),
                    accent: warningColor,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    action: banner.actionTitle != nil ? { vm.openNotificationPreferences() } : nil
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            } else {
                Spacer().frame(height: 0)
            }
            
            // Content
            ZStack {
                if vm.currentView == .dashboard {
                    FocusDashboardView(vm: vm, isDarkMode: isDarkMode, textPrimary: textPrimary, textSecondary: textSecondary, inactiveBlock: inactiveBlock, accent: accent, warningColor: warningColor, pausedColor: pausedColor, primaryColor: accent, alertColor: warningColor)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                } else if vm.currentView == .analytics {
                    AnalyticsView(vm: vm, textPrimary: textPrimary, textSecondary: textSecondary, accent: accent, inactiveBlock: inactiveBlock)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                } else if vm.currentView == .debug {
                    DebugDataView(vm: vm, textPrimary: textPrimary, textSecondary: textSecondary, inactiveBlock: inactiveBlock)
                        .transition(.move(edge: .leading).combined(with: .opacity))
                } else if vm.currentView == .settings {
                    FocusSettingsView(vm: vm, textPrimary: textPrimary, textSecondary: textSecondary, accent: accent)
                        .transition(.move(edge: .trailing).combined(with: .opacity))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 320, height: currentHeight)
        .scaleEffect(isAppearing ? 1.0 : 0.9)
        .offset(y: isAppearing ? 0 : -10)
        .opacity(isAppearing ? 1.0 : 0.0)
        .background(Color.clear)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                isAppearing = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("PopoverDidShow"))) { _ in
            // Reset and re-trigger animation when popover is shown
            isAppearing = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    isAppearing = true
                }
            }
        }
    }
}
