import SwiftUI

struct MenuBarPopoverView: View {
    @ObservedObject private var service = ScreenCaptureService.shared
    @ObservedObject private var settings = SettingsStore.shared

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)

                Text("RECAP")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Theme.textPrimary)

                Spacer()

                Text(statusText)
                    .font(.system(size: 11))
                    .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Theme.backgroundSecondary)

            Divider()

            // Timer (if recording)
            if service.recordingState.isActive {
                HStack {
                    Image(systemName: "timer")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textSecondary)

                    Text(service.formattedElapsedTime)
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(Theme.textPrimary)

                    Spacer()

                    Text(service.recordingState == .recording ? "Recording" : "Paused")
                        .font(.system(size: 11))
                        .foregroundColor(service.recordingState == .recording ? Theme.recordingRed : Theme.pausedOrange)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Theme.backgroundTertiary.opacity(0.5))

                Divider()
            }

            // Controls
            VStack(spacing: 2) {
                if service.recordingState == .idle || service.recordingState == .stopped {
                    ControlRow(icon: "record.circle", title: "Start Recording", color: Theme.recordingRed) {
                        service.startRecording()
                    }
                } else {
                    ControlRow(icon: service.recordingState == .recording ? "pause.fill" : "play.fill",
                               title: service.recordingState == .recording ? "Pause" : "Resume",
                               color: Theme.pausedOrange) {
                        if service.recordingState == .recording {
                            service.pauseRecording()
                        } else {
                            service.resumeRecording()
                        }
                    }

                    ControlRow(icon: "stop.fill", title: "Stop", color: Theme.textSecondary) {
                        service.stopRecording()
                    }
                }
            }
            .padding(.vertical, 8)

            Divider()

            // Recent Recordings
            VStack(alignment: .leading, spacing: 8) {
                Text("Recent Recordings")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Theme.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 10)

                if service.recordings.isEmpty {
                    Text("No recordings yet")
                        .font(.system(size: 12))
                        .foregroundColor(Theme.textTertiary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 10)
                } else {
                    ForEach(service.recordings.prefix(3)) { recording in
                        RecordingRowView(recording: recording)
                    }
                    .padding(.bottom, 8)
                }
            }

            Divider()

            // Bottom actions
            HStack {
                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                    if let window = NSApp.windows.first {
                        window.makeKeyAndOrderFront(nil)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "rectangle.on.rectangle")
                            .font(.system(size: 11))
                        Text("Open RECAP")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.textSecondary)

                Spacer()

                Button(action: {}) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 11))
                        Text("Settings")
                            .font(.system(size: 12))
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(Theme.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .frame(width: 300)
        .background(Theme.backgroundPrimary)
    }

    private var statusColor: Color {
        switch service.recordingState {
        case .idle, .stopped: return Theme.textTertiary
        case .recording: return Theme.recordingRed
        case .paused: return Theme.pausedOrange
        case .stopping: return Theme.textTertiary
        }
    }

    private var statusText: String {
        switch service.recordingState {
        case .idle, .stopped: return "Ready"
        case .recording: return "● RECAP"
        case .paused: return "⏸ RECAP"
        case .stopping: return "Stopping..."
        }
    }
}

// MARK: - Control Row

struct ControlRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                    .frame(width: 20)

                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textPrimary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recording Row

struct RecordingRowView: View {
    let recording: Recording

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "film")
                .font(.system(size: 14))
                .foregroundColor(Theme.accentBlue)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(recording.title)
                    .font(.system(size: 12))
                    .foregroundColor(Theme.textPrimary)
                    .lineLimit(1)

                Text("\(recording.formattedDuration) • \(recording.formattedFileSize)")
                    .font(.system(size: 10))
                    .foregroundColor(Theme.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 10))
                .foregroundColor(Theme.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            NSWorkspace.shared.activateFileViewerSelecting([recording.filePath])
        }
    }
}
