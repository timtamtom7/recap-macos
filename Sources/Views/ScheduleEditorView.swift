import SwiftUI

struct ScheduleEditorView: View {
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var scheduledDate = Date()
    @State private var hasDuration = false
    @State private var duration: TimeInterval = 3600
    @State private var repeatOption: RepeatOption = .none
    @State private var isEnabled = true

    @StateObject private var scheduleService = ScheduledRecordingService.shared

    enum RepeatOption: String, CaseIterable {
        case none = "Once"
        case daily = "Daily"
        case weekly = "Weekly"
        case hourly = "Hourly"
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("Schedule Recording")
                .font(.headline)

            Form {
                TextField("Name", text: $name)

                DatePicker("Time", selection: $scheduledDate, displayedComponents: [.date, .hourAndMinute])

                Toggle("Set duration", isOn: $hasDuration)
                if hasDuration {
                    Stepper("\(formatDuration(duration))", value: $duration, in: 60...28800, step: 60)
                }

                Picker("Repeat", selection: $repeatOption) {
                    ForEach(RepeatOption.allCases, id: \.self) { option in
                        Text(option.rawValue).tag(option)
                    }
                }

                Toggle("Enabled", isOn: $isEnabled)
            }

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                Button("Save") {
                    saveSchedule()
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
    }

    private func saveSchedule() {
        let repeatInterval: ScheduledRecording.RepeatInterval?
        switch repeatOption {
        case .none: repeatInterval = nil
        case .daily: repeatInterval = .daily
        case .weekly: repeatInterval = .weekly(weekday: Calendar.current.component(.weekday, from: scheduledDate))
        case .hourly: repeatInterval = .hourly
        }

        let recording = ScheduledRecording(
            id: UUID(),
            name: name,
            scheduledTime: scheduledDate,
            duration: hasDuration ? duration : nil,
            repeatInterval: repeatInterval,
            isEnabled: isEnabled
        )

        scheduleService.addScheduledRecording(recording)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        return String(format: "%d:%02d", hours, minutes)
    }
}

struct ScheduleListView: View {
    @StateObject private var scheduleService = ScheduledRecordingService.shared
    @State private var showAddSheet = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Scheduled Recordings")
                    .font(.headline)
                Spacer()
                Button(action: { showAddSheet = true }) {
                    Image(systemName: "plus")
                }
            }
            .padding()

            if scheduleService.scheduledRecordings.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("No scheduled recordings")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(scheduleService.scheduledRecordings) { recording in
                    ScheduleRow(recording: recording) {
                        scheduleService.removeScheduledRecording(id: recording.id)
                    }
                }
            }
        }
        .frame(minHeight: 200)
        .sheet(isPresented: $showAddSheet) {
            ScheduleEditorView(isPresented: $showAddSheet)
        }
    }
}

struct ScheduleRow: View {
    let recording: ScheduledRecording
    let onDelete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(recording.name)
                    .font(.system(size: 13, weight: .medium))
                Text(recording.scheduledTime, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if let next = recording.nextScheduledDate {
                Text(next, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Toggle("", isOn: .constant(recording.isEnabled))
                .labelsHidden()
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}
