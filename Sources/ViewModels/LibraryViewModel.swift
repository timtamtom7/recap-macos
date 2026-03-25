import Foundation
import Combine

@MainActor
class LibraryViewModel: ObservableObject {
    @Published var recordings: [Recording] = []

    private let store = RecordingStore.shared

    init() {
        loadRecordings()
    }

    func loadRecordings() {
        recordings = store.getRecentRecordings(limit: 50)
    }

    func deleteRecording(_ recording: Recording) {
        store.deleteRecording(recording.id)
        if let index = recordings.firstIndex(where: { $0.id == recording.id }) {
            recordings.remove(at: index)
        }
        try? FileManager.default.removeItem(at: recording.filePath)
    }
}
