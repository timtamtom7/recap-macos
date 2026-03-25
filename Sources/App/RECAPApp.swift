import SwiftUI

struct RECAPApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) { }

            CommandGroup(after: .toolbar) {
                Button("Start Recording") {
                    appState.toggleRecording()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])

                Button("Pause Recording") {
                    appState.togglePause()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
            }

            CommandGroup(after: .appInfo) {
                Button("Settings...") {
                    appState.showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        MenuBarExtra {
            MenuBarPopoverView()
                .environmentObject(appState)
        } label: {
            Label("RECAP", systemImage: appState.recordingState.iconName)
        }
    }
}
