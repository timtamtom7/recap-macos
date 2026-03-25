import Foundation
import AVFoundation
import CoreImage

final class CropService {
    struct CropRegion: Codable {
        var x: Double
        var y: Double
        var width: Double
        var height: Double
        var aspectRatio: AspectRatio = .free

        enum AspectRatio: String, CaseIterable, Codable {
            case free = "Free"
            case ratio16x9 = "16:9"
            case ratio4x3 = "4:3"
            case ratio1x1 = "1:1"
            case ratio9x16 = "9:16"

            var value: Double? {
                switch self {
                case .free: return nil
                case .ratio16x9: return 16.0 / 9.0
                case .ratio4x3: return 4.0 / 3.0
                case .ratio1x1: return 1.0
                case .ratio9x16: return 9.0 / 16.0
                }
            }
        }

        func apply(to size: CGSize) -> CGRect {
            CGRect(
                x: x * size.width,
                y: y * size.height,
                width: width * size.width,
                height: height * size.height
            )
        }
    }

    func crop(recording: Recording, region: CropRegion, progress: @escaping (Double) -> Void) async throws -> Recording {
        let asset = AVAsset(url: recording.filePath)
        let videoTrack = try await asset.loadTracks(withMediaType: .video).first!
        let naturalSize = try await videoTrack.load(.naturalSize)

        let videoComposition = AVMutableVideoComposition(propertiesOf: asset)
        let cropRect = region.apply(to: naturalSize)

        videoComposition.renderSize = cropRect.size

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: try await asset.load(.duration))

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        let transform = CGAffineTransform(translationX: -cropRect.origin.x, y: -cropRect.origin.y)
        layerInstruction.setTransform(transform, at: .zero)

        instruction.layerInstructions = [layerInstruction]
        videoComposition.instructions = [instruction]

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw CropError.cannotCreateExportSession
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4
        exportSession.videoComposition = videoComposition

        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            progress(Double(exportSession.progress))
        }

        await exportSession.export()
        progressTimer.invalidate()

        guard exportSession.status == .completed else {
            throw exportSession.error ?? CropError.exportFailed
        }

        let newFileSize = (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64) ?? 0

        return Recording(
            id: UUID(),
            title: "\(recording.title) (Cropped)",
            filePath: outputURL,
            duration: recording.duration,
            createdAt: Date(),
            thumbnailPath: nil,
            fileSize: newFileSize,
            displayName: recording.displayName,
            includesAudio: recording.includesAudio,
            codec: recording.codec,
            resolution: cropRect.size
        )
    }

    enum CropError: LocalizedError {
        case cannotCreateExportSession
        case exportFailed

        var errorDescription: String? {
            switch self {
            case .cannotCreateExportSession: return "Could not create crop export session"
            case .exportFailed: return "Crop export failed"
            }
        }
    }
}
