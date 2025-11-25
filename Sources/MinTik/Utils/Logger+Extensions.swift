import os
import Foundation

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier ?? "com.mintik.app"

    static let lifecycle = Logger(subsystem: subsystem, category: "Lifecycle")
    static let focus = Logger(subsystem: subsystem, category: "Focus")
    static let persistence = Logger(subsystem: subsystem, category: "Persistence")
    static let ui = Logger(subsystem: subsystem, category: "UI")
}
