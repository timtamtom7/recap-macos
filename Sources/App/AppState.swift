import Foundation
import AVFoundation
import Combine
import AppKit

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    @Published var recordingState: RecordingState = .idle
    @Published var elapsedTime: TimeInterval = 0
    @Published var showSettings = false
    @Published var selectedDisplay: DisplayInfo?
    @Published var selectedWindow: WindowInfo?
    @Published var recentRecordings: [Recording] = []
    @Published var isExporting = false
    @Published var exportProgress: Double = 0

    var captureService: ScreenCaptureService?
    private var session: ScreenRecordSession?
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private let recordingStore = RecordingStore.shared

    private init() {
        loadRecentRecordings()
    }

    var isRecording: Bool {
        recordingState == .recording || recordingState == .paused
    }

    func toggleRecording() {
        switch recordingState {
        case .idle:
            startRecording()
        case .recording, .paused:
            stopRecording()
        case .stopping, .stopped:
            break
        }
    }

    func togglePause() {
        switch recordingState {
        case .recording:
            pauseRecording()
        case .paused:
            resumeRecording()
        default:
            break
        }
    }

    func startRecording() {
        guard let display = selectedDisplay ?? getMainDisplay() else {
            NotificationCenter.default.post(name: .showDisplayPicker, object: nil)
            return
        }

        let recordSession = ScreenRecordSession(display: display)
        session = recordSession

        do {
            try recordSession.startRecording()
            recordingState = .recording
            startTimer()
            NotificationCenter.default.post(name: .recordingStateChanged, object: nil)
        } catch {
            print("Failed to start recording: \(error)")
            recordingState = .idle
        }
    }

    func pauseRecording() {
        session?.pauseRecording()
        recordingState = .paused
        stopTimer()
        NotificationCenter.default.post(name: .recordingStateChanged, object: nil)
    }

    func resumeRecording() {
        session?.resumeRecording()
        recordingState = .recording
        startTimer()
        NotificationCenter.default.post(name: .recordingStateChanged, object: nil)
    }

    func stopRecording() {
        recordingState = .stopping
        stopTimer()

        Task {
            guard let session = session else {
                await MainActor.run { self.recordingState = .idle }
                return
            }

            do {
                let outputURL = try await session.stopRecording()
                await MainActor.run {
                    self.recordingState = .stopped
                    self.handleRecordingComplete(outputURL: outputURL, session: session)
                }
            } catch {
                print("Failed to stop recording: \(error)")
                await MainActor.run { self.recordingState = .idle }
            }
        }
    }

    private func handleRecordingComplete(outputURL: URL, session: ScreenRecordSession) {
        let recording = Recording(
            id: UUID(),
            title: outputURL.deletingPathExtension().lastPathComponent,
            filePath: outputURL,
            duration: elapsedTime,
            createdAt: Date(),
            thumbnailPath: nil,
            fileSize: (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64) ?? 0,
            displayName: selectedDisplay?.name,
            includesAudio: session.includesAudio,
            codec: session.codec.rawValue,
            resolution: session.resolution
        )

        recordingStore.saveRecording(recording)
        recentRecordings.insert(recording, at: 0)
        if recentRecordings.count > 10 {
            recentRecordings.removeLast()
        }

        elapsedTime = 0
        recordingState = .idle
        NotificationCenter.default.post(name: .recordingStateChanged, object: nil)
    }

    func selectDisplay(_ display: DisplayInfo) {
        selectedDisplay = display
        selectedWindow = nil
    }

    func selectWindow(_ window: WindowInfo) {
        selectedWindow = window
        selectedDisplay = nil
    }

    func loadRecentRecordings() {
        recentRecordings = recordingStore.getRecentRecordings(limit: 10)
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.elapsedTime += 1
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func getMainDisplay() -> DisplayInfo? {
        let screen = NSScreen.main
        guard let screen = screen else { return nil }
        let displayID = CGMainDisplayID()
        return DisplayInfo(id: displayID, name: "Main Display", bounds: screen.frame)
    }

    var formattedElapsedTime: String {
        let hours = Int(elapsedTime) / 3600
        let minutes = (Int(elapsedTime) % 3600) / 60
        let seconds = Int(elapsedTime) % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

struct DisplayInfo: Identifiable, Hashable {
    let id: CGDirectDisplayID
    let name: String
    let bounds: CGRect

    var resolution: CGSize {
        CGSize(width: bounds.width, height: bounds.height)
    }
}

struct WindowInfo: Identifiable, Hashable {
    let id: CGWindowID
    let name: String
    let ownerName: String
    let bounds: CGRect
}
