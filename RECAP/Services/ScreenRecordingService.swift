import AVFoundation
import AppKit
import Combine

class ScreenCaptureService: NSObject, ObservableObject {
    static let shared = ScreenCaptureService()

    @Published var recordingState: RecordingState = .idle
    @Published var elapsedTime: TimeInterval = 0
    @Published var currentRecordingURL: URL?
    @Published var recordings: [Recording] = []

    private var captureSession: AVCaptureSession?
    private var assetWriter: AVAssetWriter?
    private var videoInput: AVAssetWriterInput?
    private var audioInput: AVAssetWriterInput?
    private var previewLayer: AVCaptureVideoPreviewLayer?

    private var displayID: CGDirectDisplayID = CGMainDisplayID()
    private var isPaused = false
    private var startTime: CMTime?
    private var pauseStartTime: CMTime?
    private var totalPauseDuration: CMTime = .zero
    private var lastPauseStart: CMTime?

    private var timer: Timer?
    private var fileHandle: AVAssetWriter?

    private let outputDirectory: URL = {
        let url = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("RECAP", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()

    override init() {
        super.init()
        loadRecordings()
    }

    // MARK: - Permissions

    func hasScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }

    func requestScreenRecordingPermission() {
        CGRequestScreenCaptureAccess()
    }

    // MARK: - Session Setup

    func setupSession(for displayID: CGDirectDisplayID) -> AVCaptureSession? {
        self.displayID = displayID

        let session = AVCaptureSession()
        session.beginConfiguration()

        // Screen input
        guard let screenInput = AVCaptureScreenInput(displayID: displayID) else {
            return nil
        }
        screenInput.minFrameDuration = CMTime(value: 1, timescale: 30)

        if session.canAddInput(screenInput) {
            session.addInput(screenInput)
        }

        session.commitConfiguration()
        return session
    }

    // MARK: - Recording

    func startRecording(preset: ExportPreset = .standard) {
        guard recordingState == .idle || recordingState == .stopped else { return }

        let fileName = "Recording-\(formattedTimestamp()).\(preset.fileExtension)"
        let fileURL = outputDirectory.appendingPathComponent(fileName)
        currentRecordingURL = fileURL

        do {
            assetWriter = try AVAssetWriter(outputURL: fileURL, fileType: preset == .highQuality ? .mov : .mp4)
        } catch {
            print("Failed to create asset writer: \(error)")
            return
        }

        // Video settings
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: preset == .highQuality ? AVVideoCodecType.proRes422 : AVVideoCodecType.h264,
            AVVideoWidthKey: CGDisplayPixelsWide(displayID),
            AVVideoHeightKey: CGDisplayPixelsHigh(displayID)
        ]

        videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput?.expectsMediaDataInRealTime = true

        if let videoInput = videoInput, assetWriter?.canAdd(videoInput) == true {
            assetWriter?.add(videoInput)
        }

        // Audio settings (display audio)
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false,
            AVLinearPCMIsNonInterleaved: false
        ]

        audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
        audioInput?.expectsMediaDataInRealTime = true

        if let audioInput = audioInput, assetWriter?.canAdd(audioInput) == true {
            assetWriter?.add(audioInput)
        }

        assetWriter?.startWriting()
        assetWriter?.startSession(atSourceTime: .zero)

        recordingState = .recording
        isPaused = false
        elapsedTime = 0
        startTime = nil
        totalPauseDuration = .zero
        pauseStartTime = nil
        lastPauseStart = nil

        startTimer()
    }

    func pauseRecording() {
        guard recordingState == .recording else { return }
        recordingState = .paused
        isPaused = true
        lastPauseStart = pauseStartTime ?? CMClockGetTime(CMClockGetHostTimeClock())
        pauseStartTime = lastPauseStart
    }

    func resumeRecording() {
        guard recordingState == .paused else { return }
        if let lastStart = lastPauseStart {
            let pauseDuration = CMTimeSubtract(CMClockGetTime(CMClockGetHostTimeClock()), lastStart)
            totalPauseDuration = CMTimeAdd(totalPauseDuration, pauseDuration)
        }
        recordingState = .recording
        isPaused = false
        lastPauseStart = nil
    }

    func stopRecording() {
        guard recordingState == .recording || recordingState == .paused else { return }
        recordingState = .stopping

        stopTimer()

        videoInput?.markAsFinished()
        audioInput?.markAsFinished()

        assetWriter?.finishWriting { [weak self] in
            DispatchQueue.main.async {
                self?.finalizeRecording()
            }
        }
    }

    private func finalizeRecording() {
        guard let url = currentRecordingURL else {
            recordingState = .idle
            return
        }

        let fileSize = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0

        let recording = Recording(
            title: url.deletingPathExtension().lastPathComponent,
            filePath: url,
            duration: elapsedTime,
            createdAt: Date(),
            fileSize: fileSize,
            displayName: "Display \(displayID)",
            includesAudio: true,
            codec: assetWriter?.outputFileType == .mov ? "prores422" : "h264",
            resolutionWidth: Int(CGDisplayPixelsWide(displayID)),
            resolutionHeight: Int(CGDisplayPixelsHigh(displayID))
        )

        recordings.insert(recording, at: 0)
        saveRecordings()

        recordingState = .stopped
        currentRecordingURL = nil
        assetWriter = nil
        videoInput = nil
        audioInput = nil
        elapsedTime = 0
    }

    // MARK: - Frame Writing

    func writeVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard recordingState == .recording,
              let videoInput = videoInput,
              videoInput.isReadyForMoreMediaData else { return }

        if startTime == nil {
            startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        }

        videoInput.append(sampleBuffer)
    }

    func writeAudioSampleBuffer(_ sampleBuffer: CMSampleBuffer) {
        guard recordingState == .recording,
              let audioInput = audioInput,
              audioInput.isReadyForMoreMediaData else { return }

        audioInput.append(sampleBuffer)
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.recordingState == .recording else { return }
            self.elapsedTime += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Helpers

    private func formattedTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        return formatter.string(from: Date())
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

    // MARK: - Persistence

    private func saveRecordings() {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("RECAP", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)

        let fileURL = url.appendingPathComponent("recordings.json")
        let data = try? JSONEncoder().encode(recordings)
        try? data?.write(to: fileURL)
    }

    private func loadRecordings() {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("RECAP", isDirectory: true)
            .appendingPathComponent("recordings.json")

        guard let data = try? Data(contentsOf: url),
              let saved = try? JSONDecoder().decode([Recording].self, from: data) else { return }
        recordings = saved
    }

    // MARK: - Export

    func exportRecording(_ recording: Recording, preset: ExportPreset, to destination: URL, completion: @escaping (Bool) -> Void) {
        let asset = AVAsset(url: recording.filePath)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            completion(false)
            return
        }

        exportSession.outputURL = destination
        exportSession.outputFileType = preset == .highQuality ? .mov : .mp4

        exportSession.exportAsynchronously {
            DispatchQueue.main.async {
                completion(exportSession.status == .completed)
            }
        }
    }

    func deleteRecording(_ recording: Recording) {
        try? FileManager.default.removeItem(at: recording.filePath)
        if let thumbnailPath = recording.thumbnailPath {
            try? FileManager.default.removeItem(at: thumbnailPath)
        }
        recordings.removeAll { $0.id == recording.id }
        saveRecordings()
    }
}
