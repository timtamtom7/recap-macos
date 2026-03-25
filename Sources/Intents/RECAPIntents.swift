import Foundation
import AppIntents

// MARK: - Start Recording Intent

struct StartRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Recording"
    static var description = IntentDescription("Starts a new screen recording with RECAP")
    
    @Parameter(title: "Duration (seconds)", default: 60)
    var duration: Int
    
    static var parameterSummary: some ParameterSummary {
        Summary("Start recording for \(\.$duration) seconds")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // Trigger recording start
        NotificationCenter.default.post(name: .startRecording, object: nil, userInfo: ["duration": duration])
        return .result(dialog: "Started recording for \(duration) seconds")
    }
}

// MARK: - Stop Recording Intent

struct StopRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Recording"
    static var description = IntentDescription("Stops the current screen recording")
    
    static var parameterSummary: some ParameterSummary {
        Summary("Stop recording")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        NotificationCenter.default.post(name: .stopRecording, object: nil)
        return .result(dialog: "Stopped recording")
    }
}

// MARK: - Get Recent Recordings Intent

struct GetRecentRecordingsIntent: AppIntent {
    static var title: LocalizedStringResource = "Get Recent Recordings"
    static var description = IntentDescription("Returns recent recordings from RECAP")
    
    @Parameter(title: "Count", default: 5)
    var count: Int
    
    static var parameterSummary: some ParameterSummary {
        Summary("Get \(\.$count) recent recordings")
    }
    
    func perform() async throws -> some IntentResult & ReturnsValue<[RecordingInfo]> {
        // Load recent recordings from UserDefaults (stub)
        let recordings = loadRecentRecordings(count: count)
        let infos = recordings.map { RecordingInfo(from: $0) }
        return .result(value: infos)
    }
    
    private func loadRecentRecordings(count: Int) -> [RecordingStub] {
        guard let data = UserDefaults.standard.data(forKey: "recording_library"),
              let recordings = try? JSONDecoder().decode([RecordingStub].self, from: data) else {
            return []
        }
        return Array(recordings.prefix(count))
    }
}

struct RecordingStub: Codable {
    let id: UUID
    let title: String
    let duration: Double
    let createdAt: Date
    let filePath: String
}

// MARK: - Export Recording Intent

struct ExportRecordingIntent: AppIntent {
    static var title: LocalizedStringResource = "Export Recording"
    static var description = IntentDescription("Exports a RECAP recording with specified format")
    
    @Parameter(title: "Recording ID")
    var recordingId: String
    
    @Parameter(title: "Format", default: .mp4)
    var format: ExportFormat
    
    @Parameter(title: "Quality", default: .high)
    var quality: ExportQuality
    
    enum ExportFormat: String, AppEnum {
        case mp4 = "MP4"
        case gif = "GIF"
        case mov = "MOV"
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Format"
        
        static var caseDisplayRepresentations: [ExportFormat: DisplayRepresentation] = [
            .mp4: "MP4 Video",
            .gif: "Animated GIF",
            .mov: "QuickTime Movie"
        ]
    }
    
    enum ExportQuality: String, AppEnum {
        case low = "Low"
        case medium = "Medium"
        case high = "High"
        case original = "Original"
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Quality"
        
        static var caseDisplayRepresentations: [ExportQuality: DisplayRepresentation] = [
            .low: "Low Quality",
            .medium: "Medium Quality",
            .high: "High Quality",
            .original: "Original Quality"
        ]
    }
    
    static var parameterSummary: some ParameterSummary {
        Summary("Export recording \(\.$recordingId) as \(\.$format)")
    }
    
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let uuid = UUID(uuidString: recordingId) else {
            return .result(dialog: "Invalid recording ID")
        }
        
        // Trigger export
        NotificationCenter.default.post(name: .exportRecording, object: nil, userInfo: [
            "recordingId": uuid,
            "format": format.rawValue,
            "quality": quality.rawValue
        ])
        
        return .result(dialog: "Exporting recording as \(format.rawValue) (\(quality.rawValue) quality)")
    }
}

// MARK: - Recording Info

struct RecordingInfo: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Recording"
    
    let id: String
    let title: String
    let duration: Double
    let createdAt: Date
    let filePath: String
    
    init(from stub: RecordingStub) {
        self.id = stub.id.uuidString
        self.title = stub.title
        self.duration = stub.duration
        self.createdAt = stub.createdAt
        self.filePath = stub.filePath
    }
    
    static var defaultQuery = RecordingInfoQuery()
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct RecordingInfoQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [RecordingInfo] {
        return []
    }
    
    func suggestedEntities() async throws -> [RecordingInfo] {
        return []
    }
}

// MARK: - App Shortcuts Provider

struct RECAPShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRecordingIntent(),
            phrases: [
                "Start screen recording in \(.applicationName)",
                "Record my screen with \(.applicationName)"
            ],
            shortTitle: "Start Recording",
            systemImageName: "record.circle"
        )
        
        AppShortcut(
            intent: StopRecordingIntent(),
            phrases: [
                "Stop recording in \(.applicationName)",
                "End screen recording in \(.applicationName)"
            ],
            shortTitle: "Stop Recording",
            systemImageName: "stop.circle"
        )
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let startRecording = Notification.Name("RECAPStartRecording")
    static let stopRecording = Notification.Name("RECAPStopRecording")
    static let exportRecording = Notification.Name("RECAPExportRecording")
}
