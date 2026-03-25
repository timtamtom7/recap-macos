import SwiftUI

struct CropOverlayView: View {
    @Binding var cropRegion: CropService.CropRegion
    let videoSize: CGSize

    var body: some View {
        GeometryReader { geometry in
            let size = geometry.size
            let cropX = cropRegion.x * size.width
            let cropY = cropRegion.y * size.height
            let cropW = cropRegion.width * size.width
            let cropH = cropRegion.height * size.height

            ZStack {
                // Dark overlay
                Color.black.opacity(0.5)
                    .mask(
                        Rectangle()
                            .overlay(
                                Rectangle()
                                    .frame(width: cropW, height: cropH)
                                    .position(x: cropX + cropW / 2, y: cropY + cropH / 2)
                                    .blendMode(.destinationOut)
                            )
                    )
                    .compositingGroup()

                // Crop border
                Rectangle()
                    .stroke(Color.white, lineWidth: 1)
                    .frame(width: cropW, height: cropH)
                    .position(x: cropX + cropW / 2, y: cropY + cropH / 2)

                // Corner handles
                cornerHandle(at: CGPoint(x: cropX, y: cropY), corner: .topLeft, in: size)
                cornerHandle(at: CGPoint(x: cropX + cropW, y: cropY), corner: .topRight, in: size)
                cornerHandle(at: CGPoint(x: cropX, y: cropY + cropH), corner: .bottomLeft, in: size)
                cornerHandle(at: CGPoint(x: cropX + cropW, y: cropY + cropH), corner: .bottomRight, in: size)

                // Rule of thirds grid
                cropGrid(cropRect: CGRect(x: cropX, y: cropY, width: cropW, height: cropH))
            }
        }
    }

    @ViewBuilder
    private func cornerHandle(at point: CGPoint, corner: Corner, in size: CGSize) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 12, height: 12)
            .position(point)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        handleDrag(corner: corner, translation: value.translation, size: size)
                    }
            )
    }

    private func cropGrid(cropRect: CGRect) -> some View {
        ZStack {
            // Vertical thirds
            Path { path in
                path.move(to: CGPoint(x: cropRect.minX + cropRect.width / 3, y: cropRect.minY))
                path.addLine(to: CGPoint(x: cropRect.minX + cropRect.width / 3, y: cropRect.maxY))
                path.move(to: CGPoint(x: cropRect.minX + 2 * cropRect.width / 3, y: cropRect.minY))
                path.addLine(to: CGPoint(x: cropRect.minX + 2 * cropRect.width / 3, y: cropRect.maxY))
            }
            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)

            // Horizontal thirds
            Path { path in
                path.move(to: CGPoint(x: cropRect.minX, y: cropRect.minY + cropRect.height / 3))
                path.addLine(to: CGPoint(x: cropRect.maxX, y: cropRect.minY + cropRect.height / 3))
                path.move(to: CGPoint(x: cropRect.minX, y: cropRect.minY + 2 * cropRect.height / 3))
                path.addLine(to: CGPoint(x: cropRect.maxX, y: cropRect.minY + 2 * cropRect.height / 3))
            }
            .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
        }
    }

    enum Corner {
        case topLeft, topRight, bottomLeft, bottomRight
    }

    private func handleDrag(corner: Corner, translation: CGSize, size: CGSize) {
        let dx = translation.width / size.width
        let dy = translation.height / size.height

        switch corner {
        case .topLeft:
            let newX = max(0, min(cropRegion.x + dx, cropRegion.x + cropRegion.width - 0.05))
            let newY = max(0, min(cropRegion.y + dy, cropRegion.y + cropRegion.height - 0.05))
            cropRegion.width = max(0.05, cropRegion.x + cropRegion.width - newX)
            cropRegion.height = max(0.05, cropRegion.y + cropRegion.height - newY)
            cropRegion.x = newX
            cropRegion.y = newY
        case .topRight:
            cropRegion.width = max(0.05, min(cropRegion.width + dx, 1 - cropRegion.x))
            let newY = max(0, min(cropRegion.y + dy, cropRegion.y + cropRegion.height - 0.05))
            cropRegion.height = max(0.05, cropRegion.y + cropRegion.height - newY)
            cropRegion.y = newY
        case .bottomLeft:
            let newX = max(0, min(cropRegion.x + dx, cropRegion.x + cropRegion.width - 0.05))
            cropRegion.width = max(0.05, cropRegion.x + cropRegion.width - newX)
            cropRegion.x = newX
            cropRegion.height = max(0.05, min(cropRegion.height + dy, 1 - cropRegion.y))
        case .bottomRight:
            cropRegion.width = max(0.05, min(cropRegion.width + dx, 1 - cropRegion.x))
            cropRegion.height = max(0.05, min(cropRegion.height + dy, 1 - cropRegion.y))
        }
    }
}
