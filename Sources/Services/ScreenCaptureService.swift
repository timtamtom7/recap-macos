import Foundation
import AVFoundation
import CoreMedia
import AppKit
import os.log

class ScreenCaptureService: NSObject {
    private var captureInput: AVCaptureScreenInput?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var assetWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var audioWriterInput: AVAssetWriterInput?

    private var isRecording = false
    private var isPaused = false
    private var session: ScreenRecordSession?
    private var display: DisplayInfo

    private let sessionQueue = DispatchQueue(label: "com.recap.captureSessionQueue")
    private let videoQueue = DispatchQueue(label: "com.recap.videoQueue")

    init(display: DisplayInfo) {
        self.display = display
        super.init()
    }

    func setupSession(_ session: ScreenRecordSession) {
        self.session = session

        guard let input = AVCaptureScreenInput(displayID: display.id) else {
            Log.capture.error("Failed to create screen input")
            return
        }

        input.minFrameDuration = CMTime(value: 1, timescale: CMTimeScale(session.frameRate))

        self.captureInput = input

        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoOutput.setSampleBufferDelegate(self, queue: videoQueue)

        self.videoDataOutput = videoOutput
    }

    func startCapture() throws {
        guard let input = captureInput else {
            throw CaptureError.inputNotConfigured
        }

        guard let session = session else {
            throw CaptureError.sessionNotConfigured
        }

        let writer = try AVAssetWriter(url: session.outputURL, fileType: .mov)

        let videoSettings: [String: Any] = [
            AVVideoCodecKey: session.codec.avCodec,
            AVVideoWidthKey: Int(display.resolution.width),
            AVVideoHeightKey: Int(display.resolution.height)
        ]

        let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
        videoInput.expectsMediaDataInRealTime = true
        videoInput.transform = CGAffineTransform(rotationAngle: 0)

        if writer.canAdd(videoInput) {
            writer.add(videoInput)
        }
        self.videoWriterInput = videoInput

        if session.includesAudio == true {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVLinearPCMBitDepthKey: 16,
                AVLinearPCMIsFloatKey: false,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false
            ]

            let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: audioSettings)
            audioInput.expectsMediaDataInRealTime = true

            if writer.canAdd(audioInput) {
                writer.add(audioInput)
            }
            self.audioWriterInput = audioInput
        }

        self.assetWriter = writer

        writer.startWriting()
        writer.startSession(atSourceTime: .zero)

        isRecording = true
    }

    func stopCapture() async throws -> URL {
        isRecording = false

        return try await withCheckedThrowingContinuation { continuation in
            videoWriterInput?.markAsFinished()
            audioWriterInput?.markAsFinished()

            assetWriter?.finishWriting { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: self?.session?.outputURL ?? URL(fileURLWithPath: ""))
                    return
                }

                if let error = self.assetWriter?.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: self.session?.outputURL ?? URL(fileURLWithPath: ""))
                }

                self.assetWriter = nil
                self.videoWriterInput = nil
                self.audioWriterInput = nil
            }
        }
    }

    func pauseCapture() {
        isPaused = true
    }

    func resumeCapture() {
        isPaused = false
    }

}

extension ScreenCaptureService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isRecording, !isPaused else { return }

        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)

        if assetWriter?.status == .writing {
            if videoWriterInput?.isReadyForMoreMediaData == true {
                videoWriterInput?.append(sampleBuffer)
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Frame dropped
    }
}

enum CaptureError: Error {
    case inputNotConfigured
    case sessionNotConfigured
    case writerNotReady
    case encodingFailed
}

extension Codec {
    var avCodec: AVVideoCodecType {
        switch self {
        case .prores422:
            return .proRes422
        case .h264:
            return .h264
        }
    }
}
