import Foundation
import AVFoundation
import AppKit
import ImageIO
import UniformTypeIdentifiers

final class GIFExportService {
    private var assetWriter: AVAssetWriter?
    private var assetReader: AVAssetReader?

    func exportGIF(from recording: Recording, options: GIFExportOptions, progress: @escaping (Double) -> Void) async throws -> URL {
        let asset = AVAsset(url: recording.filePath)
        let duration = try await asset.load(.duration).seconds

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("gif")

        let track = try await asset.loadTracks(withMediaType: .video).first!
        let naturalSize = try await track.load(.naturalSize)

        let outputSize: CGSize
        if let presetSize = options.resolution.size {
            let aspectRatio = naturalSize.height / naturalSize.width
            outputSize = CGSize(width: presetSize.width, height: presetSize.width * aspectRatio)
        } else {
            outputSize = naturalSize
        }

        guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.gif.identifier as CFString, 0, nil) else {
            throw GIFExportError.cannotCreateDestination
        }

        let frameCount = Int(duration * Double(options.frameRate.rawValue))
        let frameDuration = 1.0 / Double(options.frameRate.rawValue)

        let properties: [String: Any] = [
            kCGImagePropertyGIFDictionary as String: [
                kCGImagePropertyGIFLoopCount as String: options.loopCount.count
            ]
        ]
        CGImageDestinationSetProperties(destination, properties as CFDictionary)

        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = outputSize

        let times = (0..<frameCount).map { i -> NSValue in
            let time = CMTime(seconds: Double(i) * frameDuration, preferredTimescale: 600)
            return NSValue(time: time)
        }

        var frameIndex = 0
        let lock = NSLock()

        await withCheckedContinuation { continuation in
            generator.generateCGImagesAsynchronously(forTimes: times) { requestedTime, cgImage, actualTime, result, error in
                lock.lock()
                defer { lock.unlock() }

                if let cgImage = cgImage {
                    let frameProperties: [String: Any] = [
                        kCGImagePropertyGIFDictionary as String: [
                            kCGImagePropertyGIFDelayTime as String: frameDuration
                        ]
                    ]
                    CGImageDestinationAddImage(destination, cgImage, frameProperties as CFDictionary)
                }

                frameIndex += 1
                let currentProgress = Double(frameIndex) / Double(frameCount)
                DispatchQueue.main.async {
                    progress(currentProgress)
                }

                if frameIndex >= frameCount {
                    continuation.resume()
                }
            }
        }

        guard CGImageDestinationFinalize(destination) else {
            throw GIFExportError.finalizationFailed
        }

        return outputURL
    }

    func estimateSize(duration: TimeInterval, options: GIFExportOptions) -> String {
        let frameCount = Int(duration * Double(options.frameRate.rawValue))
        let bytesPerFrame: Double

        switch options.resolution {
        case .original, .p720:
            bytesPerFrame = 80000
        case .p480:
            bytesPerFrame = 40000
        case .p360:
            bytesPerFrame = 20000
        }

        let colorFactor: Double
        switch options.quality {
        case .low: colorFactor = 1.0
        case .medium: colorFactor = 0.8
        case .high: colorFactor = 0.6
        }

        let totalBytes = Double(frameCount) * bytesPerFrame * colorFactor
        return ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
    }

    enum GIFExportError: LocalizedError {
        case cannotCreateDestination
        case finalizationFailed

        var errorDescription: String? {
            switch self {
            case .cannotCreateDestination: return "Could not create GIF destination"
            case .finalizationFailed: return "Failed to finalize GIF export"
            }
        }
    }
}
