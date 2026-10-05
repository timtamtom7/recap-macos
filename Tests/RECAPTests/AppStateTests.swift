import XCTest
@testable import RECAP

@MainActor
final class AppStateTests: XCTestCase {
    func testFormattedElapsedTimeHours() {
        AppState.shared.elapsedTime = 3661
        XCTAssertEqual(AppState.shared.formattedElapsedTime, "01:01:01")
    }

    func testFormattedElapsedTimeMinutes() {
        AppState.shared.elapsedTime = 125
        XCTAssertEqual(AppState.shared.formattedElapsedTime, "02:05")
    }

    func testFormattedElapsedTimeZero() {
        AppState.shared.elapsedTime = 0
        XCTAssertEqual(AppState.shared.formattedElapsedTime, "00:00")
    }

    func testIsRecordingWhenRecording() {
        AppState.shared.recordingState = .recording
        XCTAssertTrue(AppState.shared.isRecording)
    }

    func testIsRecordingWhenPaused() {
        AppState.shared.recordingState = .paused
        XCTAssertTrue(AppState.shared.isRecording)
    }

    func testIsNotRecordingWhenIdle() {
        AppState.shared.recordingState = .idle
        XCTAssertFalse(AppState.shared.isRecording)
    }

    func testIsNotRecordingWhenStopped() {
        AppState.shared.recordingState = .stopped
        XCTAssertFalse(AppState.shared.isRecording)
    }
}
