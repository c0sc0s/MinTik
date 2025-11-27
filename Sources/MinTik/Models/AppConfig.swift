import Foundation

struct WorkHourRange: Codable, Identifiable, Equatable {
    var id = UUID()
    var start: Date
    var end: Date
}

struct AppConfig: Codable {
    var duration: Double = 60
    var activeThreshold: Double = 5
    var restDuration: Double = 180
    var userName: String = ""
    var workHours: [WorkHourRange] = []
    var isFirstLaunch: Bool = true
    var primaryColorHex: String = "FF8A3D"
    var launchAtLogin: Bool = false
    var enableFullScreenNotification: Bool = false
    
    init() {}
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        duration = try container.decodeIfPresent(Double.self, forKey: .duration) ?? 60
        activeThreshold = try container.decodeIfPresent(Double.self, forKey: .activeThreshold) ?? 5
        restDuration = try container.decodeIfPresent(Double.self, forKey: .restDuration) ?? 180
        userName = try container.decodeIfPresent(String.self, forKey: .userName) ?? ""
        workHours = try container.decodeIfPresent([WorkHourRange].self, forKey: .workHours) ?? []
        isFirstLaunch = try container.decodeIfPresent(Bool.self, forKey: .isFirstLaunch) ?? true
        primaryColorHex = try container.decodeIfPresent(String.self, forKey: .primaryColorHex) ?? "FF8A3D"
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        enableFullScreenNotification = try container.decodeIfPresent(Bool.self, forKey: .enableFullScreenNotification) ?? false
    }
    
    // Computed properties for theme-specific fatigue colors
    var fatigueColorStart: String {
        switch primaryColorHex.uppercased() {
        case "FF8A3D", "FF9F0A": // Orange theme
            return "FF6B35"
        case "0A7AEE", "0A84FF": // Blue theme
            return "5B9FD8"
        case "30D158": // Green theme
            return "FFD60A"
        default:
            return "FF6B35" // Default to orange theme
        }
    }
    
    var fatigueColorMid: String {
        switch primaryColorHex.uppercased() {
        case "FF8A3D", "FF9F0A": // Orange theme
            return "E63946"
        case "0A7AEE", "0A84FF": // Blue theme
            return "8B7FB8"
        case "30D158": // Green theme
            return "FF9F0A"
        default:
            return "E63946" // Default to orange theme
        }
    }
    
    var fatigueColorEnd: String {
        switch primaryColorHex.uppercased() {
        case "FF8A3D", "FF9F0A": // Orange theme
            return "C1121F"
        case "0A7AEE", "0A84FF": // Blue theme
            return "B565A7"
        case "30D158": // Green theme
            return "FF6B35"
        default:
            return "C1121F" // Default to orange theme
        }
    }
}
