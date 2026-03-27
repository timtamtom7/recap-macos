import Foundation

struct Recording: Identifiable, Codable, Hashable {
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
    var resolution: CGSize

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
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdAt)
    }
}
