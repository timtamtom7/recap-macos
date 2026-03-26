import SwiftUI
import AVFoundation

struct RecordingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var recordingVM: RecordingViewModel
    @State private var showDisplayPicker = false
    @State private var showExportSheet = false

    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .background(.ultraThinMaterial)

                if let display = appState.selectedDisplay {
                    VStack(spacing: 12) {
                        Text("Recording: \(display.name)")
                            .font(.title3.weight(.semibold))
                            .foregroundColor(.primary)

                        Text("\(Int(display.resolution.width)) × \(Int(display.resolution.height))")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "record.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)

                        Text("Select a display to record")
                            .font(.title3.weight(.medium))
                            .foregroundColor(.secondary)

                        Button("Choose Display") {
                            showDisplayPicker = true
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 400)
            .padding(8)

            if appState.isRecording {
                HStack {
                    Circle()
                        .fill(appState.recordingState == .recording ? Color.red : Color.orange)
                        .frame(width: 12, height: 12)
                        .modifier(PulseModifier(isAnimating: appState.recordingState == .recording))

                    Text(appState.formattedElapsedTime)
                        .font(.system(size: 36, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }

            ControlBarView()
                .environmentObject(appState)
                .environmentObject(recordingVM)

            if !appState.recentRecordings.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent")
                        .font(.title3.weight(.semibold))
                        .padding(.horizontal, 8)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(appState.recentRecordings.prefix(5)) { recording in
                                RecordingThumbnail(recording: recording)
                                    .onTapGesture {
                                        NSWorkspace.shared.activateFileViewerSelecting([recording.filePath])
                                    }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
            }
        }
        .padding(24)
        .sheet(isPresented: $showDisplayPicker) {
            DisplayPickerView()
                .environmentObject(appState)
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
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .frame(width: 160, height: 90)
                .overlay {
                    Image(systemName: "film.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }

            Text(recording.title)
                .font(.caption.weight(.medium))
                .lineLimit(1)

            Text(recording.formattedDuration)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
