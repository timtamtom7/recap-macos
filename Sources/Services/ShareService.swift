import Foundation
import AppKit

final class ShareService {
    func share(recording: Recording, from view: NSView) {
        let picker = NSSharingServicePicker(items: [recording.filePath])
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }

    func shareGIF(url: URL, from view: NSView) {
        let picker = NSSharingServicePicker(items: [url])
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }

    func copyToClipboard(fileURL: URL) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects([fileURL as NSURL])
    }

    func copyGIFToClipboard(url: URL) {
        guard let imageData = try? Data(contentsOf: url) else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(imageData, forType: .tiff)
    }

    func copyVideoURL(_ recording: Recording) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(recording.filePath.absoluteString, forType: .string)
    }

    func shareViaAirDrop(url: URL) {
        NSWorkspace.shared.open(url)
    }
}
