import Foundation
import AVFoundation

final class TrimService {
    func trim(recording: Recording, range: TrimRange, progress: @escaping (Double) -> Void) async throws -> Recording {
        let asset = AVAsset(url: recording.filePath)

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("mp4")

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            throw TrimError.cannotCreateExportSession
        }

        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mp4

        let startCMTime = CMTime(seconds: range.startTime, preferredTimescale: 600)
        let endCMTime = CMTime(seconds: range.endTime, preferredTimescale: 600)
        exportSession.timeRange = CMTimeRange(start: startCMTime, end: endCMTime)

        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            progress(Double(exportSession.progress))
        }

        await exportSession.export()
        progressTimer.invalidate()

        switch exportSession.status {
        case .completed:
            let newDuration = range.duration
            let newFileSize = (try? FileManager.default.attributesOfItem(atPath: outputURL.path)[.size] as? Int64) ?? 0

            let newRecording = Recording(
                id: UUID(),
                title: "\(recording.title) (Trimmed)",
                filePath: outputURL,
                duration: newDuration,
                createdAt: Date(),
                thumbnailPath: recording.thumbnailPath,
                fileSize: newFileSize,
                displayName: recording.displayName,
                includesAudio: recording.includesAudio,
                codec: recording.codec,
                resolution: recording.resolution
            )

            return newRecording

        case .failed:
            throw exportSession.error ?? TrimError.exportFailed

        case .cancelled:
            throw TrimError.cancelled

        default:
            throw TrimError.exportFailed
        }
    }

    func getDuration(for recording: Recording) async -> TimeInterval {
        let asset = AVAsset(url: recording.filePath)
        do {
            return try await asset.load(.duration).seconds
        } catch {
            return 0
        }
    }

    enum TrimError: LocalizedError {
        case cannotCreateExportSession
        case exportFailed
        case cancelled

        var errorDescription: String? {
            switch self {
            case .cannotCreateExportSession: return "Could not create export session"
            case .exportFailed: return "Export failed"
            case .cancelled: return "Export was cancelled"
            }
        }
    }
}
