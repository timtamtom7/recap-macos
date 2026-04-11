import Foundation

enum Configuration {
    // API
    static let apiPort: UInt16 = 8778

    // Paths
    static var recordingsDirectory: URL {
        guard let url = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first else {
            // Fallback to temporary directory if Movies directory is unavailable
            let fallback = FileManager.default.temporaryDirectory.appendingPathComponent("RECAP", isDirectory: true)
            try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
            return fallback
        }
        let recURL = url.appendingPathComponent("RECAP", isDirectory: true)
        try? FileManager.default.createDirectory(at: recURL, withIntermediateDirectories: true)
        return recURL
    }

    static var appSupportDirectory: URL {
        guard let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            // Fallback to application support in user's home directory
            let fallback = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Application Support/RECAP", isDirectory: true)
            try? FileManager.default.createDirectory(at: fallback, withIntermediateDirectories: true)
            return fallback
        }
        let appURL = url.appendingPathComponent("RECAP", isDirectory: true)
        try? FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
        return appURL
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
