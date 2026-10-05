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
        RecapAPIService.shared.start()

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
        RecapAPIService.shared.stop()
        if AppState.shared.recordingState == .recording {
            AppState.shared.stopRecording()
        }
        ClickDetector.shared.stop()
        GlobalHotkeyService.shared.stop()
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
