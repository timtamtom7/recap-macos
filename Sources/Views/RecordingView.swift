import SwiftUI
import AVFoundation

struct RecordingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var recordingVM: RecordingViewModel
    @State private var showDisplayPicker = false
    @State private var showExportSheet = false

    var body: some View {
        VStack(spacing: 24) {
            previewCard
                .frame(maxWidth: .infinity, maxHeight: 400)

            if appState.isRecording {
                recordingTimer
            }

            ControlBarView()
                .environmentObject(appState)
                .environmentObject(recordingVM)

            if !appState.recentRecordings.isEmpty {
                recentRecordingsSection
            }

            Spacer()
        }
        .padding(24)
        .sheet(isPresented: $showDisplayPicker) {
            DisplayPickerView()
                .environmentObject(appState)
        }
    }

    private var previewCard: some View {
        VStack(spacing: 16) {
            if let display = appState.selectedDisplay {
                VStack(spacing: 8) {
                    Image(systemName: "display")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)

                    Text("Recording: \(display.name)")
                        .font(.headline)

                    Text("\(Int(display.resolution.width)) × \(Int(display.resolution.height))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "record.circle")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)

                    Text("Select a display to record")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Button("Choose Display") {
                        showDisplayPicker = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }

    private var recordingTimer: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.red)
                .frame(width: 12, height: 12)
                .modifier(PulseModifier(isAnimating: appState.recordingState == .recording))

            Text(appState.formattedElapsedTime)
                .font(.system(size: 32, weight: .medium, design: .monospaced))
                .monospacedDigit()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }

    private var recentRecordingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Recordings")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(appState.recentRecordings.prefix(5)) { recording in
                        RecordingThumbnail(recording: recording)
                            .onTapGesture {
                                NSWorkspace.shared.activateFileViewerSelecting([recording.filePath])
                            }
                    }
                }
            }
        }
    }
}

struct PulseModifier: ViewModifier {
    let isAnimating: Bool
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .animation(
                isAnimating ? Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true) : .default,
                value: scale
            )
            .onAppear {
                if isAnimating {
                    scale = 1.2
                }
            }
    }
}

struct RecordingThumbnail: View {
    let recording: Recording

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .frame(width: 160, height: 90)
                .overlay {
                    Image(systemName: "film")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )

            VStack(spacing: 4) {
                Text(recording.title)
                    .font(.caption.weight(.medium))
                    .lineLimit(1)

                Text(recording.formattedDuration)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}
