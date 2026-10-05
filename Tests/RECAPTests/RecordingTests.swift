import XCTest
@testable import RECAP

final class RecordingTests: XCTestCase {
    func testFormattedDurationHours() {
        let recording = Recording(
            id: UUID(),
            title: "Test",
            filePath: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 3661,
            createdAt: Date(),
            thumbnailPath: nil,
            fileSize: 1024,
            displayName: nil,
            includesAudio: true,
            codec: "prores422",
            resolution: CGSize(width: 1920, height: 1080)
        )
        XCTAssertEqual(recording.formattedDuration, "01:01:01")
    }

    func testFormattedDurationMinutes() {
        let recording = Recording(
            id: UUID(),
            title: "Test",
            filePath: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 125,
            createdAt: Date(),
            thumbnailPath: nil,
            fileSize: 1024,
            displayName: nil,
            includesAudio: true,
            codec: "prores422",
            resolution: CGSize(width: 1920, height: 1080)
        )
        XCTAssertEqual(recording.formattedDuration, "02:05")
    }

    func testFormattedDurationZero() {
        let recording = Recording(
            id: UUID(),
            title: "Test",
            filePath: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 0,
            createdAt: Date(),
            thumbnailPath: nil,
            fileSize: 0,
            displayName: nil,
            includesAudio: true,
            codec: "prores422",
            resolution: CGSize(width: 1920, height: 1080)
        )
        XCTAssertEqual(recording.formattedDuration, "00:00")
    }

    func testFormattedFileSize() {
        let recording = Recording(
            id: UUID(),
            title: "Test",
            filePath: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 100,
            createdAt: Date(),
            thumbnailPath: nil,
            fileSize: 1_500_000_000,
            displayName: nil,
            includesAudio: true,
            codec: "prores422",
            resolution: CGSize(width: 1920, height: 1080)
        )
        let formatted = recording.formattedFileSize
        XCTAssertTrue(formatted.contains("GB") || formatted.contains("gigabytes"))
    }

    func testFormattedDate() {
        let date = Date(timeIntervalSince1970: 1700000000)
        let recording = Recording(
            id: UUID(),
            title: "Test",
            filePath: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 100,
            createdAt: date,
            thumbnailPath: nil,
            fileSize: 1024,
            displayName: nil,
            includesAudio: true,
            codec: "prores422",
            resolution: CGSize(width: 1920, height: 1080)
        )
        let formatted = recording.formattedDate
        XCTAssertFalse(formatted.isEmpty)
    }

    func testRecordingCodableRoundTrip() throws {
        let original = Recording(
            id: UUID(),
            title: "Test Recording",
            filePath: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 3661,
            createdAt: Date(),
            thumbnailPath: URL(fileURLWithPath: "/tmp/thumb.jpg"),
            fileSize: 1_500_000_000,
            displayName: "Main Display",
            includesAudio: true,
            codec: "prores422",
            resolution: CGSize(width: 1920, height: 1080)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(original)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Recording.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.title, original.title)
        XCTAssertEqual(decoded.duration, original.duration)
        XCTAssertEqual(decoded.fileSize, original.fileSize)
        XCTAssertEqual(decoded.includesAudio, original.includesAudio)
        XCTAssertEqual(decoded.codec, original.codec)
        XCTAssertEqual(decoded.resolution, original.resolution)
    }
}
