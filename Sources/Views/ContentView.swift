import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var recordingVM = RecordingViewModel()
    @State private var selectedTab: Tab = .record

    enum Tab: String, CaseIterable {
        case record = "Record"
        case library = "Library"
        case settings = "Settings"

        var icon: String {
            switch self {
            case .record: return "record.circle.fill"
            case .library: return "film.stack.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            switch selectedTab {
            case .record:
                RecordingView()
                    .environmentObject(appState)
                    .environmentObject(recordingVM)
            case .library:
                RecordingsLibraryView()
                    .environmentObject(appState)
            case .settings:
                SettingsView()
                    .environmentObject(appState)
            }
        }
        .frame(minWidth: 700, minHeight: 500)
    }
}

struct SidebarView: View {
    @Binding var selectedTab: ContentView.Tab

    var body: some View {
        List(ContentView.Tab.allCases, id: \.self, selection: $selectedTab) { tab in
            Button {
                selectedTab = tab
            } label: {
                Label(tab.rawValue, systemImage: tab.icon)
                    .font(.title3.weight(.semibold))
            }
            .buttonStyle(.plain)
            .listRowBackground(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedTab == tab ? Color.accentColor.opacity(0.2) : Color.clear)
                    .padding(.vertical, 4)
            )
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
    }
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedCodec: Codec = .prores422
    @State private var includeAudio = true
    @State private var frameRate = 30
    @State private var exportPreset: ExportPreset = .standard

    var body: some View {
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
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .frame(width: 400, height: 350)
    }
}
