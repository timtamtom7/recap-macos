import AppKit
import SwiftUI
import Combine

class MenuBarController: NSObject, ObservableObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var eventMonitor: Any?
    private var cancellables = Set<AnyCancellable>()

    private let service = ScreenCaptureService.shared

    override init() {
        super.init()
        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        observeRecordingState()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "record.circle", accessibilityDescription: "RECAP")
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 380)
        popover.behavior = .transient
        popover.animates = true
        popover.contentViewController = NSHostingController(rootView: MenuBarPopoverView())
    }

    private func setupEventMonitor() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let self = self, self.popover.isShown {
                self.popover.performClose(nil)
            }
        }
    }

    private func observeRecordingState() {
        service.$recordingState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateStatusIcon(for: state)
            }
            .store(in: &cancellables)
    }

    private func updateStatusIcon(for state: RecordingState) {
        guard let button = statusItem.button else { return }

        let symbolName: String
        let color: NSColor

        switch state {
        case .idle, .stopped:
            symbolName = "record.circle"
            color = .secondaryLabelColor
        case .recording:
            symbolName = "record.circle.fill"
            color = .systemRed
        case .paused:
            symbolName = "pause.circle.fill"
            color = .systemOrange
        case .stopping:
            symbolName = "record.circle"
            color = .secondaryLabelColor
        }

        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "RECAP") {
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            button.image = image.withSymbolConfiguration(config)
            button.contentTintColor = color
        }
    }

    @objc private func togglePopover() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }

    // MARK: - Actions

    func startRecording() {
        service.startRecording()
    }

    func togglePause() {
        if service.recordingState == .recording {
            service.pauseRecording()
        } else if service.recordingState == .paused {
            service.resumeRecording()
        }
    }

    func stopRecording() {
        service.stopRecording()
    }

    func showSettings() {
        // R2 - show settings window
    }

    func exportLastRecording() {
        guard let recording = service.recordings.first else { return }

        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.movie]
        savePanel.nameFieldStringValue = recording.title
        savePanel.directoryURL = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                self.service.exportRecording(recording, preset: SettingsStore.shared.qualityPreset, to: url) { success in
                    if success {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            }
        }
    }

    deinit {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
