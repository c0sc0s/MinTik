import Foundation
import UserNotifications

enum NotificationAvailability {
    static let isAvailable: Bool = {
        guard let url = Bundle.main.bundleURL as URL? else { return false }
        return url.pathExtension == "app"
    }()
}

enum NotificationPermissionState: Equatable {
    case unsupported
    case unknown
    case notDetermined
    case denied
    case authorized
    case provisional
    
    init(status: UNAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .denied:
            self = .denied
        case .authorized, .ephemeral:
            self = .authorized
        case .provisional:
            self = .provisional
        @unknown default:
            self = .unknown
        }
    }
    
    var needsUserAction: Bool {
        switch self {
        case .denied:
            return true
        default:
            return false
        }
    }
    
    var bannerContent: (title: String, detail: String, actionTitle: String?)? {
        switch self {
        case .denied:
            return ("系统通知已关闭", "前往 系统设置 > 通知 > MinTik，允许提醒以便准时休息。", "前往设置")
        default:
            return nil
        }
    }
}

enum AppState {
    case active, warning, idle, paused
}

enum AppView {
    case dashboard, analytics, settings, debug
}
