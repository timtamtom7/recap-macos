import SwiftUI

struct ControlBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var recordingVM: RecordingViewModel
    @State private var showExportSheet = false

    var body: some View {
        HStack(spacing: 24) {
            // Display selector
            Menu {
                if let display = appState.selectedDisplay {
                    Button("Display: \(display.name)") {}
                    Divider()
                }
                Button("Change Display...") {
                    NotificationCenter.default.post(name: .showDisplayPicker, object: nil)
                }
            } label: {
                HStack {
                    Image(systemName: "rectangle.on.rectangle")
                    Text(appState.selectedDisplay?.name ?? "Select Display")
                        .lineLimit(1)
                }
            }
            .menuStyle(.borderlessButton)
            .frame(minWidth: 150)

            Divider()
                .frame(height: 30)

            Spacer()

            // Main controls
            if appState.recordingState == .idle {
                Button(action: { appState.toggleRecording() }) {
                    Label("Record", systemImage: "record.circle")
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            } else if appState.recordingState == .stopping {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Saving...")
                    .foregroundColor(.secondary)
            } else {
                // Recording controls
                Button(action: { appState.togglePause() }) {
                    Image(systemName: appState.recordingState == .paused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)

                Button(action: { appState.stopRecording() }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Settings
            Button(action: { appState.showSettings = true }) {
                Image(systemName: "gear")
                    .font(.title3)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}
