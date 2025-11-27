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
}
