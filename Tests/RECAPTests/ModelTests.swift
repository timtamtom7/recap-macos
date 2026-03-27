import XCTest
@testable import RECAP

final class RecordingStateTests: XCTestCase {
    func testRecordingStateDisplayNames() {
        XCTAssertEqual(RecordingState.idle.displayName, "Ready")
        XCTAssertEqual(RecordingState.recording.displayName, "Recording")
        XCTAssertEqual(RecordingState.paused.displayName, "Paused")
        XCTAssertEqual(RecordingState.stopping.displayName, "Stopping...")
        XCTAssertEqual(RecordingState.stopped.displayName, "Stopped")
    }

    func testRecordingStateIconNames() {
        XCTAssertEqual(RecordingState.idle.iconName, "record.circle")
        XCTAssertEqual(RecordingState.recording.iconName, "record.circle.fill")
        XCTAssertEqual(RecordingState.paused.iconName, "pause.circle.fill")
        XCTAssertEqual(RecordingState.stopping.iconName, "stop.circle.fill")
        XCTAssertEqual(RecordingState.stopped.iconName, "stop.circle")
    }
}

final class ExportPresetTests: XCTestCase {
    func testHighQualityPreset() {
        let preset = ExportPreset.highQuality
        XCTAssertEqual(preset.codec, "prores422")
        XCTAssertEqual(preset.fileExtension, "mov")
        XCTAssertNil(preset.resolution)
        XCTAssertEqual(preset.frameRate, 60)
        XCTAssertTrue(preset.description.contains("ProRes"))
    }

    func testStandardPreset() {
        let preset = ExportPreset.standard
        XCTAssertEqual(preset.codec, "h264")
        XCTAssertEqual(preset.fileExtension, "mp4")
        XCTAssertEqual(preset.resolution, CGSize(width: 1920, height: 1080))
        XCTAssertEqual(preset.frameRate, 30)
        XCTAssertTrue(preset.description.contains("1080p"))
    }

    func testCompactPreset() {
        let preset = ExportPreset.compact
        XCTAssertEqual(preset.codec, "h264")
        XCTAssertEqual(preset.fileExtension, "mp4")
        XCTAssertEqual(preset.resolution, CGSize(width: 1280, height: 720))
        XCTAssertEqual(preset.frameRate, 30)
        XCTAssertTrue(preset.description.contains("720p"))
    }

    func testExportPresetCaseIterable() {
        XCTAssertEqual(ExportPreset.allCases.count, 3)
    }
}
