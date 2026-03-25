import Foundation
import SwiftUI

enum RecordingState: String {
    case idle
    case recording
    case paused
    case stopping
    case stopped

    var displayName: String {
        switch self {
        case .idle: return "Ready"
        case .recording: return "Recording"
        case .paused: return "Paused"
        case .stopping: return "Stopping..."
        case .stopped: return "Stopped"
        }
    }

    var iconName: String {
        switch self {
        case .idle: return "record.circle"
        case .recording: return "record.circle.fill"
        case .paused: return "pause.circle.fill"
        case .stopping: return "stop.circle.fill"
        case .stopped: return "stop.circle"
        }
    }

    var iconColor: Color {
        switch self {
        case .idle: return .gray
        case .recording: return .red
        case .paused: return .orange
        case .stopping: return .orange
        case .stopped: return .gray
        }
    }
}

enum ExportPreset: String, CaseIterable, Identifiable {
    case highQuality = "High Quality"
    case standard = "Standard"
    case compact = "Compact"

    var id: String { rawValue }

    var codec: String {
        switch self {
        case .highQuality: return "prores422"
        case .standard, .compact: return "h264"
        }
    }

    var fileExtension: String {
        switch self {
        case .highQuality: return "mov"
        case .standard, .compact: return "mp4"
        }
    }

    var resolution: CGSize? {
        switch self {
        case .highQuality: return nil
        case .standard: return CGSize(width: 1920, height: 1080)
        case .compact: return CGSize(width: 1280, height: 720)
        }
    }

    var frameRate: Int {
        switch self {
        case .highQuality: return 60
        case .standard, .compact: return 30
        }
    }

    var description: String {
        switch self {
        case .highQuality: return "MOV ProRes 422, Native Resolution, 60fps"
        case .standard: return "MP4 H.264, 1080p, 30fps"
        case .compact: return "MP4 H.264, 720p, 30fps, 5Mbps"
        }
    }
}

enum CaptureMode: String, CaseIterable {
    case display = "Display"
    case window = "Window"
}
