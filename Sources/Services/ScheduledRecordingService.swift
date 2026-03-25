import Foundation
import UserNotifications

struct ScheduledRecording: Identifiable, Codable {
    let id: UUID
    var name: String
    var displayName: String?
    var scheduledTime: Date
    var duration: TimeInterval?
    var repeatInterval: RepeatInterval?
    var isEnabled: Bool

    enum RepeatInterval: Codable {
        case daily
        case weekly(weekday: Int)
        case hourly
        case customWeekdays([Int])

        func nextDate(after: Date) -> Date? {
            let calendar = Calendar.current
            switch self {
            case .daily:
                return calendar.date(byAdding: .day, value: 1, to: after)
            case .weekly(let weekday):
                return nextWeekdayFn(weekday, after: after)
            case .hourly:
                return calendar.date(byAdding: .hour, value: 1, to: after)
            case .customWeekdays(let weekdays):
                return nextCustomWeekdayFn(weekdays, after: after)
            }
        }

        private func nextWeekdayFn(_ weekday: Int, after: Date) -> Date? {
            let calendar = Calendar.current
            var components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: after)
            components.weekday = weekday
            return calendar.nextDate(after: after, matching: components, matchingPolicy: .nextTime)
        }

        private func nextCustomWeekdayFn(_ weekdays: [Int], after: Date) -> Date? {
            guard let foundWeekday = weekdays.sorted().first(where: { $0 > Calendar.current.component(.weekday, from: after) }) else {
                return nil
            }
            return nextWeekdayFn(foundWeekday, after: after)
        }
    }

    var nextScheduledDate: Date? {
        guard isEnabled else { return nil }
        if scheduledTime > Date() { return scheduledTime }
        if let repeatInterval = repeatInterval {
            return repeatInterval.nextDate(after: scheduledTime)
        }
        return nil
    }
}

final class ScheduledRecordingService: ObservableObject {
    static let shared = ScheduledRecordingService()

    @Published var scheduledRecordings: [ScheduledRecording] = []
    private var timers: [UUID: Timer] = [:]

    private init() {
        loadScheduledRecordings()
    }

    func addScheduledRecording(_ recording: ScheduledRecording) {
        scheduledRecordings.append(recording)
        saveScheduledRecordings()
        scheduleRecording(recording)
        scheduleNotification(for: recording)
    }

    func removeScheduledRecording(id: UUID) {
        scheduledRecordings.removeAll { $0.id == id }
        timers[id]?.invalidate()
        timers.removeValue(forKey: id)
        saveScheduledRecordings()
    }

    func updateScheduledRecording(_ recording: ScheduledRecording) {
        if let index = scheduledRecordings.firstIndex(where: { $0.id == recording.id }) {
            scheduledRecordings[index] = recording
            saveScheduledRecordings()

            timers[recording.id]?.invalidate()
            if recording.isEnabled {
                scheduleRecording(recording)
            }
        }
    }

    private func scheduleRecording(_ recording: ScheduledRecording) {
        guard let nextDate = recording.nextScheduledDate else { return }

        let timeInterval = nextDate.timeIntervalSinceNow
        guard timeInterval > 0 else { return }

        let timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.triggerRecording(recording)
        }
        timers[recording.id] = timer
    }

    private func triggerRecording(_ recording: ScheduledRecording) {
        NotificationCenter.default.post(name: .startScheduledRecording, object: nil, userInfo: ["recordingId": recording.id])

        // Reschedule if repeating
        if recording.repeatInterval != nil {
            if var updated = scheduledRecordings.first(where: { $0.id == recording.id }) {
                updated.scheduledTime = Date()
                if let next = updated.nextScheduledDate {
                    updated.scheduledTime = next
                    updateScheduledRecording(updated)
                }
            }
        }
    }

    private func scheduleNotification(for recording: ScheduledRecording) {
        guard let nextDate = recording.nextScheduledDate else { return }

        let content = UNMutableNotificationContent()
        content.title = "Recording Starting Soon"
        content.body = "\(recording.name) will start in 1 minute"
        content.sound = .default

        let triggerDate = nextDate.addingTimeInterval(-60)
        guard triggerDate > Date() else { return }

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: triggerDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: "scheduled-\(recording.id.uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func loadScheduledRecordings() {
        guard let data = UserDefaults.standard.data(forKey: "scheduledRecordings"),
              let recordings = try? JSONDecoder().decode([ScheduledRecording].self, from: data) else {
            return
        }
        scheduledRecordings = recordings
        for recording in recordings where recording.isEnabled {
            scheduleRecording(recording)
        }
    }

    private func saveScheduledRecordings() {
        if let data = try? JSONEncoder().encode(scheduledRecordings) {
            UserDefaults.standard.set(data, forKey: "scheduledRecordings")
        }
    }
}

extension Notification.Name {
    static let startScheduledRecording = Notification.Name("startScheduledRecording")
}
