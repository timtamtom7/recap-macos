import Foundation

struct GIFExportOptions: Codable {
    var resolution: Resolution = .original
    var frameRate: FrameRate = .fps15
    var quality: Quality = .medium
    var loopCount: LoopCount = .infinite

    enum Resolution: String, CaseIterable, Codable {
        case original = "Original"
        case p720 = "720p"
        case p480 = "480p"
        case p360 = "360p"

        var size: CGSize? {
            switch self {
            case .original: return nil
            case .p720: return CGSize(width: 1280, height: 720)
            case .p480: return CGSize(width: 854, height: 480)
            case .p360: return CGSize(width: 640, height: 360)
            }
        }
    }

    enum FrameRate: Int, CaseIterable, Codable {
        case fps10 = 10
        case fps15 = 15
        case fps20 = 20

        var displayName: String {
            "\(rawValue) fps"
        }
    }

    enum Quality: String, CaseIterable, Codable {
        case low = "Low (256 colors)"
        case medium = "Medium (128 colors)"
        case high = "High (64 colors)"

        var colorCount: Int {
            switch self {
            case .low: return 256
            case .medium: return 128
            case .high: return 64
            }
        }
    }

    enum LoopCount: String, CaseIterable, Codable {
        case infinite = "Infinite"
        case once = "1x"
        case thrice = "3x"

        var count: Int {
            switch self {
            case .infinite: return 0
            case .once: return 1
            case .thrice: return 3
            }
        }
    }
}

struct TrimRange: Codable {
    var startTime: TimeInterval
    var endTime: TimeInterval

    var duration: TimeInterval {
        endTime - startTime
    }

    init(startTime: TimeInterval = 0, endTime: TimeInterval) {
        self.startTime = startTime
        self.endTime = endTime
    }
}
