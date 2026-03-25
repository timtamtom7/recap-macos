import AppKit
import SwiftUI
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var popover: NSPopover!
    var menuBarController: MenuBarController!
    var windowController: RecordingWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        menuBarController = MenuBarController()

        setupMainMenu()

        if !ScreenCaptureService.shared.hasScreenRecordingPermission() {
            ScreenCaptureService.shared.requestScreenRecordingPermission()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()

        // App menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About RECAP", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit RECAP", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // File menu
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(withTitle: "Export Recording...", action: #selector(exportRecording), keyEquivalent: "e")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // Recording menu
        let recordMenuItem = NSMenuItem()
        let recordMenu = NSMenu(title: "Recording")
        recordMenu.addItem(withTitle: "Start Recording", action: #selector(startRecording), keyEquivalent: "r")
        recordMenu.addItem(withTitle: "Pause/Resume", action: #selector(togglePause), keyEquivalent: "p")
        recordMenu.addItem(withTitle: "Stop Recording", action: #selector(stopRecording), keyEquivalent: ".")
        recordMenuItem.submenu = recordMenu
        mainMenu.addItem(recordMenuItem)

        // Window menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Show RECAP", action: #selector(showMainWindow), keyEquivalent: "1")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.miniaturize(_:)), keyEquivalent: "m")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc func openSettings() {
        menuBarController.showSettings()
    }

    @objc func exportRecording() {
        menuBarController.exportLastRecording()
    }

    @objc func startRecording() {
        menuBarController.startRecording()
    }

    @objc func togglePause() {
        menuBarController.togglePause()
    }

    @objc func stopRecording() {
        menuBarController.stopRecording()
    }

    @objc func showMainWindow() {
        if windowController == nil {
            windowController = RecordingWindowController()
        }
        windowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Recording Window Controller

class RecordingWindowController: NSWindowController {
    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 450),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "RECAP"
        window.center()
        window.isReleasedWhenClosed = false

        self.init(window: window)

        let contentView = ContentView()
        window.contentView = NSHostingView(rootView: contentView)
    }
}
