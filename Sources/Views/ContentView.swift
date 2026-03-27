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
            case .record: return "record.circle"
            case .library: return "film.stack"
            case .settings: return "gearshape"
            }
        }
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            currentDetailView
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 800, minHeight: 600)
    }

    @ViewBuilder
    private var currentDetailView: some View {
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
}

struct SidebarView: View {
    @Binding var selectedTab: ContentView.Tab
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text("RECAP")
                    .font(.title.weight(.bold))
                    .foregroundColor(.primary)
                Text("Screen Recorder")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
                .padding(.horizontal, 12)

            VStack(spacing: 4) {
                ForEach(ContentView.Tab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Label(tab.rawValue, systemImage: tab.icon)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                    )
                }
            }
            .padding(.vertical, 8)

            Spacer()

            if appState.isRecording {
                HStack(spacing: 8) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("Recording")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }
        }
        .background(
            Color(NSColor.windowBackgroundColor)
                .overlay(
                    Color(NSColor.controlBackgroundColor)
                        .opacity(0.5)
                )
        )
    }
}

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("includeAudio") private var includeAudio = true
    @AppStorage("frameRate") private var frameRate = 30
    @AppStorage("selectedCodec") private var selectedCodec = Codec.prores422.rawValue
    @AppStorage("exportPreset") private var exportPreset = ExportPreset.standard.rawValue
    @AppStorage("countdownSeconds") private var countdownSeconds = 3
    @AppStorage("autoStopRecording") private var autoStopRecording = false
    @AppStorage("maxRecordingDuration") private var maxRecordingDuration = 3600

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Settings")
                    .font(.largeTitle.weight(.bold))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)

                settingsSection(title: "Recording", icon: "record.circle") {
                    Toggle("Include Microphone Audio", isOn: $includeAudio)

                    Picker("Frame Rate", selection: $frameRate) {
                        Text("24 fps").tag(24)
                        Text("30 fps").tag(30)
                        Text("60 fps").tag(60)
                    }

                    Picker("Video Codec", selection: $selectedCodec) {
                        Text("ProRes 422 (Best Quality)").tag(Codec.prores422.rawValue)
                        Text("H.264 (Smaller File)").tag(Codec.h264.rawValue)
                    }
                }

                settingsSection(title: "Timer", icon: "timer") {
                    Stepper("Countdown: \(countdownSeconds)s", value: $countdownSeconds, in: 0...10)

                    Toggle("Auto-stop Recording", isOn: $autoStopRecording)

                    if autoStopRecording {
                        Stepper("Max Duration: \(maxRecordingDuration / 60) min", value: $maxRecordingDuration, in: 60...14400, step: 60)
                    }
                }

                settingsSection(title: "Export", icon: "square.and.arrow.up") {
                    Picker("Default Preset", selection: $exportPreset) {
                        ForEach(ExportPreset.allCases, id: \.rawValue) { preset in
                            Text(preset.rawValue).tag(preset.rawValue)
                        }
                    }
                }

                settingsSection(title: "About", icon: "info.circle") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(24)
            .frame(maxWidth: 700)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.primary)

            VStack(spacing: 0) {
                content()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.controlBackgroundColor))
            )
        }
    }
}
