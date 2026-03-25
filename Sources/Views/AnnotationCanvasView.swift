import SwiftUI
import AppKit

struct AnnotationCanvasView: View {
    @ObservedObject var engine: AnnotationEngine
    let currentTime: TimeInterval
    let canvasSize: CGSize

    var body: some View {
        Canvas { context, size in
            // Draw all completed layers that are active at current time
            guard let project = engine.currentProject else { return }

            for layer in project.layers where currentTime >= layer.startTime && currentTime <= layer.endTime {
                drawLayer(layer, in: &context)
            }

            // Draw current layer being drawn
            if let currentLayer = engine.currentDrawingLayer() {
                drawLayer(currentLayer, in: &context)
            }
        }
        .frame(width: canvasSize.width, height: canvasSize.height)
        .allowsHitTesting(false)
    }

    private func drawLayer(_ layer: AnnotationLayer, in context: inout GraphicsContext) {
        switch layer.tool {
        case .pen, .highlighter:
            drawPenStroke(layer, in: &context)
        case .arrow:
            drawArrow(layer, in: &context)
        case .rectangle:
            drawRectangle(layer, in: &context)
        case .ellipse:
            drawEllipse(layer, in: &context)
        case .text:
            drawText(layer, in: &context)
        case .number:
            drawNumber(layer, in: &context)
        }
    }

    private func drawPenStroke(_ layer: AnnotationLayer, in context: inout GraphicsContext) {
        guard layer.points.count > 1 else { return }

        var path = Path()
        path.move(to: layer.points[0])
        for point in layer.points.dropFirst() {
            path.addLine(to: point)
        }

        let color = Color(nsColor: layer.color.color)
        context.stroke(path, with: .color(color), lineWidth: layer.strokeWidth)
    }

    private func drawArrow(_ layer: AnnotationLayer, in context: inout GraphicsContext) {
        guard layer.points.count >= 2 else { return }
        let start = layer.points.first!
        let end = layer.points.last!

        var path = Path()
        path.move(to: start)
        path.addLine(to: end)

        // Arrow head
        let angle = atan2(end.y - start.y, end.x - start.x)
        let headLength: CGFloat = 15
        let headAngle: CGFloat = .pi / 6

        let p1 = CGPoint(x: end.x - headLength * cos(angle - headAngle), y: end.y - headLength * sin(angle - headAngle))
        let p2 = CGPoint(x: end.x - headLength * cos(angle + headAngle), y: end.y - headLength * sin(angle + headAngle))

        path.move(to: end)
        path.addLine(to: p1)
        path.move(to: end)
        path.addLine(to: p2)

        let color = Color(nsColor: layer.color.color)
        context.stroke(path, with: .color(color), lineWidth: layer.strokeWidth)
    }

    private func drawRectangle(_ layer: AnnotationLayer, in context: inout GraphicsContext) {
        guard let rect = layer.rect else { return }
        let rectPath = Path(rect)
        let color = Color(nsColor: layer.color.color)
        if layer.isFilled {
            context.fill(rectPath, with: .color(color.opacity(Double(layer.color.alpha))))
        } else {
            context.stroke(rectPath, with: .color(color), lineWidth: layer.strokeWidth)
        }
    }

    private func drawEllipse(_ layer: AnnotationLayer, in context: inout GraphicsContext) {
        guard let rect = layer.rect else { return }
        let ellipsePath = Path(ellipseIn: rect)
        let color = Color(nsColor: layer.color.color)
        if layer.isFilled {
            context.fill(ellipsePath, with: .color(color.opacity(Double(layer.color.alpha))))
        } else {
            context.stroke(ellipsePath, with: .color(color), lineWidth: layer.strokeWidth)
        }
    }

    private func drawText(_ layer: AnnotationLayer, in context: inout GraphicsContext) {
        guard let text = layer.text, let point = layer.points.first else { return }
        let color = Color(nsColor: layer.color.color)
        context.draw(Text(text).foregroundColor(color).font(.system(size: layer.strokeWidth * 4)), at: point)
    }

    private func drawNumber(_ layer: AnnotationLayer, in context: inout GraphicsContext) {
        guard let text = layer.text, let point = layer.points.first else { return }
        let color = Color(nsColor: layer.color.color)
        context.draw(Text(text).foregroundColor(color).font(.system(size: layer.strokeWidth * 4, weight: .bold)), at: point)
    }
}
