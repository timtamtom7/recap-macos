import Foundation

enum RecordingState: Equatable {
    case idle
    case recording
    case paused
    case stopping
    case stopped

    var displayText: String {
        switch self {
        case .idle: return "Ready"
        case .recording: return "Recording"
        case .paused: return "Paused"
        case .stopping: return "Stopping..."
        case .stopped: return "Stopped"
        }
    }

    var isActive: Bool {
        switch self {
        case .recording, .paused: return true
        default: return false
        }
    }
}

enum ExportPreset: String, CaseIterable, Identifiable {
    case highQuality  // MOV ProRes 422
    case standard     // MP4 H264
    case compact      // MP4 H264 720p

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .highQuality: return "High Quality (MOV, ProRes)"
        case .standard: return "Standard (MP4, H.264)"
        case .compact: return "Compact (MP4, 720p)"
        }
    }

    var fileExtension: String {
        switch self {
        case .highQuality: return "mov"
        case .standard, .compact: return "mp4"
        }
    }

    var codec: String {
        switch self {
        case .highQuality: return "prores422"
        case .standard, .compact: return "h264"
        }
    }
}
