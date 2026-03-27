import Foundation

enum Configuration {
    // API
    static let apiPort: UInt16 = 8778

    // Paths
    static var recordingsDirectory: URL {
        let url = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("RECAP", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static var appSupportDirectory: URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!.appendingPathComponent("RECAP", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    // Recording
    static let defaultFrameRate: Int = 30
    static let maxRecentRecordings: Int = 10
    static let timerInterval: TimeInterval = 1.0

    // Disk Space
    static let minimumFreeSpaceBytes: Int64 = 500_000_000 // 500 MB
    static let warningFreeSpaceBytes: Int64 = 1_000_000_000 // 1 GB
    static let diskSpaceCheckInterval: TimeInterval = 60.0
}
