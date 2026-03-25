import AppKit
import SwiftUI
import AVFoundation
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindowController: MainWindowController?
    var menuBarController: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        RecordingStore.shared.setup()
        mainWindowController = MainWindowController()
        mainWindowController?.showWindow(nil)

        NSApp.setActivationPolicy(.accessory)
        NSApp.activate(ignoringOtherApps: true)

        requestScreenRecordingPermission()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return false
    }

    func applicationWillTerminate(_ notification: Notification) {
        if AppState.shared.recordingState == .recording {
            AppState.shared.stopRecording()
        }
    }

    private func requestScreenRecordingPermission() {
        if #available(macOS 10.15, *) {
            switch CGPreflightScreenCaptureAccess() {
            case true:
                break
            case false:
                CGRequestScreenCaptureAccess()
            }
        }
    }
}

extension Notification.Name {
    static let recordingStateChanged = Notification.Name("recordingStateChanged")
    static let showDisplayPicker = Notification.Name("showDisplayPicker")
}
