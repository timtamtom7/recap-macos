import SwiftUI

struct RecordingsLibraryView: View {
    @EnvironmentObject var appState: AppState
    @State private var viewMode: ViewMode = .grid
    @State private var selectedRecording: Recording?
    @State private var showExportSheet = false

    enum ViewMode {
        case grid, list
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Recordings Library")
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Picker("View", selection: $viewMode) {
                    Image(systemName: "square.grid.2x2").tag(ViewMode.grid)
                    Image(systemName: "list.bullet").tag(ViewMode.list)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
            .padding()

            Divider()

            // Content
            if appState.recentRecordings.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Recordings Yet")
                        .font(.headline)
                    Text("Start recording to see your files here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    if viewMode == .grid {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 200))], spacing: 16) {
                            ForEach(appState.recentRecordings) { recording in
                                RecordingGridItem(recording: recording)
                                    .onTapGesture {
                                        NSWorkspace.shared.activateFileViewerSelecting([recording.filePath])
                                    }
                                    .contextMenu {
                                        Button("Show in Finder") {
                                            NSWorkspace.shared.activateFileViewerSelecting([recording.filePath])
                                        }
                                        Button("Export...") {
                                            selectedRecording = recording
                                            showExportSheet = true
                                        }
                                        Divider()
                                        Button("Delete", role: .destructive) {
                                            deleteRecording(recording)
                                        }
                                    }
                            }
                        }
                        .padding()
                    } else {
                        LazyVStack(spacing: 1) {
                            ForEach(appState.recentRecordings) { recording in
                                RecordingRowView(recording: recording)
                                    .onTapGesture {
                                        NSWorkspace.shared.activateFileViewerSelecting([recording.filePath])
                                    }
                                    .contextMenu {
                                        Button("Show in Finder") {
                                            NSWorkspace.shared.activateFileViewerSelecting([recording.filePath])
                                        }
                                        Button("Export...") {
                                            selectedRecording = recording
                                            showExportSheet = true
                                        }
                                        Divider()
                                        Button("Delete", role: .destructive) {
                                            deleteRecording(recording)
                                        }
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showExportSheet) {
            if let recording = selectedRecording {
                ExportSettingsSheet(recording: recording)
                    .environmentObject(appState)
            }
        }
    }

    private func deleteRecording(_ recording: Recording) {
        RecordingStore.shared.deleteRecording(recording.id)
        if let index = appState.recentRecordings.firstIndex(where: { $0.id == recording.id }) {
            appState.recentRecordings.remove(at: index)
        }
        try? FileManager.default.removeItem(at: recording.filePath)
    }
}

struct RecordingGridItem: View {
    let recording: Recording

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 120)
                .overlay {
                    Image(systemName: "film")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                }

            VStack(spacing: 2) {
                Text(recording.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack {
                    Text(recording.formattedDuration)
                    Text("·")
                    Text(recording.formattedFileSize)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RecordingRowView: View {
    let recording: Recording

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 120, height: 68)
                .overlay {
                    Image(systemName: "film")
                        .foregroundColor(.secondary)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(recording.title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(recording.formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack {
                    Label(recording.formattedDuration, systemImage: "clock")
                    Text("·")
                    Label(recording.formattedFileSize, systemImage: "doc")
                    Text("·")
                    Text(recording.codec.uppercased())
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}
