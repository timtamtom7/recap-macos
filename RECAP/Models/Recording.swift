import SwiftUI

struct Recording: Identifiable, Codable {
    let id: UUID
    var title: String
    var filePath: URL
    var duration: TimeInterval
    var createdAt: Date
    var thumbnailPath: URL?
    var fileSize: Int64
    var displayName: String?
    var includesAudio: Bool
    var codec: String
    var resolutionWidth: Int
    var resolutionHeight: Int

    init(
        id: UUID = UUID(),
        title: String,
        filePath: URL,
        duration: TimeInterval,
        createdAt: Date = Date(),
        thumbnailPath: URL? = nil,
        fileSize: Int64 = 0,
        displayName: String? = nil,
        includesAudio: Bool = false,
        codec: String = "h264",
        resolutionWidth: Int = 0,
        resolutionHeight: Int = 0
    ) {
        self.id = id
        self.title = title
        self.filePath = filePath
        self.duration = duration
        self.createdAt = createdAt
        self.thumbnailPath = thumbnailPath
        self.fileSize = fileSize
        self.displayName = displayName
        self.includesAudio = includesAudio
        self.codec = codec
        self.resolutionWidth = resolutionWidth
        self.resolutionHeight = resolutionHeight
    }

    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}
