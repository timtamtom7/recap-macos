import SwiftUI
import AVKit

struct AnnotationEditorView: View {
    let recording: Recording
    @StateObject private var engine = AnnotationEngine()
    @State private var currentTime: TimeInterval = 0
    @State private var isPlaying = false
    @State private var videoPlayer: AVPlayer?
    @State private var canvasSize: CGSize = .zero

    private let projectStore = AnnotationProjectStore()

    var body: some View {
        HSplitView {
            // Video + annotation canvas
            ZStack {
                if let player = videoPlayer {
                    VideoPlayer(player: player)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                AnnotationCanvasView(engine: engine, currentTime: currentTime, canvasSize: canvasSize)
                    .allowsHitTesting(true)
                    .gesture(annotationGesture)
            }
            .frame(minWidth: 400)

            // Right panel - layers
            VStack(spacing: 0) {
                HStack {
                    Text("Layers")
                        .font(.headline)
                    Spacer()
                    Text(formattedTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))

                Divider()

                if let project = engine.currentProject {
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(project.layers) { layer in
                                layerRow(layer)
                            }
                        }
                        .padding()
                    }
                }

                Divider()

                // Timeline scrubber
                VStack(spacing: 4) {
                    Slider(value: $currentTime, in: 0...(engine.currentProject?.duration ?? 1))
                        .onChange(of: currentTime) { newTime in
                            videoPlayer?.seek(to: CMTime(seconds: newTime, preferredTimescale: 600))
                        }

                    HStack {
                        Text(formatTime(currentTime))
                        Spacer()
                        Text(formatTime(engine.currentProject?.duration ?? 0))
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                .padding()
            }
            .frame(width: 250)
        }
        .onAppear { setup() }
        .onDisappear { teardown() }
    }

    private var formattedTime: String {
        formatTime(currentTime)
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func setup() {
        if true {
            videoPlayer = AVPlayer(url: recording.filePath)
            let duration = videoPlayer?.currentItem?.asset.duration.seconds ?? 0
            let project = projectStore.getProject(forRecording: recording.id) ?? AnnotationProject(recordingId: recording.id, duration: duration)
            engine.setProject(project)
        }
    }

    private func teardown() {
        if let project = engine.currentProject {
            projectStore.saveProject(project)
        }
        videoPlayer?.pause()
    }

    private var annotationGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                if !engine.isDrawing {
                    engine.startStroke(at: value.location, time: currentTime)
                } else {
                    engine.continueStroke(to: value.location, time: currentTime)
                }
            }
            .onEnded { _ in
                engine.endStroke(at: nil, text: nil, time: currentTime)
            }
    }

    @ViewBuilder
    private func layerRow(_ layer: AnnotationLayer) -> some View {
        HStack {
            Image(systemName: layer.tool.icon)
                .foregroundColor(Color(nsColor: layer.color.color))
            Text(layer.tool.rawValue)
                .font(.caption)
            Spacer()
            Text("\(formatTime(layer.startTime)) - \(formatTime(layer.endTime))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(4)
    }
}
