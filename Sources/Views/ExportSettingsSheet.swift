import SwiftUI

struct ExportSettingsSheet: View {
    let recording: Recording
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPreset: ExportPreset = .standard
    @State private var isExporting = false
    @State private var progress: Double = 0
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            Text("Export Recording")
                .font(.headline)

            Form {
                Section("Export Preset") {
                    ForEach(ExportPreset.allCases) { preset in
                        Button(action: { selectedPreset = preset }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(preset.rawValue)
                                        .fontWeight(.medium)
                                    Text(preset.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if selectedPreset == preset {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                Section("Output") {
                    HStack {
                        Text("Source:")
                        Text(recording.filePath.lastPathComponent)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Duration:")
                        Text(recording.formattedDuration)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Size:")
                        Text(recording.formattedFileSize)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()

            if isExporting {
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .frame(width: 300)

                    Text("Exporting... \(Int(progress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .disabled(isExporting)

                Spacer()

                Button(action: exportRecording) {
                    if isExporting {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text("Export")
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(isExporting)
            }
            .padding()
        }
        .frame(width: 450, height: 500)
    }

    private func exportRecording() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.movie]
        panel.nameFieldStringValue = "\(recording.title).\(selectedPreset.fileExtension)"
        panel.canCreateDirectories = true

        guard panel.runModal() == .OK, let outputURL = panel.url else { return }

        isExporting = true
        errorMessage = nil
        progress = 0

        Task {
            do {
                try await ExportService.shared.export(
                    recording: recording,
                    to: outputURL,
                    preset: selectedPreset
                ) { prog in
                    Task { @MainActor in
                        self.progress = prog
                    }
                }

                await MainActor.run {
                    self.isExporting = false
                    self.dismiss()
                    NSWorkspace.shared.activateFileViewerSelecting([outputURL])
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isExporting = false
                }
            }
        }
    }
}
