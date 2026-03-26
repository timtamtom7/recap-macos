import SwiftUI
import AVKit

struct TrimmerView: View {
    let recording: Recording
    @Binding var trimRange: TrimRange
    @State private var isPlaying = false
    @State private var duration: TimeInterval = 0
    @State private var currentTime: TimeInterval = 0
    @State private var videoPlayer: AVPlayer?
    @State private var isDraggingInHandle = false
    @State private var isDraggingOutHandle = false
    @State private var dragOffset: CGFloat = 0

    private let trimService = TrimService()

    var body: some View {
        VStack(spacing: 16) {
            // Video preview
            if let player = videoPlayer {
                VideoPlayer(player: player)
                    .frame(height: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Timeline
            VStack(spacing: 8) {
                GeometryReader { geometry in
                    let width = geometry.size.width

                    ZStack(alignment: .leading) {
                        // Track background
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(NSColor.separatorColor))

                        // Selected range
                        let inPos = (trimRange.startTime / max(duration, 1)) * width
                        let outPos = (trimRange.endTime / max(duration, 1)) * width

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor.opacity(0.3))
                            .frame(width: outPos - inPos)
                            .offset(x: inPos)

                        // Playhead
                        let playheadPos = (currentTime / max(duration, 1)) * width
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 2)
                            .offset(x: playheadPos)
                            .shadow(radius: 1)

                        // In handle
                        TrimHandle(isIn: true)
                            .offset(x: inPos - 8)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let newTime = max(0, min(value.location.x / width * duration, trimRange.endTime - 0.1))
                                        trimRange.startTime = newTime
                                    }
                            )

                        // Out handle
                        TrimHandle(isIn: false)
                            .offset(x: outPos - 8)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let newTime = max(trimRange.startTime + 0.1, min(value.location.x / width * duration, duration))
                                        trimRange.endTime = newTime
                                    }
                            )
                    }
                    .frame(height: 44)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let tappedTime = location.x / width * duration
                        videoPlayer?.seek(to: CMTime(seconds: tappedTime, preferredTimescale: 600))
                    }
                }
                .frame(height: 44)

                // Time labels
                HStack {
                    Text(formatTime(trimRange.startTime))
                        .font(.caption.monospaced())
                    Spacer()
                    Text("Duration: \(formatTime(trimRange.duration))")
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatTime(trimRange.endTime))
                        .font(.caption.monospaced())
                }
            }
            .padding(.horizontal)

            // Controls
            HStack(spacing: 16) {
                Button("Set In") {
                    trimRange.startTime = currentTime
                }

                Button("Set Out") {
                    trimRange.endTime = currentTime
                }

                Button("Reset") {
                    trimRange.startTime = 0
                    trimRange.endTime = duration
                }
            }

            HStack {
                Button("Cancel") {
                    // Cancel action
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Export Trimmed") {
                    exportTrimmed()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(width: 600, height: 480)
        .onAppear { setup() }
        .onDisappear { teardown() }
    }

    private func setup() {
        videoPlayer = AVPlayer(url: recording.filePath)
        Task {
            duration = await trimService.getDuration(for: recording)
            if duration > 0 {
                trimRange.endTime = duration
            }
        }
    }

    private func teardown() {
        videoPlayer?.pause()
    }

    private func exportTrimmed() {
        Task {
            do {
                let newRecording = try await trimService.trim(recording: recording, range: trimRange) { progress in
                    // Update progress UI
                }
                // Save and show
            } catch {
                print("Trim error: \(error)")
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        let centiseconds = Int((time.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%02d:%02d.%02d", minutes, seconds, centiseconds)
    }
}

struct TrimHandle: View {
    let isIn: Bool

    var body: some View {
        VStack(spacing: 0) {
            Path { path in
                path.move(to: CGPoint(x: 8, y: 0))
                if isIn {
                    path.addLine(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 8, y: 44))
                    path.addLine(to: CGPoint(x: 16, y: 44))
                } else {
                    path.addLine(to: CGPoint(x: 16, y: 0))
                    path.addLine(to: CGPoint(x: 8, y: 44))
                }
                path.closeSubpath()
            }
            .fill(Color.accentColor)
            .frame(width: 16, height: 44)

            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 16, height: 2)
        }
    }
}
