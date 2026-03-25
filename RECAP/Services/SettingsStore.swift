import Foundation
import Combine

class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let frameRate = "recording.frameRate"
        static let qualityPreset = "recording.qualityPreset"
        static let saveDirectory = "recording.saveDirectory"
        static let recordCursor = "recording.recordCursor"
        static let recordAudio = "recording.recordAudio"
        static let launchAtLogin = "app.launchAtLogin"
        static let showInMenuBar = "app.showInMenuBar"
        static let countdownSeconds = "recording.countdownSeconds"
    }

    @Published var frameRate: Int {
        didSet { defaults.set(frameRate, forKey: Keys.frameRate) }
    }

    @Published var qualityPreset: ExportPreset {
        didSet { defaults.set(qualityPreset.rawValue, forKey: Keys.qualityPreset) }
    }

    @Published var saveDirectory: URL {
        didSet { defaults.set(saveDirectory.path, forKey: Keys.saveDirectory) }
    }

    @Published var recordCursor: Bool {
        didSet { defaults.set(recordCursor, forKey: Keys.recordCursor) }
    }

    @Published var recordAudio: Bool {
        didSet { defaults.set(recordAudio, forKey: Keys.recordAudio) }
    }

    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Keys.launchAtLogin) }
    }

    @Published var showInMenuBar: Bool {
        didSet { defaults.set(showInMenuBar, forKey: Keys.showInMenuBar) }
    }

    @Published var countdownSeconds: Int {
        didSet { defaults.set(countdownSeconds, forKey: Keys.countdownSeconds) }
    }

    private init() {
        let moviesURL = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("RECAP", isDirectory: true)

        self.frameRate = defaults.object(forKey: Keys.frameRate) as? Int ?? 30
        self.qualityPreset = ExportPreset(rawValue: defaults.string(forKey: Keys.qualityPreset) ?? "") ?? .standard
        self.saveDirectory = URL(fileURLWithPath: defaults.string(forKey: Keys.saveDirectory) ?? moviesURL.path)
        self.recordCursor = defaults.object(forKey: Keys.recordCursor) as? Bool ?? true
        self.recordAudio = defaults.object(forKey: Keys.recordAudio) as? Bool ?? false
        self.launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)
        self.showInMenuBar = defaults.object(forKey: Keys.showInMenuBar) as? Bool ?? true
        self.countdownSeconds = defaults.object(forKey: Keys.countdownSeconds) as? Int ?? 0
    }
}
