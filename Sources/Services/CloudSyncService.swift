import Foundation
import CloudKit

final class CloudSyncService: ObservableObject {
    static let shared = CloudSyncService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var isEnabled = true
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    
    private init() {
        container = CKContainer(identifier: "iCloud.com.recap.app")
        privateDatabase = container.privateCloudDatabase
        loadSettings()
    }
    
    private func loadSettings() {
        isEnabled = UserDefaults.standard.bool(forKey: "cloudSyncEnabled")
    }
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "cloudSyncEnabled")
        
        if enabled {
            Task { await performSync() }
        }
    }
    
    // MARK: - Sync Operations
    
    func performSync() async {
        guard isEnabled, !isSyncing else { return }
        
        await MainActor.run { isSyncing = true }
        defer {
            Task { @MainActor in
                isSyncing = false
                lastSyncDate = Date()
            }
        }
        
        // Sync recording metadata
        do {
            try await syncRecordingMetadata()
        } catch {
            print("Cloud sync error: \(error)")
        }
    }
    
    private func syncRecordingMetadata() async throws {
        // Fetch remote records
        let query = CKQuery(recordType: "RecordingMetadata", predicate: NSPredicate(value: true))
        let (results, _) = try await privateDatabase.records(matching: query)
        
        // Process remote records
        for (_, result) in results {
            if case .success(let record) = result {
                await processRemoteRecord(record)
            }
        }
        
        // Upload local records
        let localRecordings = loadLocalRecordingsMetadata()
        for recording in localRecordings {
            try await uploadRecordingMetadata(recording)
        }
    }
    
    private func processRemoteRecord(_ record: CKRecord) async {
        // Extract metadata
        guard let idString = record["recordingId"] as? String,
              let id = UUID(uuidString: idString),
              let title = record["title"] as? String,
              let createdAt = record["createdAt"] as? Date else {
            return
        }
        
        let duration = record["duration"] as? Double ?? 0
        let notes = record["notes"] as? String
        
        // Check if we have this recording locally
        if !localRecordingExists(id: id) {
            // Add to local index with "remote" flag
            addRemoteRecordingIndex(id: id, title: title, createdAt: createdAt, duration: duration, notes: notes)
        }
    }
    
    private func uploadRecordingMetadata(_ recording: CloudRecordingMetadata) async throws {
        let record = CKRecord(recordType: "RecordingMetadata")
        record["recordingId"] = recording.id.uuidString as CKRecordValue
        record["title"] = recording.title as CKRecordValue
        record["createdAt"] = recording.createdAt as CKRecordValue
        record["duration"] = recording.duration as CKRecordValue
        record["notes"] = recording.notes as CKRecordValue?
        record["isLocal"] = true as CKRecordValue
        
        try await privateDatabase.save(record)
    }
    
    // MARK: - Local Storage
    
    private func loadLocalRecordingsMetadata() -> [CloudRecordingMetadata] {
        guard let data = UserDefaults.standard.data(forKey: "recording_metadata_index"),
              let recordings = try? JSONDecoder().decode([CloudRecordingMetadata].self, from: data) else {
            return []
        }
        return recordings
    }
    
    private func localRecordingExists(id: UUID) -> Bool {
        let recordings = loadLocalRecordingsMetadata()
        return recordings.contains { $0.id == id }
    }
    
    private func addRemoteRecordingIndex(id: UUID, title: String, createdAt: Date, duration: Double, notes: String?) {
        var recordings = loadLocalRecordingsMetadata()
        recordings.append(CloudRecordingMetadata(
            id: id,
            title: title,
            createdAt: createdAt,
            duration: duration,
            notes: notes,
            isRemote: true
        ))
        
        if let data = try? JSONEncoder().encode(recordings) {
            UserDefaults.standard.set(data, forKey: "recording_metadata_index")
        }
    }
    
    // MARK: - Remote Recording Access
    
    func getRemoteRecordings() -> [CloudRecordingMetadata] {
        return loadLocalRecordingsMetadata().filter { $0.isRemote }
    }
    
    func copyToLocal(recordingId: UUID, completion: @escaping (Result<URL, Error>) -> Void) {
        // In production, this would download from iCloud Drive
        // For now, simulate failure
        completion(.failure(CloudSyncError.remoteRecordingNotAvailable))
    }
}

// MARK: - Recording Metadata

struct CloudRecordingMetadata: Codable {
    let id: UUID
    var title: String
    let createdAt: Date
    var duration: Double
    var notes: String?
    var isRemote: Bool = false
}

enum CloudSyncError: Error {
    case remoteRecordingNotAvailable
    case syncFailed
}
