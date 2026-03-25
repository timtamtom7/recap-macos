import SwiftUI

struct HotkeySettingsView: View {
    @AppStorage("hotkeyStartRecording") private var startHotkey = "F10"
    @AppStorage("hotkeyPauseRecording") private var pauseHotkey = "F11"
    @AppStorage("hotkeyStopRecording") private var stopHotkey = "F12"
    @AppStorage("globalHotkeysEnabled") private var hotkeysEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Toggle("Enable Global Hotkeys", isOn: $hotkeysEnabled)

            if hotkeysEnabled {
                Divider()

                Text("When RECAP is running (even in background):")
                    .font(.caption)
                    .foregroundColor(.secondary)

                hotkeyRow(label: "Start Recording", key: $startHotkey, defaultKey: "F10")
                hotkeyRow(label: "Pause/Resume", key: $pauseHotkey, defaultKey: "F11")
                hotkeyRow(label: "Stop Recording", key: $stopHotkey, defaultKey: "F12")
            }
        }
    }

    @ViewBuilder
    private func hotkeyRow(label: String, key: Binding<String>, defaultKey: String) -> some View {
        HStack {
            Text(label)
                .frame(width: 140, alignment: .trailing)

            Text(key.wrappedValue)
                .font(.system(size: 13, design: .monospaced))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
                .onTapGesture {
                    key.wrappedValue = "Press key..."
                }

            Button("Reset") {
                key.wrappedValue = defaultKey
            }
            .buttonStyle(.plain)
            .foregroundColor(.secondary)
        }
    }
}
