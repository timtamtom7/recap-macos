import Foundation
import os.log

enum Log {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.recap.macos"

    static let general = Logger(subsystem: subsystem, category: "general")
    static let capture = Logger(subsystem: subsystem, category: "capture")
    static let export = Logger(subsystem: subsystem, category: "export")
    static let storage = Logger(subsystem: subsystem, category: "storage")
    static let schedule = Logger(subsystem: subsystem, category: "schedule")
    static let api = Logger(subsystem: subsystem, category: "api")
    static let cloud = Logger(subsystem: subsystem, category: "cloud")
    static let thumbnail = Logger(subsystem: subsystem, category: "thumbnail")
}
