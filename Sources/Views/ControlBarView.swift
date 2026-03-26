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
            } else if appState.recordingState == .stopping {
                ProgressView()
                    .scaleEffect(1.2)
                Text("Saving...")
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
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

            Button(action: { appState.showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.title3.weight(.medium))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(NSColor.controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}
