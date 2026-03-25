import SwiftUI

struct MetadataEditorView: View {
    @Binding var recording: Recording
    @Binding var isPresented: Bool
    @State private var title: String
    @State private var notes: String
    @State private var tagsText: String
    @State private var isStarred: Bool

    private let metadataStore = RecordingMetadataStore()

    init(recording: Binding<Recording>, isPresented: Binding<Bool>) {
        self._recording = recording
        self._isPresented = isPresented
        self._title = State(initialValue: recording.wrappedValue.title)
        self._notes = State(initialValue: metadataStore.getMetadata(for: recording.wrappedValue.id)?.notes ?? "")
        self._tagsText = State(initialValue: metadataStore.getMetadata(for: recording.wrappedValue.id)?.tags.joined(separator: ", ") ?? "")
        self._isStarred = State(initialValue: metadataStore.getMetadata(for: recording.wrappedValue.id)?.isStarred ?? false)
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Edit Recording")
                .font(.headline)

            Form {
                TextField("Title", text: $title)

                Toggle("Starred", isOn: $isStarred)

                Text("Notes")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextEditor(text: $notes)
                    .frame(height: 100)

                TextField("Tags (comma-separated)", text: $tagsText)
            }

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                Button("Save") {
                    save()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 360)
    }

    private func save() {
        var updated = recording
        updated.title = title

        let tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        metadataStore.saveMetadata(RecordingMetadata(
            recordingId: recording.id,
            title: title,
            notes: notes,
            tags: tags,
            isStarred: isStarred,
            updatedAt: Date()
        ))

        recording = updated
    }
}

struct RecordingMetadata: Codable {
    let recordingId: UUID
    var title: String
    var notes: String
    var tags: [String]
    var isStarred: Bool
    var updatedAt: Date
}

final class RecordingMetadataStore {
    private let key = "recordingMetadata"

    func saveMetadata(_ metadata: RecordingMetadata) {
        var all = getAllMetadata()
        all[metadata.recordingId.uuidString] = metadata
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func getMetadata(for recordingId: UUID) -> RecordingMetadata? {
        getAllMetadata()[recordingId.uuidString]
    }

    private func getAllMetadata() -> [String: RecordingMetadata] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let metadata = try? JSONDecoder().decode([String: RecordingMetadata].self, from: data) else {
            return [:]
        }
        return metadata
    }
}
