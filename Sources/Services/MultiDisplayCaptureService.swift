import Foundation
import AVFoundation
import AppKit

final class MultiDisplayCaptureService: ObservableObject {
    @Published var availableDisplays: [DisplayInfo] = []
    @Published var selectedDisplays: Set<CGDirectDisplayID> = []
    @Published var compositeLayout: CompositeLayout = .single

    enum CompositeLayout: String, CaseIterable, Codable {
        case single = "Single"
        case sideBySide = "Side by Side"
        case pip = "Picture in Picture"
        case grid2x1 = "Grid (2)"
        case grid2x2 = "Grid (4)"
    }

    init() {
        refreshDisplays()
    }

    func refreshDisplays() {
        var displays: [DisplayInfo] = []
        var displayCount: UInt32 = 0

        CGGetActiveDisplayList(0, nil, &displayCount)

        var activeDisplays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetActiveDisplayList(displayCount, &activeDisplays, &displayCount)

        for displayId in activeDisplays {
            let isMain = CGDisplayIsMain(displayId) != 0
            let bounds = CGDisplayBounds(displayId)
            let name = isMain ? "Main Display" : "Display \(displays.count + 1)"

            displays.append(DisplayInfo(
                id: displayId,
                name: name,
                bounds: bounds
            ))
        }

        DispatchQueue.main.async {
            self.availableDisplays = displays
        }
    }

    func captureSession(for display: DisplayInfo) -> AVCaptureScreenInput? {
        guard let input = AVCaptureScreenInput(displayID: display.id) else { return nil }
        input.minFrameDuration = CMTime(value: 1, timescale: CMTimeScale(Configuration.defaultFrameRate * 2))
        return input
    }

    func selectDisplay(_ display: DisplayInfo) {
        selectedDisplays.insert(display.id)
    }

    func deselectDisplay(_ display: DisplayInfo) {
        selectedDisplays.remove(display.id)
    }

    func outputSize(for layout: CompositeLayout) -> CGSize {
        let selected = availableDisplays.filter { selectedDisplays.contains($0.id) }
        let totalWidth = selected.reduce(0.0) { $0 + $1.resolution.width }
        let maxHeight = selected.map { $0.resolution.height }.max() ?? 0

        switch layout {
        case .single:
            return selected.first?.resolution ?? .zero
        case .sideBySide:
            return CGSize(width: totalWidth, height: maxHeight)
        case .pip:
            return CGSize(width: 1920, height: 1080)
        case .grid2x1:
            return CGSize(width: totalWidth, height: maxHeight * 2)
        case .grid2x2:
            let halfWidth = totalWidth / 2
            return CGSize(width: totalWidth, height: maxHeight * 2)
        }
    }
}
