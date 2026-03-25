import SwiftUI

struct TimestampSettingsView: View {
    @AppStorage("timestampEnabled") private var enabled = true
    @AppStorage("timestampPosition") private var position = "Top Left"
    @AppStorage("timestampFormat") private var format = "HH:MM:SS.mm"
    @AppStorage("timestampFontSize") private var fontSize = 24

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Show Timestamp Overlay", isOn: $enabled)

            if enabled {
                HStack {
                    Picker("Format", selection: $format) {
                        Text("HH:MM:SS").tag("HH:MM:SS")
                        Text("HH:MM:SS.mm").tag("HH:MM:SS.mm")
                        Text("HH:MM:SS AM/PM").tag("HH:MM:SS AM/PM")
                    }
                    .labelsHidden()

                    Picker("Position", selection: $position) {
                        Text("Top Left").tag("Top Left")
                        Text("Top Right").tag("Top Right")
                        Text("Bottom Left").tag("Bottom Left")
                        Text("Bottom Right").tag("Bottom Right")
                    }
                    .labelsHidden()
                }

                HStack {
                    Text("Size:")
                    Slider(value: Binding(
                        get: { Double(fontSize) },
                        set: { fontSize = Int($0) }
                    ), in: 12...48, step: 2)
                    Text("\(fontSize)pt")
                        .frame(width: 40)
                }
            }
        }
    }
}

struct ClickHighlightSettingsView: View {
    @AppStorage("clickHighlightEnabled") private var enabled = true
    @AppStorage("clickHighlightStyle") private var style = "Circle"
    @AppStorage("clickHighlightSize") private var size = "Medium"

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Highlight Clicks", isOn: $enabled)

            if enabled {
                HStack {
                    Picker("Style", selection: $style) {
                        Text("Circle").tag("Circle")
                        Text("Ripple").tag("Ripple")
                        Text("Spotlight").tag("Spotlight")
                        Text("None").tag("None")
                    }
                    .labelsHidden()

                    Picker("Size", selection: $size) {
                        Text("Small").tag("Small")
                        Text("Medium").tag("Medium")
                        Text("Large").tag("Large")
                    }
                    .labelsHidden()
                }
            }
        }
    }
}
