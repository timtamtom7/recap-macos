import Foundation
import AVFoundation
import CoreMedia

class ScreenRecordSession {
    let id: UUID
    let display: DisplayInfo
    let outputURL: URL
    let includesAudio: Bool
    let codec: Codec
    let resolution: CGSize
    let frameRate: Int

    private let captureService: ScreenCaptureService
    private var startTime: CMTime?

    init(display: DisplayInfo, includesAudio: Bool = true, codec: Codec = .prores422, frameRate: Int = 30) {
        self.id = UUID()
        self.display = display
        self.includesAudio = includesAudio
        self.codec = codec
        self.resolution = display.resolution
        self.frameRate = frameRate

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HHmmss"
        let timestamp = formatter.string(from: Date())
        let filename = "Recording-\(timestamp)"

        let moviesDir = FileManager.default.urls(for: .moviesDirectory, in: .userDomainMask).first!
        let recapDir = moviesDir.appendingPathComponent("RECAP", isDirectory: true)
        try? FileManager.default.createDirectory(at: recapDir, withIntermediateDirectories: true)

        self.outputURL = recapDir.appendingPathComponent("\(filename).mov")

        self.captureService = ScreenCaptureService(display: display)
        self.captureService.setupSession(self)
    }

    func startRecording() throws {
        try captureService.startCapture()
    }

    func pauseRecording() {
        captureService.pauseCapture()
    }

    func resumeRecording() {
        captureService.resumeCapture()
    }

    func stopRecording() async throws -> URL {
        return try await captureService.stopCapture()
    }
}

enum Codec: String {
    case prores422 = "prores422"
    case h264 = "h264"
}
