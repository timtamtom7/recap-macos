import Foundation
import AVFoundation

class ExportService {
    static let shared = ExportService()

    func export(recording: Recording, to url: URL, preset: ExportPreset, progressHandler: ((Double) -> Void)? = nil) async throws {
        let asset = AVURLAsset(url: recording.filePath)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: preset.avPreset) else {
            throw ExportError.sessionCreationFailed
        }

        exportSession.outputURL = url
        exportSession.outputFileType = preset.avFileType

        if let resolution = preset.resolution {
            let videoComposition = try await createVideoComposition(for: asset, targetResolution: resolution)
            exportSession.videoComposition = videoComposition
        }

        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            progressHandler?(Double(exportSession.progress))
        }

        await exportSession.export()
        progressTimer.invalidate()

        if let error = exportSession.error {
            throw error
        }

        if exportSession.status != .completed {
            throw ExportError.exportFailed
        }
    }

    private func createVideoComposition(for asset: AVAsset, targetResolution: CGSize) async throws -> AVMutableVideoComposition {
        guard let videoTrack = try await asset.loadTracks(withMediaType: .video).first else {
            throw ExportError.noVideoTrack
        }

        let naturalSize = try await videoTrack.load(.naturalSize)
        let transform = try await videoTrack.load(.preferredTransform)

        let transformedSize = naturalSize.applying(transform)
        let sourceSize = CGSize(width: abs(transformedSize.width), height: abs(transformedSize.height))

        let scaleX = targetResolution.width / sourceSize.width
        let scaleY = targetResolution.height / sourceSize.height
        let scale = min(scaleX, scaleY)

        let scaledSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)

        let composition = AVMutableVideoComposition()
        composition.renderSize = scaledSize
        composition.frameDuration = CMTime(value: 1, timescale: 30)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: try await asset.load(.duration))

        let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack)
        layerInstruction.setTransform(transform, at: .zero)

        let scaledTransform = transform.scaledBy(x: scale, y: scale)
        layerInstruction.setTransform(scaledTransform, at: .zero)

        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]

        return composition
    }

    func getAvailableDisplays() -> [DisplayInfo] {
        var displayCount: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &displayCount)

        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetActiveDisplayList(displayCount, &displays, &displayCount)

        return displays.map { displayID in
            let bounds = CGDisplayBounds(displayID)
            let name = "Display \(displayID)"
            return DisplayInfo(id: displayID, name: name, bounds: bounds)
        }
    }

    func getAvailableWindows() -> [WindowInfo] {
        let options = CGWindowListOption(arrayLiteral: .excludeDesktopElements, .optionOnScreenOnly)
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        return windowList.compactMap { info -> WindowInfo? in
            guard let windowID = info[kCGWindowNumber as String] as? CGWindowID,
                  let ownerName = info[kCGWindowOwnerName as String] as? String,
                  let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                  let x = boundsDict["X"] as? CGFloat,
                  let y = boundsDict["Y"] as? CGFloat,
                  let width = boundsDict["Width"] as? CGFloat,
                  let height = boundsDict["Height"] as? CGFloat else {
                return nil
            }

            let name = info[kCGWindowName as String] as? String ?? ownerName

            return WindowInfo(
                id: windowID,
                name: name,
                ownerName: ownerName,
                bounds: CGRect(x: x, y: y, width: width, height: height)
            )
        }
    }
}

extension ExportPreset {
    var avPreset: String {
        switch self {
        case .highQuality:
            return AVAssetExportPresetHighestQuality
        case .standard:
            return AVAssetExportPresetHighestQuality
        case .compact:
            return AVAssetExportPresetMediumQuality
        }
    }

    var avFileType: AVFileType {
        switch self {
        case .highQuality:
            return .mov
        case .standard, .compact:
            return .mp4
        }
    }
}

enum ExportError: Error {
    case sessionCreationFailed
    case exportFailed
    case noVideoTrack
}
