import Foundation

/// AI-powered recording intelligence for Recap screen recorder
final class RecordingIntelligence {
    static let shared = RecordingIntelligence()
    
    private init() {}
    
    /// Suggest optimal recording quality based on content type
    func suggestQuality(for contentType: String) -> String {
        switch contentType {
        case "presentation": return "1080p"
        case "code": return "1440p"
        case "gameplay": return "4K"
        default: return "1080p"
        }
    }
}
