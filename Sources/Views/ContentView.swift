import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var recordingVM = RecordingViewModel()
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            RecordingView()
                .environmentObject(appState)
                .environmentObject(recordingVM)
                .tabItem {
                    Label("Record", systemImage: "record.circle")
                }
                .tag(0)

            RecordingsLibraryView()
                .environmentObject(appState)
                .tabItem {
                    Label("Library", systemImage: "film.stack")
                }
                .tag(1)

            SettingsView()
                .environmentObject(appState)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .frame(minWidth: 700, minHeight: 500)
        .sheet(isPresented: $appState.showSettings) {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCodec: Codec = .prores422
    @State private var includeAudio = true
    @State private var frameRate = 30
    @State private var exportPreset: ExportPreset = .standard

    var body: some View {
        VStack(spacing: 20) {
            Text("RECAP Settings")
                .font(.headline)

            Form {
                Section("Recording") {
                    Toggle("Include Audio", isOn: $includeAudio)

                    Picker("Frame Rate", selection: $frameRate) {
                        Text("24 fps").tag(24)
                        Text("30 fps").tag(30)
                        Text("60 fps").tag(60)
                    }

                    Picker("Codec", selection: $selectedCodec) {
                        Text("ProRes 422 (High Quality)").tag(Codec.prores422)
                        Text("H.264 (Standard)").tag(Codec.h264)
                    }
                }

                Section("Export Default") {
                    Picker("Export Preset", selection: $exportPreset) {
                        ForEach(ExportPreset.allCases) { preset in
                            Text(preset.rawValue).tag(preset)
                        }
                    }
                }
            }
            .padding()

            HStack {
                Spacer()
                Button("Done") {
                    appState.showSettings = false
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 400, height: 350)
    }
}
