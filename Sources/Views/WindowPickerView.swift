import SwiftUI

struct WindowPickerView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedWindow: WindowInfo?

    private let exportService = ExportService.shared

    var body: some View {
        VStack(spacing: 20) {
            Text("Select Window to Record")
                .font(.headline)

            let windows = exportService.getAvailableWindows()

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(windows) { window in
                        WindowRow(window: window, isSelected: selectedWindow?.id == window.id)
                            .onTapGesture {
                                selectedWindow = window
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
                    if let window = selectedWindow {
                        appState.selectWindow(window)
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .disabled(selectedWindow == nil)
            }
            .padding()
        }
        .frame(width: 450, height: 500)
    }
}

struct WindowRow: View {
    let window: WindowInfo
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .frame(width: 80, height: 50)
                .overlay {
                    Image(systemName: "macwindow")
                        .foregroundColor(.secondary)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(window.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(window.ownerName)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("\(Int(window.bounds.width)) × \(Int(window.bounds.height))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding()
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
