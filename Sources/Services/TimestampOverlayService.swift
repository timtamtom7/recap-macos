import Foundation
import CoreGraphics
import CoreImage
import AppKit

final class TimestampOverlayService {
    struct Settings: Codable {
        var enabled: Bool = true
        var position: Position = .topLeft
        var format: TimestampFormat = .HHMMSSmm
        var fontSize: Int = 24
        var textColor: CodableColor = .white
        var backgroundColor: CodableColor = CodableColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        var backgroundEnabled: Bool = true

        enum Position: String, CaseIterable, Codable {
            case topLeft = "Top Left"
            case topRight = "Top Right"
            case bottomLeft = "Bottom Left"
            case bottomRight = "Bottom Right"
        }

        enum TimestampFormat: String, CaseIterable, Codable {
            case HHMMSS = "HH:MM:SS"
            case HHMMSSmm = "HH:MM:SS.mm"
            case HHMMSSampm = "HH:MM:SS AM/PM"
            case custom = "Custom"

            var displayFormat: String { rawValue }
        }
    }

    var settings = Settings()

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    func timestampString(for elapsedSeconds: TimeInterval) -> String {
        let totalMilliseconds = Int(elapsedSeconds * 100)
        let minutes = totalMilliseconds / 60000
        let seconds = (totalMilliseconds % 60000) / 1000
        let milliseconds = totalMilliseconds % 1000

        switch settings.format {
        case .HHMMSS:
            return String(format: "%02d:%02d:%02d", minutes / 60, minutes % 60, seconds)
        case .HHMMSSmm:
            return String(format: "%02d:%02d:%02d.%02d", minutes / 60, minutes % 60, seconds, milliseconds / 10)
        case .HHMMSSampm:
            let hour = minutes / 60
            let min = minutes % 60
            let sec = seconds
            let ampm = hour >= 12 ? "PM" : "AM"
            let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
            return String(format: "%02d:%02d:%02d %@", displayHour, min, sec, ampm)
        case .custom:
            return String(format: "%02d:%02d:%02d", minutes / 60, minutes % 60, seconds)
        }
    }

    func positionForTimestamp(in rect: CGRect, size: CGSize) -> CGPoint {
        let padding: CGFloat = 16
        switch settings.position {
        case .topLeft:
            return CGPoint(x: padding, y: rect.height - size.height - padding)
        case .topRight:
            return CGPoint(x: rect.width - size.width - padding, y: rect.height - size.height - padding)
        case .bottomLeft:
            return CGPoint(x: padding, y: padding)
        case .bottomRight:
            return CGPoint(x: rect.width - size.width - padding, y: padding)
        }
    }

    func renderTimestamp(at point: CGPoint, elapsed: TimeInterval, in context: CGContext, frameSize: CGSize) {
        let text = timestampString(for: elapsed)
        let font = NSFont.systemFont(ofSize: CGFloat(settings.fontSize), weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: settings.textColor.color
        ]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()

        let bgRect = CGRect(
            x: point.x - 8,
            y: point.y - 4,
            width: textSize.width + 16,
            height: textSize.height + 8
        )

        if settings.backgroundEnabled {
            context.saveGState()
            context.setFillColor(settings.backgroundColor.color.withAlphaComponent(settings.backgroundColor.alpha).cgColor)
            let path = CGMutablePath()
            let r = CGRect(x: bgRect.origin.x + 6, y: bgRect.origin.y, width: bgRect.width - 12, height: bgRect.height)
            path.addRoundedRect(in: bgRect, cornerWidth: 6, cornerHeight: 6)
            context.addPath(path)
            context.fillPath()
            context.restoreGState()
        }

        NSGraphicsContext.saveGraphicsState()
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = nsContext
        attributedString.draw(at: point)
        NSGraphicsContext.restoreGraphicsState()
    }
}
