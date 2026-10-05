import Foundation
import SwiftUI

enum AnnotationTool: String, CaseIterable, Codable {
    case pen = "Pen"
    case highlighter = "Highlighter"
    case arrow = "Arrow"
    case rectangle = "Rectangle"
    case ellipse = "Ellipse"
    case text = "Text"
    case number = "Number"

    var icon: String {
        switch self {
        case .pen: return "pencil.tip"
        case .highlighter: return "highlighter"
        case .arrow: return "arrow.right"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .text: return "textformat"
        case .number: return "number"
        }
    }
}

struct AnnotationLayer: Identifiable, Codable {
    let id: UUID
    let tool: AnnotationTool
    var color: CodableColor
    var strokeWidth: CGFloat
    var points: [CGPoint]
    var rect: CGRect?
    var text: String?
    var startTime: TimeInterval
    var endTime: TimeInterval
    var isFilled: Bool

    init(id: UUID = UUID(), tool: AnnotationTool, color: CodableColor, strokeWidth: CGFloat, points: [CGPoint] = [], rect: CGRect? = nil, text: String? = nil, startTime: TimeInterval = 0, endTime: TimeInterval = .infinity, isFilled: Bool = false) {
        self.id = id
        self.tool = tool
        self.color = color
        self.strokeWidth = strokeWidth
        self.points = points
        self.rect = rect
        self.text = text
        self.startTime = startTime
        self.endTime = endTime
        self.isFilled = isFilled
    }
}

struct AnnotationProject: Identifiable, Codable {
    let id: UUID
    let recordingId: UUID
    var layers: [AnnotationLayer]
    var duration: TimeInterval

    init(id: UUID = UUID(), recordingId: UUID, layers: [AnnotationLayer] = [], duration: TimeInterval) {
        self.id = id
        self.recordingId = recordingId
        self.layers = layers
        self.duration = duration
    }
}

struct CodableColor: Codable, Equatable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    init(color: NSColor) {
        let c = color.usingColorSpace(.deviceRGB) ?? color
        self.red = c.redComponent
        self.green = c.greenComponent
        self.blue = c.blueComponent
        self.alpha = c.alphaComponent
    }

    var color: NSColor {
        NSColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    static let red = CodableColor(red: 1, green: 0, blue: 0)
    static let blue = CodableColor(red: 0, green: 0.47, blue: 1)
    static let green = CodableColor(red: 0.3, green: 0.8, blue: 0.3)
    static let yellow = CodableColor(red: 1, green: 0.8, blue: 0)
    static let white = CodableColor(red: 1, green: 1, blue: 1)
    static let black = CodableColor(red: 0, green: 0, blue: 0)

    static let presets: [CodableColor] = [.red, .blue, .green, .yellow, .white, .black,
        CodableColor(red: 1, green: 0.4, blue: 0.8),
        CodableColor(red: 0.6, green: 0.4, blue: 1)
    ]
}
