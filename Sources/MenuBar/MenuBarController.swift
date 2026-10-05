import AppKit
import SwiftUI

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?

    override init() {
        super.init()
        setupStatusItem()
        setupPopover()
        setupNotifications()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "record.circle", accessibilityDescription: "RECAP")
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 320, height: 440)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: EnhancedMenuBarPopoverView()
                .environmentObject(AppState.shared)
        )
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateIcon),
            name: .recordingStateChanged,
            object: nil
        )
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent

        if event?.type == .rightMouseUp {
            showContextMenu(sender)
        } else {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    private func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()
        menu.addItem(withTitle: "Start Recording", action: #selector(startRecording), keyEquivalent: "")
        menu.addItem(withTitle: "Pause", action: #selector(togglePause), keyEquivalent: "")
        menu.addItem(withTitle: "Stop Recording", action: #selector(stopRecording), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Open RECAP", action: #selector(openRECAP), keyEquivalent: "")
        menu.addItem(withTitle: "Settings...", action: #selector(openSettings), keyEquivalent: "")
        menu.addItem(NSMenuItem.separator())
        menu.addItem(withTitle: "Quit RECAP", action: #selector(quitRECAP), keyEquivalent: "")
        menu.delegate = self
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }

    @objc private func startRecording() {
        NotificationCenter.default.post(name: .startRecording, object: nil)
    }

    @objc private func togglePause() {
        NotificationCenter.default.post(name: .togglePause, object: nil)
    }

    @objc private func stopRecording() {
        NotificationCenter.default.post(name: .stopRecording, object: nil)
    }

    @objc private func openRECAP() {
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openSettings() {
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }

    @objc private func quitRECAP() {
        NSApp.terminate(nil)
    }

    @objc private func updateIcon() {
        guard let button = statusItem?.button else { return }
        Task { @MainActor in
            let iconName = AppState.shared.recordingState.iconName
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "RECAP")
        }
    }
}

extension MenuBarController: NSMenuDelegate {}

struct EnhancedMenuBarPopoverView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var scheduleService = ScheduledRecordingService.shared

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            ScrollView {
                VStack(spacing: 12) {
                    if appState.recordingState == .recording || appState.recordingState == .paused {
                        recordingStatusCard
                    }
                    if !scheduleService.scheduledRecordings.isEmpty {
                        scheduledRecordingsCard
                    }
                    recentRecordingsCard
                }
                .padding()
            }
            Divider()
            footer
        }
    }

    private var header: some View {
        HStack {
            Image(systemName: "record.circle.fill")
                .foregroundColor(appState.recordingState == .recording ? .red : .accentColor)
            Text("RECAP")
                .font(.headline)
            Spacer()
            Button(action: {
                NotificationCenter.default.post(name: .openSettings, object: nil)
            }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var recordingStatusCard: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(appState.recordingState == .recording ? Color.red : Color.orange)
                    .frame(width: 8, height: 8)
                Text(appState.recordingState == .recording ? "Recording" : "Paused")
                    .font(.system(size: 13, weight: .medium))
                Spacer()
                Text(appState.formattedElapsedTime)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Button(appState.recordingState == .paused ? "Resume" : "Pause") {
                    NotificationCenter.default.post(name: .togglePause, object: nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.accentColor)

                Button("Stop") {
                    NotificationCenter.default.post(name: .stopRecording, object: nil)
                }
                .buttonStyle(.plain)
                .foregroundColor(.red)
            }
            .font(.caption)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var scheduledRecordingsCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                Text("Scheduled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(scheduleService.scheduledRecordings.prefix(2)) { recording in
                HStack {
                    Text(recording.name)
                        .font(.caption)
                    Spacer()
                    if let next = recording.nextScheduledDate {
                        Text(next, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var recentRecordingsCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "clock")
                    .font(.caption)
                Text("Recent")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(Array(RecordingStore.shared.getRecentRecordings(limit: 3).enumerated()), id: \.offset) { _, recording in
                HStack {
                    Image(systemName: "video.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(recording.title)
                        .font(.caption)
                        .lineLimit(1)
                    Spacer()
                    Text(recording.formattedDuration)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .onTapGesture {
                    NSWorkspace.shared.open(recording.filePath)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var footer: some View {
        HStack {
            Button("Open RECAP") {
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
            Spacer()
            Button("All Recordings") {
                NSApp.activate(ignoringOtherApps: true)
                NotificationCenter.default.post(name: .openLibrary, object: nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.accentColor)
        }
        .padding()
    }
}
