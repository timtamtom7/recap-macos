import SwiftUI

struct DisplayPickerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedDisplay: DisplayInfo?

    private let exportService = ExportService.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("Select Display to Record")
                .font(.headline)

            let displays = exportService.getAvailableDisplays()

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(displays) { display in
                        DisplayCard(display: display, isSelected: selectedDisplay?.id == display.id)
                            .onTapGesture {
                                selectedDisplay = display
                            }
                    }
                }
                .padding()
            }

            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button("Start Recording") {
                    if let display = selectedDisplay {
                        appState.selectDisplay(display)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(selectedDisplay == nil)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .onAppear {
            if appState.selectedDisplay == nil, let first = exportService.getAvailableDisplays().first {
                selectedDisplay = first
            } else {
                selectedDisplay = appState.selectedDisplay
            }
        }
    }
}

struct DisplayCard: View {
    let display: DisplayInfo
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 120)
                .overlay {
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                }
                .overlay {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.accentColor, lineWidth: 3)
                    }
                }

            Text(display.name)
                .font(.subheadline)
                .fontWeight(.medium)

            Text("\(Int(display.resolution.width)) × \(Int(display.resolution.height))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
