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
}
