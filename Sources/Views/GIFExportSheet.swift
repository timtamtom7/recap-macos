import SwiftUI

struct GIFExportSheet: View {
    let recording: Recording
    @Binding var isPresented: Bool
    @State private var options = GIFExportOptions()
    @State private var isExporting = false
    @State private var progress: Double = 0
    @State private var exportedURL: URL?
    @State private var errorMessage: String?

    private let gifService = GIFExportService()

    var body: some View {
        VStack(spacing: 16) {
            Text("Export as GIF")
                .font(.headline)

            if let url = exportedURL {
                exportedView(url: url)
            } else if isExporting {
                exportingView
            } else {
                optionsView
            }
        }
        .padding()
        .frame(width: 400)
    }

    private var optionsView: some View {
        VStack(spacing: 12) {
            Form {
                Picker("Resolution", selection: $options.resolution) {
                    ForEach(GIFExportOptions.Resolution.allCases, id: \.self) { res in
                        Text(res.rawValue).tag(res)
                    }
                }

                Picker("Frame Rate", selection: $options.frameRate) {
                    ForEach(GIFExportOptions.FrameRate.allCases, id: \.self) { fps in
                        Text(fps.displayName).tag(fps)
                    }
                }

                Picker("Quality", selection: $options.quality) {
                    ForEach(GIFExportOptions.Quality.allCases, id: \.self) { q in
                        Text(q.rawValue).tag(q)
                    }
                }

                Picker("Loop", selection: $options.loopCount) {
                    ForEach(GIFExportOptions.LoopCount.allCases, id: \.self) { loop in
                        Text(loop.rawValue).tag(loop)
                    }
                }
            }

            Divider()

            HStack {
                Text("Duration:")
                Text(formatTime(recording.duration))
                    .foregroundColor(.secondary)
            }
            .font(.caption)

            HStack {
                Text("Estimated size:")
                Text(gifService.estimateSize(duration: recording.duration, options: options))
                    .foregroundColor(.secondary)
            }
            .font(.caption)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack {
                Button("Cancel") {
                    isPresented = false
                }
                Button("Export GIF") {
                    startExport()
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private var exportingView: some View {
        VStack(spacing: 16) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)

            Text("Exporting... \(Int(progress * 100))%")
                .foregroundColor(.secondary)

            Button("Cancel") {
                // Cancel export
                isExporting = false
            }
        }
        .padding()
    }

    @ViewBuilder
    private func exportedView(url: URL) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundColor(.green)

            Text("GIF exported successfully!")
                .font(.title3)

            Text(url.lastPathComponent)
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Button("Copy to Clipboard") {
                    ShareService().copyGIFToClipboard(url: url)
                    isPresented = false
                }
                Button("Done") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }

    private func startExport() {
        isExporting = true
        progress = 0

        Task {
            do {
                let url = try await gifService.exportGIF(from: recording, options: options) { p in
                    DispatchQueue.main.async {
                        progress = p
                    }
                }
                await MainActor.run {
                    exportedURL = url
                    isExporting = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isExporting = false
                }
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
