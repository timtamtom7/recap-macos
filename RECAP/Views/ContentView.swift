import SwiftUI

struct ContentView: View {
    @ObservedObject private var service = ScreenCaptureService.shared
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("RECAP")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Text(service.recordingState.displayText)
                    .font(.system(size: 13))
                    .foregroundColor(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .cornerRadius(6)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Theme.backgroundSecondary)

            Divider()

            // Main content
            if service.recordingState == .idle || service.recordingState == .stopped {
                RecordingIdleView()
            } else {
                RecordingActiveView()
            }

            Divider()

            // Control bar
            ControlBarView()
        }
        .frame(minWidth: 500, minHeight: 400)
        .background(Theme.backgroundPrimary)
    }

    private var statusColor: Color {
        switch service.recordingState {
        case .idle, .stopped: return Theme.textSecondary
        case .recording: return Theme.recordingRed
        case .paused: return Theme.pausedOrange
        case .stopping: return Theme.textSecondary
        }
    }
}

// MARK: - Idle View

struct RecordingIdleView: View {
    @ObservedObject private var service = ScreenCaptureService.shared
    @State private var showingDisplayPicker = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "record.circle")
                .font(.system(size: 64))
                .foregroundColor(Theme.textSecondary.opacity(0.5))

            Text("Ready to Record")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Theme.textPrimary)

            Text("Select a display or window to start recording")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)

            Button(action: { showingDisplayPicker = true }) {
                HStack {
                    Image(systemName: "display")
                    Text("Choose Display")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Theme.accentBlue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showingDisplayPicker) {
            DisplayPickerView(isPresented: $showingDisplayPicker)
        }
    }
}

// MARK: - Active View

struct RecordingActiveView: View {
    @ObservedObject private var service = ScreenCaptureService.shared

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.recordingRed.opacity(0.1))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(Theme.recordingRed.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .scaleEffect(service.recordingState == .recording ? 1.0 : 0.8)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: service.recordingState)

                Circle()
                    .fill(Theme.recordingRed)
                    .frame(width: 60, height: 60)

                Image(systemName: service.recordingState == .recording ? "waveform" : "pause.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }

            Text(service.formattedElapsedTime)
                .font(.system(size: 48, weight: .light, design: .monospaced))
                .foregroundColor(Theme.textPrimary)

            Text(service.recordingState == .recording ? "Recording in progress" : "Paused")
                .font(.system(size: 14))
                .foregroundColor(Theme.textSecondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Control Bar

struct ControlBarView: View {
    @ObservedObject private var service = ScreenCaptureService.shared

    var body: some View {
        HStack(spacing: 16) {
            // Record/Stop button
            Button(action: {
                if service.recordingState == .idle || service.recordingState == .stopped {
                    service.startRecording()
                } else {
                    service.stopRecording()
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: recordIcon)
                        .font(.system(size: 14))
                    Text(recordLabel)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(recordButtonColor)
                .foregroundColor(.white)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            // Pause/Resume button
            if service.recordingState.isActive {
                Button(action: {
                    if service.recordingState == .recording {
                        service.pauseRecording()
                    } else {
                        service.resumeRecording()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: service.recordingState == .recording ? "pause.fill" : "play.fill")
                            .font(.system(size: 12))
                        Text(service.recordingState == .recording ? "Pause" : "Resume")
                            .font(.system(size: 13))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Theme.backgroundTertiary)
                    .foregroundColor(Theme.textPrimary)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            Spacer()

            // Recordings count
            if !service.recordings.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 12))
                    Text("\(service.recordings.count) recording\(service.recordings.count == 1 ? "" : "s")")
                        .font(.system(size: 12))
                }
                .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Theme.backgroundSecondary)
    }

    private var recordIcon: String {
        switch service.recordingState {
        case .idle, .stopped: return "record.circle"
        case .recording, .paused, .stopping: return "stop.fill"
        }
    }

    private var recordLabel: String {
        switch service.recordingState {
        case .idle, .stopped: return "Record"
        case .recording, .paused, .stopping: return "Stop"
        }
    }

    private var recordButtonColor: Color {
        switch service.recordingState {
        case .idle, .stopped: return Theme.recordingRed
        case .recording, .paused, .stopping: return Theme.textSecondary
        }
    }
}

// MARK: - Display Picker

struct DisplayPickerView: View {
    @Binding var isPresented: Bool
    @ObservedObject private var service = ScreenCaptureService.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("Choose Display to Record")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Theme.textPrimary)

            Text("Select which display you want to record")
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary)

            Divider()

            // Just use main display for R1
            HStack {
                Image(systemName: "display")
                    .font(.system(size: 24))
                    .foregroundColor(Theme.accentBlue)

                VStack(alignment: .leading) {
                    Text("Main Display")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Theme.textPrimary)
                    Text("\(Int(CGDisplayPixelsWide(CGMainDisplayID()))) × \(Int(CGDisplayPixelsHigh(CGMainDisplayID())))")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)
                }

                Spacer()

                Button("Record") {
                    service.startRecording()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Theme.backgroundSecondary)
            .cornerRadius(8)

            Spacer()

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
            }
        }
        .padding(24)
        .frame(width: 400, height: 280)
    }
}
