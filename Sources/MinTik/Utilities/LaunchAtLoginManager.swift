import Foundation
import ServiceManagement

/// Manager for handling launch at login functionality
class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()
    
    private init() {}
    
    /// Check if launch at login is currently enabled
    var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // Fallback for older macOS versions
            return false
        }
    }
    
    /// Enable or disable launch at login
    /// - Parameter enabled: Whether to enable or disable launch at login
    /// - Returns: Success status
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Bool {
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status == .enabled {
                        // Already enabled
                        return true
                    }
                    try SMAppService.mainApp.register()
                    return true
                } else {
                    if SMAppService.mainApp.status == .notRegistered {
                        // Already disabled
                        return true
                    }
                    try SMAppService.mainApp.unregister()
                    return true
                }
            } catch {
                print("Failed to \(enabled ? "enable" : "disable") launch at login: \(error.localizedDescription)")
                return false
            }
        } else {
            // Fallback for older macOS versions
            print("Launch at login requires macOS 13.0 or later")
            return false
        }
    }
    
    /// Get the current status of the login item
    var statusDescription: String {
        if #available(macOS 13.0, *) {
            switch SMAppService.mainApp.status {
            case .enabled:
                return "已开启"
            case .notRegistered:
                return "已关闭"
            case .notFound:
                return "未找到"
            case .requiresApproval:
                return "需要批准"
            @unknown default:
                return "未知"
            }
        } else {
            return "不支持"
        }
    }
    
    /// Sync the actual system status and return whether it's enabled
    /// This should be called when the app becomes active to detect external changes
    func syncStatus() -> Bool {
        return isEnabled
    }
}
