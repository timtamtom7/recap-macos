import SwiftUI

struct MenuBarPopoverView: View {
    @EnvironmentObject var appState: AppState
    @State private var showExportSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(appState.recordingState.iconColor)
                    .frame(width: 10, height: 10)

                Text("RECAP")
                    .font(.headline)

                Spacer()

                Text(appState.recordingState.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()

            Divider()

            // Recording status
            if appState.isRecording {
                HStack {
                    Circle()
                        .fill(appState.recordingState == .recording ? Color.red : Color.orange)
                        .frame(width: 8, height: 8)
                        .modifier(PulseModifier(isAnimating: appState.recordingState == .recording))

                    Text("Recording: \(appState.formattedElapsedTime)")
                        .font(.system(.body, design: .monospaced))
                }
                .padding()
            }

            // Controls
            HStack(spacing: 16) {
                if appState.recordingState == .idle {
                    Button(action: { appState.toggleRecording() }) {
                        Label("Record", systemImage: "record.circle")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                } else if appState.recordingState != .stopping {
                    Button(action: { appState.togglePause() }) {
                        Image(systemName: appState.recordingState == .paused ? "play.fill" : "pause.fill")
                    }
                    .buttonStyle(.bordered)

                    Button(action: { appState.stopRecording() }) {
                        Image(systemName: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Saving...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()

            Divider()

            // Recent recordings
            if !appState.recentRecordings.isEmpty {
                Text("Recent")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)

                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(appState.recentRecordings.prefix(3)) { recording in
                            Button(action: {
                                NSWorkspace.shared.activateFileViewerSelecting([recording.filePath])
                            }) {
                                HStack {
                                    Image(systemName: "film")
                                        .font(.caption)

                                    Text(recording.title)
                                        .font(.caption)
                                        .lineLimit(1)

                                    Spacer()

                                    Text(recording.formattedDuration)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .frame(maxHeight: 120)
            }

            Divider()

            // Footer
            HStack {
                Button("Open RECAP...") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                .buttonStyle(.plain)
                .font(.caption)

                Spacer()

                Button("Settings...") {
                    appState.showSettings = true
                }
                .buttonStyle(.plain)
                .font(.caption)

                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.caption)
            }
            .padding()
        }
        .frame(width: 280)
    }
}
