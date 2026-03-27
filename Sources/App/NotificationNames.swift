import Foundation

extension Notification.Name {
    // Recording
    static let recordingStateChanged = Notification.Name("recordingStateChanged")
    static let showDisplayPicker = Notification.Name("showDisplayPicker")
    static let startRecording = Notification.Name("startRecording")
    static let stopRecording = Notification.Name("stopRecording")
    static let togglePause = Notification.Name("togglePause")
    static let stopRecordingDueToDiskSpace = Notification.Name("stopRecordingDueToDiskSpace")

    // Navigation
    static let openSettings = Notification.Name("openSettings")
    static let openLibrary = Notification.Name("openLibrary")

    // Scheduled/Automation
    static let startScheduledRecording = Notification.Name("startScheduledRecording")
    static let systemDidWake = Notification.Name("systemDidWake")

    // Export
    static let exportRecording = Notification.Name("exportRecording")
}