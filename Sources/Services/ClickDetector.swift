import Foundation
import AppKit
import CoreGraphics

final class ClickDetector {
    static let shared = ClickDetector()
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var onClickHandler: ((CGPoint, Bool) -> Void)?

    enum ClickStyle: String, CaseIterable, Codable {
        case circle = "Circle"
        case ripple = "Ripple"
        case spotlight = "Spotlight"
        case none = "None"
    }

    struct Settings: Codable {
        var enabled: Bool = true
        var style: ClickStyle = .circle
        var size: ClickSize = .medium
        var color: CodableColor = .red
        var opacity: Double = 0.8

        enum ClickSize: String, CaseIterable, Codable {
            case small = "Small"
            case medium = "Medium"
            case large = "Large"

            var radius: CGFloat {
                switch self {
                case .small: return 12
                case .medium: return 20
                case .large: return 30
                }
            }
        }
    }

    var settings = Settings()

    func startDetecting(onClick: @escaping (CGPoint, Bool) -> Void) {
        guard eventTap == nil else { return }
        self.onClickHandler = onClick

        let eventMask: CGEventMask = (1 << CGEventType.leftMouseDown.rawValue) | (1 << CGEventType.rightMouseDown.rawValue)
        let detectorPtr = Unmanaged.passUnretained(self).toOpaque()

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, userInfo) -> Unmanaged<CGEvent>? in
                guard let userInfo = userInfo else { return Unmanaged.passRetained(event) }
                let detector = Unmanaged<ClickDetector>.fromOpaque(userInfo).takeUnretainedValue()
                let isRightClick = type == .rightMouseDown
                let location = event.location
                DispatchQueue.main.async { @MainActor in
                    detector.onClickHandler?(location, isRightClick)
                }
                return Unmanaged.passRetained(event)
            },
            userInfo: detectorPtr
        )

        guard let tap = eventTap else { return }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }

    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        eventTap = nil
        runLoopSource = nil
        onClickHandler = nil
    }

    deinit {
        stop()
    }
}
