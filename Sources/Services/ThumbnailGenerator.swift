import Foundation
import AVFoundation
import AppKit

class ThumbnailGenerator {
    static let shared = ThumbnailGenerator()

    private init() {}

    func generateThumbnail(for videoURL: URL, at time: CMTime = .zero) async -> URL? {
        let asset = AVURLAsset(url: videoURL)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 320, height: 180)

        do {
            let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
            let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

            let thumbnailURL = videoURL.deletingPathExtension().appendingPathExtension("jpg")
            if let tiffData = nsImage.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: tiffData),
               let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) {
                try jpegData.write(to: thumbnailURL)
                return thumbnailURL
            }
        } catch {
            print("Thumbnail generation failed: \(error)")
        }

        return nil
    }
}
