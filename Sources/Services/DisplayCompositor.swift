import Foundation
import AVFoundation
import CoreImage

final class DisplayCompositor {
    enum Layout {
        case single
        case sideBySide
        case pip(position: PIPPosition)
        case grid(rows: Int, cols: Int)

        enum PIPPosition {
            case topLeft, topRight, bottomLeft, bottomRight
        }
    }

    struct InputStream {
        let displayId: CGDirectDisplayID
        let input: AVCaptureScreenInput
        let contentRect: CGRect
    }

    func composite(streams: [InputStream], layout: Layout, outputSize: CGSize) -> AVMutableVideoComposition {
        let composition = AVMutableVideoComposition()
        composition.renderSize = outputSize
        composition.frameDuration = CMTime(value: 1, timescale: 60)

        let instruction = AVMutableVideoCompositionInstruction()
        instruction.timeRange = CMTimeRange(start: .zero, duration: .positiveInfinity)

        let layerInstruction = AVMutableVideoCompositionLayerInstruction()

        switch layout {
        case .single:
            if let stream = streams.first {
                let transform = CGAffineTransform(scaleX: outputSize.width / stream.contentRect.width,
                                                  y: outputSize.height / stream.contentRect.height)
                layerInstruction.setTransform(transform, at: .zero)
            }

        case .sideBySide:
            var xOffset: CGFloat = 0
            for stream in streams {
                // Partial transform for each stream
                xOffset += stream.contentRect.width
            }

        case .pip(let position):
            if let main = streams.first, streams.count > 1 {
                let mainTransform = CGAffineTransform(scaleX: outputSize.width / main.contentRect.width,
                                                      y: outputSize.height / main.contentRect.height)
                // Main covers full output

                let pip = streams[1]
                let pipWidth = outputSize.width * 0.25
                let pipHeight = pipWidth * (pip.contentRect.height / pip.contentRect.width)
                let pipX: CGFloat
                let pipY: CGFloat

                switch position {
                case .topLeft: pipX = 20; pipY = outputSize.height - pipHeight - 20
                case .topRight: pipX = outputSize.width - pipWidth - 20; pipY = outputSize.height - pipHeight - 20
                case .bottomLeft: pipX = 20; pipY = 20
                case .bottomRight: pipX = outputSize.width - pipWidth - 20; pipY = 20
                }

                let pipTransform = CGAffineTransform(scaleX: pipWidth / pip.contentRect.width,
                                                    y: pipHeight / pip.contentRect.height)
                    .translatedBy(x: pipX, y: pipY)
                layerInstruction.setTransform(mainTransform, at: .zero)
                // Note: would need separate layer instruction per stream for multiple transforms
            }

        case .grid(let rows, let cols):
            let cellWidth = outputSize.width / CGFloat(cols)
            let cellHeight = outputSize.height / CGFloat(rows)
            for (index, stream) in streams.enumerated() {
                let col = index % cols
                let row = index / cols
                let x = CGFloat(col) * cellWidth
                let y = CGFloat(row) * cellHeight
                let transform = CGAffineTransform(scaleX: cellWidth / stream.contentRect.width,
                                                  y: cellHeight / stream.contentRect.height)
                    .translatedBy(x: x, y: y)
                if index == 0 {
                    layerInstruction.setTransform(transform, at: .zero)
                }
            }
        }

        instruction.layerInstructions = [layerInstruction]
        composition.instructions = [instruction]

        return composition
    }
}
