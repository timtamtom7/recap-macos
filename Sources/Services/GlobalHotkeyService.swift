import Foundation
import AppKit
import Carbon

final class GlobalHotkeyService: ObservableObject {
    static let shared = GlobalHotkeyService()

    @Published var isEnabled = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    struct Hotkey: Identifiable {
        let id: String
        let keyCode: UInt16
        let modifiers: UInt32
        var action: () -> Void
    }

    private var hotkeys: [Hotkey] = []

    private init() {}

    func register(hotkey: Hotkey) {
        hotkeys.removeAll { $0.id == hotkey.id }
        hotkeys.append(hotkey)
    }

    func unregister(id: String) {
        hotkeys.removeAll { $0.id == id }
    }

    func start() {
        guard eventTap == nil else { return }

        let eventMask: CGEventMask = (1 << CGEventType.keyDown.rawValue)

        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: eventMask,
            callback: { (proxy, type, event, userInfo) -> Unmanaged<CGEvent>? in
                return Unmanaged.passRetained(event)
            },
            userInfo: nil
        )

        guard let tap = eventTap else { return }

        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        isEnabled = true
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
        isEnabled = false
    }

    static let MOD_CMD: UInt32 = 1 << 0
    static let MOD_SHIFT: UInt32 = 1 << 1
    static let MOD_CONTROL: UInt32 = 1 << 2
    static let MOD_OPTION: UInt32 = 1 << 3
}
