import AppKit
import SwiftUI

class MainWindowController: NSWindowController {
    convenience init() {
        let contentView = ContentView()
            .environmentObject(AppState.shared)

        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "RECAP"
        window.minSize = NSSize(width: 600, height: 450)
        window.center()
        window.contentViewController = hostingController

        self.init(window: window)
    }
}
