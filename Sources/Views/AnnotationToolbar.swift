import SwiftUI

struct AnnotationToolbar: View {
    @ObservedObject var engine: AnnotationEngine
    let onClose: () -> Void

    @State private var isCollapsed = false

    var body: some View {
        VStack(spacing: 0) {
            if !isCollapsed {
                // Tool buttons
                HStack(spacing: 4) {
                    ForEach(AnnotationTool.allCases, id: \.self) { tool in
                        toolButton(tool)
                    }
                }
                .padding(8)

                Divider()

                // Color picker
                HStack(spacing: 4) {
                    ForEach(Array(CodableColor.presets.prefix(6).enumerated()), id: \.offset) { _, color in
                        colorButton(color)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

                Divider()

                // Stroke width
                HStack {
                    Text("Stroke:")
                        .font(.caption)
                    Slider(value: $engine.currentStrokeWidth, in: 2...12, step: 1)
                    Text("\(Int(engine.currentStrokeWidth))pt")
                        .font(.caption2)
                        .frame(width: 28)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)

                Divider()

                // Actions
                HStack(spacing: 8) {
                    Button(action: { engine.undo() }) {
                        Image(systemName: "arrow.uturn.backward")
                    }
                    .buttonStyle(.plain)
                    .help("Undo")

                    Button(action: { engine.redo() }) {
                        Image(systemName: "arrow.uturn.forward")
                    }
                    .buttonStyle(.plain)
                    .help("Redo")

                    Button(action: { clearAll() }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                    .help("Clear all")

                    Spacer()

                    Button(action: { isCollapsed = true }) {
                        Image(systemName: "chevron.up")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
            } else {
                HStack {
                    Image(systemName: engine.currentTool.icon)
                        .font(.caption)
                    Button(action: { isCollapsed = false }) {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                }
                .padding(8)
            }
        }
        .frame(width: isCollapsed ? 40 : 220)
        .background(Color(NSColor.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(radius: 4)
    }

    @ViewBuilder
    private func toolButton(_ tool: AnnotationTool) -> some View {
        Button(action: { engine.currentTool = tool }) {
            Image(systemName: tool.icon)
                .font(.system(size: 14))
                .frame(width: 32, height: 32)
                .background(engine.currentTool == tool ? Color.accentColor.opacity(0.2) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .help(tool.rawValue)
    }

    @ViewBuilder
    private func colorButton(_ color: CodableColor) -> some View {
        Button(action: { engine.currentColor = color }) {
            Circle()
                .fill(Color(nsColor: color.color))
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .stroke(engine.currentColor == color ? Color.white : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }

    private func clearAll() {
        if let project = engine.currentProject {
            engine.setProject(AnnotationProject(recordingId: project.recordingId, duration: project.duration))
        }
    }
}
