import SwiftUI
import UserNotifications

struct FocusSettingsView: View {
    @ObservedObject var vm: FocusViewModel
    var textPrimary: Color
    var textSecondary: Color
    var accent: Color
    
    @State private var showClearDataConfirmation = false
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
        VStack(alignment: .leading, spacing: 25) {
            // Personalized Greeting
            if !vm.config.userName.isEmpty {
                Text("Hi, \(vm.config.userName)")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(textPrimary.opacity(0.7))
                    .padding(.top, 5)
            }
            
            Text("设置")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(textPrimary)
                .padding(.top, vm.config.userName.isEmpty ? 10 : 0)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("专注时长")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(textSecondary)
                    Spacer()
                    Text("\(Int(vm.config.duration)) 分钟")
                        .font(.system(size: 13, weight: .medium, design: .rounded).monospacedDigit())
                        .foregroundColor(textPrimary)
                }
                Slider(value: $vm.config.duration, in: 10...90, step: 5)
                    .accentColor(accent)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("休息重置时间")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(textSecondary)
                    Spacer()
                    Text("\(Int(vm.config.restDuration / 60)) 分钟")
                        .font(.system(size: 13, weight: .medium, design: .rounded).monospacedDigit())
                        .foregroundColor(textPrimary)
                }
                Slider(value: $vm.config.restDuration, in: 60...600, step: 60)
                    .accentColor(accent)
            }
            
            // Notification Permission Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("系统通知")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(textSecondary)
                    Spacer()
                    
                    // Permission Status Badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(notificationStatusColor)
                            .frame(width: 6, height: 6)
                        Text(notificationStatusText)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(textPrimary.opacity(0.7))
                    }
                }
                
                Text("当进入疲劳状态时，系统会发送通知提醒您休息")
                    .font(.system(size: 10))
                    .foregroundColor(textSecondary.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                
                // Show button to open settings if permission is denied or not determined
                if vm.notificationState == .denied || vm.notificationState == .notDetermined {
                    Button(action: {
                        if vm.notificationState == .denied {
                            vm.openNotificationPreferences()
                        } else {
                            // Request permission
                            vm.requestNotificationPermission()
                        }
                    }) {
                        HStack {
                            Image(systemName: vm.notificationState == .denied ? "gear" : "bell.badge")
                                .font(.system(size: 11, weight: .medium))
                            Text(vm.notificationState == .denied ? "前往系统设置开启" : "请求通知权限")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(accent)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Launch at Login Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("开机自启")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(textSecondary)
                    Spacer()
                    
                    // Status Badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(vm.config.launchAtLogin ? Color.green : Color.gray.opacity(0.5))
                            .frame(width: 6, height: 6)
                        Text(vm.config.launchAtLogin ? "已开启" : "已关闭")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(textPrimary.opacity(0.7))
                    }
                }
                
                HStack {
                    Text("开启后，应用将在系统启动时自动运行")
                        .font(.system(size: 10))
                        .foregroundColor(textSecondary.opacity(0.7))
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                    
                    // Settings Button
                    Button(action: {
                        // Open system login items settings
                        if let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Text("设置")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(textSecondary.opacity(0.5))
                            .underline()
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("主题色")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(textSecondary)
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    ThemeOptionView(
                        name: "活力橙",
                        primary: Color(hex: "FF9F0A"),
                        isSelected: vm.config.primaryColorHex == "FF9F0A",
                        onSelect: { vm.config.primaryColorHex = "FF9F0A" }
                    )
                    
                    ThemeOptionView(
                        name: "深海蓝",
                        primary: Color(hex: "0A84FF"),
                        isSelected: vm.config.primaryColorHex == "0A84FF",
                        onSelect: { vm.config.primaryColorHex = "0A84FF" }
                    )
                    
                    ThemeOptionView(
                        name: "森林绿",
                        primary: Color(hex: "30D158"),
                        isSelected: vm.config.primaryColorHex == "30D158",
                        onSelect: { vm.config.primaryColorHex = "30D158" }
                    )
                }
            }
            
            // Data Management Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("数据管理")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(textSecondary)
                    Spacer()
                }
                
                Button(action: {
                    showClearDataConfirmation = true
                }) {
                    Text("重置应用并清除数据")
                        .font(.system(size: 10))
                        .foregroundColor(textSecondary.opacity(0.5))
                        .underline()
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
                .alert(isPresented: $showClearDataConfirmation) {
                    Alert(
                        title: Text("重置应用？"),
                        message: Text("这将清除所有数据并重置设置。应用将自动退出，下次启动时会重新进入新手引导。"),
                        primaryButton: .destructive(Text("重置并退出")) {
                            vm.clearAllData()
                        },
                        secondaryButton: .cancel(Text("取消"))
                    )
                }
            }

            Spacer()
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 25)
        }
    }
    
    // Computed properties for notification status
    private var notificationStatusColor: Color {
        switch vm.notificationState {
        case .authorized, .provisional:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        case .unsupported, .unknown:
            return .gray
        }
    }
    
    private var notificationStatusText: String {
        switch vm.notificationState {
        case .authorized, .provisional:
            return "已开启"
        case .denied:
            return "已关闭"
        case .notDetermined:
            return "未设置"
        case .unsupported:
            return "不支持"
        case .unknown:
            return "未知"
        }
    }
    

}

struct ThemeOptionView: View {
    let name: String
    let primary: Color
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(primary)
                    .frame(width: 40, height: 40)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2.5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isSelected ? primary.opacity(0.5) : Color.clear, lineWidth: 1)
                            .padding(2.5)
                    )
                    .shadow(color: primary.opacity(0.3), radius: 4, x: 0, y: 2)
                
                Text(name)
                    .font(.system(size: 10, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
        }
        .buttonStyle(.plain)
    }
}
