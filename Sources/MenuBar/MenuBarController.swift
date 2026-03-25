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
            button.action = #selector(togglePopover)
            button.target = self
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 350)
        popover?.behavior = .transient
        popover?.contentViewController = NSHostingController(
            rootView: MenuBarPopoverView()
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

    @objc private func togglePopover() {
        guard let button = statusItem?.button, let popover = popover else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    @objc private func updateIcon() {
        guard let button = statusItem?.button else { return }

        Task { @MainActor in
            let iconName = AppState.shared.recordingState.iconName
            button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "RECAP")

            if AppState.shared.recordingState == .recording {
                self.animateRecordingIcon()
            }
        }
    }

    private func animateRecordingIcon() {
        guard let button = statusItem?.button else { return }

        Task { @MainActor in
            guard AppState.shared.recordingState == .recording else { return }

            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.5
                context.allowsImplicitAnimation = true
                button.alphaValue = 0.3
            } completionHandler: { [weak self] in
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.5
                    context.allowsImplicitAnimation = true
                    button.alphaValue = 1.0
                }

                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self?.animateRecordingIcon()
                }
            }
        }
    }
}
