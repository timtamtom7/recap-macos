import SwiftUI

struct MultiDisplaySelectorView: View {
    @StateObject private var displayService = MultiDisplayCaptureService()

    var body: some View {
        VStack(spacing: 16) {
            Text("Select Displays")
                .font(.headline)

            Text("Choose which displays to record. Multiple displays can be composited together.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(displayService.availableDisplays) { display in
                        DisplaySelectorCard(display: display, isSelected: displayService.selectedDisplays.contains(display.id)) {
                            toggleDisplay(display)
                        }
                    }
                }
            }

            if displayService.selectedDisplays.count > 1 {
                Divider()

                Text("Composite Layout")
                    .font(.subheadline)

                Picker("Layout", selection: $displayService.compositeLayout) {
                    ForEach(MultiDisplayCaptureService.CompositeLayout.allCases, id: \.self) { layout in
                        Text(layout.rawValue).tag(layout)
                    }
                }
                .pickerStyle(.segmented)
            }

            HStack {
                Button("Refresh") {
                    displayService.refreshDisplays()
                }
                Spacer()
                Button("Cancel") {}
                Button("Start Recording") {
                    // Start recording with selected displays
                }
                .buttonStyle(.borderedProminent)
                .disabled(displayService.selectedDisplays.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 450)
    }

    private func toggleDisplay(_ display: DisplayInfo) {
        if displayService.selectedDisplays.contains(display.id) {
            displayService.deselectDisplay(display)
        } else {
            displayService.selectDisplay(display)
        }
    }
}

struct DisplaySelectorCard: View {
    let display: DisplayInfo
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: isSelected ? 3 : 1)
                .frame(height: 80)
                .overlay(
                    VStack {
                        if display.id == CGMainDisplayID() {
                            Image(systemName: "desktopcomputer")
                                .font(.title)
                                .foregroundColor(.secondary)
                        } else {
                            Image(systemName: "display")
                                .font(.title)
                                .foregroundColor(.secondary)
                        }
                        Text(display.name)
                            .font(.caption)
                    }
                )
                .onTapGesture(perform: onTap)

            Text("\(Int(display.resolution.width))×\(Int(display.resolution.height))")
                .font(.caption2)
                .foregroundColor(.secondary)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
    }
}
