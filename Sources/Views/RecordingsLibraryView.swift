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
            HStack {
                Text("Recordings Library")
                    .font(.title2.weight(.bold))

                Spacer()

                Picker("View", selection: $viewMode) {
                    Image(systemName: "square.grid.2x2.fill").tag(ViewMode.grid)
                    Image(systemName: "list.bullet").tag(ViewMode.list)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            Divider()

            if appState.recentRecordings.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "film.stack.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Recordings Yet")
                        .font(.title3.weight(.semibold))
                    Text("Start recording to see your files here")
                        .font(.body)
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
                        .padding(24)
                    } else {
                        LazyVStack(spacing: 8) {
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
                        .padding(24)
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(NSColor.windowBackgroundColor))
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
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .frame(height: 120)
                .overlay {
                    Image(systemName: "film.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )

            VStack(spacing: 4) {
                Text(recording.title)
                    .font(.subheadline.weight(.semibold))
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}

struct RecordingRowView: View {
    let recording: Recording

    var body: some View {
        HStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .frame(width: 120, height: 68)
                .overlay {
                    Image(systemName: "film.fill")
                        .foregroundColor(.secondary)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(recording.title)
                    .font(.subheadline.weight(.semibold))

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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}
