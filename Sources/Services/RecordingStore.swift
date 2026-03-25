import Foundation
import SQLite

class RecordingStore {
    static let shared = RecordingStore()

    private var db: Connection?

    private init() {}

    func setup() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let recapDir = appSupport.appendingPathComponent("RECAP", isDirectory: true)
        try? FileManager.default.createDirectory(at: recapDir, withIntermediateDirectories: true)
        let dbPath = recapDir.appendingPathComponent("recap.db").path

        do {
            db = try Connection(dbPath)
            try createTables()
        } catch {
            print("RecordingStore setup failed: \(error)")
        }
    }

    private func createTables() throws {
        guard let db = db else { return }

        let recordings = Table("recordings")
        let id = SQLite.Expression<String>("id")
        let title = SQLite.Expression<String>("title")
        let filePath = SQLite.Expression<String>("file_path")
        let durationSeconds = SQLite.Expression<Double>("duration_seconds")
        let createdAt = SQLite.Expression<String>("created_at")
        let thumbnailPath = SQLite.Expression<String?>("thumbnail_path")
        let fileSizeBytes = SQLite.Expression<Int64>("file_size_bytes")
        let displayName = SQLite.Expression<String?>("display_name")
        let includesAudio = SQLite.Expression<Bool>("includes_audio")
        let codec = SQLite.Expression<String>("codec")
        let resolutionWidth = SQLite.Expression<Int?>("resolution_width")
        let resolutionHeight = SQLite.Expression<Int?>("resolution_height")

        try db.run(recordings.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(title)
            t.column(filePath)
            t.column(durationSeconds)
            t.column(createdAt)
            t.column(thumbnailPath)
            t.column(fileSizeBytes)
            t.column(displayName)
            t.column(includesAudio)
            t.column(codec)
            t.column(resolutionWidth)
            t.column(resolutionHeight)
        })
    }

    func saveRecording(_ recording: Recording) {
        guard let db = db else { return }

        let recordings = Table("recordings")
        let id = SQLite.Expression<String>("id")
        let title = SQLite.Expression<String>("title")
        let filePath = SQLite.Expression<String>("file_path")
        let durationSeconds = SQLite.Expression<Double>("duration_seconds")
        let createdAt = SQLite.Expression<String>("created_at")
        let thumbnailPath = SQLite.Expression<String?>("thumbnail_path")
        let fileSizeBytes = SQLite.Expression<Int64>("file_size_bytes")
        let displayName = SQLite.Expression<String?>("display_name")
        let includesAudio = SQLite.Expression<Bool>("includes_audio")
        let codec = SQLite.Expression<String>("codec")
        let resolutionWidth = SQLite.Expression<Int?>("resolution_width")
        let resolutionHeight = SQLite.Expression<Int?>("resolution_height")

        let formatter = ISO8601DateFormatter()

        do {
            try db.run(recordings.insert(or: .replace,
                id <- recording.id.uuidString,
                title <- recording.title,
                filePath <- recording.filePath.absoluteString,
                durationSeconds <- recording.duration,
                createdAt <- formatter.string(from: recording.createdAt),
                thumbnailPath <- recording.thumbnailPath?.absoluteString,
                fileSizeBytes <- recording.fileSize,
                displayName <- recording.displayName,
                includesAudio <- recording.includesAudio,
                codec <- recording.codec,
                resolutionWidth <- Int(recording.resolution.width),
                resolutionHeight <- Int(recording.resolution.height)
            ))
        } catch {
            print("Error saving recording: \(error)")
        }
    }

    func getRecentRecordings(limit: Int = 10) -> [Recording] {
        guard let db = db else { return [] }

        let recordings = Table("recordings")
        let id = SQLite.Expression<String>("id")
        let title = SQLite.Expression<String>("title")
        let filePath = SQLite.Expression<String>("file_path")
        let durationSeconds = SQLite.Expression<Double>("duration_seconds")
        let createdAt = SQLite.Expression<String>("created_at")
        let thumbnailPath = SQLite.Expression<String?>("thumbnail_path")
        let fileSizeBytes = SQLite.Expression<Int64>("file_size_bytes")
        let displayName = SQLite.Expression<String?>("display_name")
        let includesAudio = SQLite.Expression<Bool>("includes_audio")
        let codec = SQLite.Expression<String>("codec")
        let resolutionWidth = SQLite.Expression<Int?>("resolution_width")
        let resolutionHeight = SQLite.Expression<Int?>("resolution_height")

        let formatter = ISO8601DateFormatter()

        var result: [Recording] = []
        do {
            let query = recordings.order(createdAt.desc).limit(limit)
            for row in try db.prepare(query) {
                let recording = Recording(
                    id: UUID(uuidString: row[id]) ?? UUID(),
                    title: row[title],
                    filePath: URL(string: row[filePath])!,
                    duration: row[durationSeconds],
                    createdAt: formatter.date(from: row[createdAt]) ?? Date(),
                    thumbnailPath: row[thumbnailPath].flatMap { URL(string: $0) },
                    fileSize: row[fileSizeBytes],
                    displayName: row[displayName],
                    includesAudio: row[includesAudio],
                    codec: row[codec],
                    resolution: CGSize(
                        width: CGFloat(row[resolutionWidth] ?? 1920),
                        height: CGFloat(row[resolutionHeight] ?? 1080)
                    )
                )
                result.append(recording)
            }
        } catch {
            print("Error getting recordings: \(error)")
        }
        return result
    }

    func deleteRecording(_ recordingId: UUID) {
        guard let db = db else { return }

        let recordings = Table("recordings")
        let id = SQLite.Expression<String>("id")

        let recordingRow = recordings.filter(id == recordingId.uuidString)
        do {
            try db.run(recordingRow.delete())
        } catch {
            print("Error deleting recording: \(error)")
        }
    }
}
