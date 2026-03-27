import Foundation
import AVFoundation
import AppKit
import os.log

class ThumbnailGenerator {
    static let shared = ThumbnailGenerator()

    private var ongoingGenerations: [URL: Task<URL?, Never>] = [:]
    private let lock = NSLock()

    private init() {}

    func generateThumbnail(for videoURL: URL, at time: CMTime = .zero) async -> URL? {
        if let existingTask = getOngoingTask(for: videoURL) {
            return await existingTask.value
        }

        let task = Task<URL?, Never> {
            return await generateThumbnailInternal(for: videoURL, at: time)
        }

        setOngoingTask(task, for: videoURL)
        let result = await task.value
        removeOngoingTask(for: videoURL)
        return result
    }

    private func getOngoingTask(for videoURL: URL) -> Task<URL?, Never>? {
        lock.lock()
        defer { lock.unlock() }
        return ongoingGenerations[videoURL]
    }

    private func setOngoingTask(_ task: Task<URL?, Never>, for videoURL: URL) {
        lock.lock()
        defer { lock.unlock() }
        ongoingGenerations[videoURL] = task
    }

    private func removeOngoingTask(for videoURL: URL) {
        lock.lock()
        defer { lock.unlock() }
        ongoingGenerations.removeValue(forKey: videoURL)
    }

    private func generateThumbnailInternal(for videoURL: URL, at time: CMTime) async -> URL? {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 320, height: 180)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero

        if Task.isCancelled { return nil }

        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)

            if Task.isCancelled { return nil }

            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

            let thumbnailURL = videoURL.deletingPathExtension().appendingPathExtension("jpg")
            if let tiffData = nsImage.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: tiffData),
               let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) {
                try jpegData.write(to: thumbnailURL)
                return thumbnailURL
            }
        } catch {
            Log.thumbnail.error("Thumbnail generation failed: \(error.localizedDescription)")
        }

        return nil
    }

    func cancelGeneration(for videoURL: URL) {
        lock.lock()
        defer { lock.unlock() }
        ongoingGenerations[videoURL]?.cancel()
        ongoingGenerations.removeValue(forKey: videoURL)
    }
}
