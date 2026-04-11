import SwiftUI

struct ControlBarView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var recordingVM: RecordingViewModel
    @State private var showExportSheet = false

    var body: some View {
        HStack(spacing: 24) {
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
                .font(.body.weight(.medium))
            }
            .menuStyle(.borderlessButton)
            .frame(minWidth: 150)
            .accessibilityLabel("Display selector")
            .accessibilityHint(appState.selectedDisplay == nil ? "No display selected. Opens display picker." : "Selected: \(appState.selectedDisplay?.name ?? "")")

            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(width: 1, height: 30)

            Spacer()

            if appState.recordingState == .idle {
                Button(action: { appState.toggleRecording() }) {
                    Label("Record", systemImage: "record.circle.fill")
                        .font(.body.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Start Recording")
                .accessibilityHint("Begins screen recording with the selected display")
            } else if appState.recordingState == .stopping {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Saving...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Saving recording")
            } else {
                Button(action: { appState.togglePause() }) {
                    Image(systemName: appState.recordingState == .paused ? "play.circle.fill" : "pause.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(appState.recordingState == .paused ? "Resume Recording" : "Pause Recording")
                .accessibilityHint(appState.recordingState == .paused ? "Resumes the current recording" : "Pauses the current recording")

                Button(action: { appState.stopRecording() }) {
                    Image(systemName: "stop.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.red)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Stop Recording")
                .accessibilityHint("Stops and saves the current recording")
            }

            Spacer()

            Button(action: { appState.showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title3.weight(.medium))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
            .accessibilityHint("Opens RECAP settings")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
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
