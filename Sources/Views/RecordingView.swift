import SwiftUI
import AVFoundation

struct RecordingView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var recordingVM: RecordingViewModel
    @State private var showDisplayPicker = false
    @State private var showExportSheet = false

    var body: some View {
        VStack(spacing: 20) {
            // Preview area
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black)

                if let display = appState.selectedDisplay {
                    Text("Recording: \(display.name)")
                        .foregroundColor(.white)
                        .font(.headline)

                    Text("\(Int(display.resolution.width)) × \(Int(display.resolution.height))")
                        .foregroundColor(.white.opacity(0.7))
                        .font(.subheadline)
                        .padding(.top, 30)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "record.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary)

                        Text("Select a display to record")
                            .foregroundColor(.secondary)

                        Button("Choose Display") {
                            showDisplayPicker = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: 400)
            .padding()

            // Timer
            if appState.isRecording {
                HStack {
                    Circle()
                        .fill(appState.recordingState == .recording ? Color.red : Color.orange)
                        .frame(width: 12, height: 12)
                        .modifier(PulseModifier(isAnimating: appState.recordingState == .recording))

                    Text(appState.formattedElapsedTime)
                        .font(.system(size: 36, weight: .medium, design: .monospaced))
                        .foregroundColor(.primary)
                }
            }

            // Control bar
            ControlBarView()
                .environmentObject(appState)
                .environmentObject(recordingVM)

            // Recent recordings
            if !appState.recentRecordings.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent")
                        .font(.headline)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(appState.recentRecordings.prefix(5)) { recording in
                                RecordingThumbnail(recording: recording)
                                    .onTapGesture {
                                        NSWorkspace.shared.activateFileViewerSelecting([recording.filePath])
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
        }
        .padding()
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
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 160, height: 90)
                .overlay {
                    Image(systemName: "film")
                        .foregroundColor(.secondary)
                }

            Text(recording.title)
                .font(.caption)
                .lineLimit(1)

            Text(recording.formattedDuration)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}
