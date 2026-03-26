import Foundation

// MARK: - Recap R13: Enterprise & Editorial Features

/// Editorial workflow, brand voice, content approval, analytics, publishing, SSO
final class RecapEnterpriseService: ObservableObject {
    static let shared = RecapEnterpriseService()

    @Published var editorialQueue: [EditorialItem] = []
    @Published var brandVoiceConfig: BrandVoiceConfig?
    @Published var analyticsData: RecapAnalytics = RecapAnalytics()
    @Published var publishingQueue: [PublishedRecap] = []
    @Published var ssoConfig: RecapSSOConfig?

    struct EditorialItem: Identifiable, Codable {
        let id: UUID; let recapId: UUID; var status: EditorialStatus
        var editor: String?; var version: Int; let submittedAt: Date?
        enum EditorialStatus: String, Codable { case draft, inReview, approved, published, rejected }
    }

    struct BrandVoiceConfig: Codable {
        var styleGuide: String; var customVocabulary: [String]; var tone: VoiceTone
        enum VoiceTone: String, Codable { case formal, casual, technical }
    }

    struct RecapAnalytics: Codable {
        var mostReadRecaps: [RecapStat] = []
        var totalRecapsGenerated: Int = 0
        var averageReadingTime: TimeInterval = 0
    }

    struct RecapStat: Identifiable, Codable {
        let id: UUID; var recapTitle: String; var views: Int; var readingTime: TimeInterval
    }

    struct PublishedRecap: Identifiable, Codable {
        let id: UUID; var recapId: UUID; var platform: PublishPlatform
        var publishedAt: Date; var status: PublishStatus
        enum PublishPlatform: String, Codable { case wordpress, contentful, linkedIn, internalWiki }
        enum PublishStatus: String, Codable { case scheduled, published, failed }
    }

    struct RecapSSOConfig: Codable {
        var provider: SSOProvider; var enabled: Bool
        enum SSOProvider: String, Codable { case okta, azureAD, googleWorkspace }
    }

    private init() { loadState() }

    func submitForEditorial(recapId: UUID) {
        let item = EditorialItem(id: UUID(), recapId: recapId, status: .inReview, editor: nil, version: 1, submittedAt: Date())
        editorialQueue.append(item); saveState()
    }

    func approveEditorial(_ id: UUID) {
        guard let idx = editorialQueue.firstIndex(where: { $0.id == id }) else { return }
        editorialQueue[idx].status = .approved; saveState()
    }

    func configureBrandVoice(styleGuide: String, vocabulary: [String], tone: BrandVoiceConfig.VoiceTone) {
        brandVoiceConfig = BrandVoiceConfig(styleGuide: styleGuide, customVocabulary: vocabulary, tone: tone)
        saveState()
    }

    func schedulePublish(recapId: UUID, platform: PublishedRecap.PublishPlatform, at date: Date) -> PublishedRecap {
        let pub = PublishedRecap(id: UUID(), recapId: recapId, platform: platform, publishedAt: date, status: .scheduled)
        publishingQueue.append(pub); saveState(); return pub
    }

    private var stateURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RECAP/enterprise.json")
    }

    func saveState() {
        try? FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let state = RecapEnterpriseState(editorialQueue: editorialQueue, brandVoiceConfig: brandVoiceConfig, analyticsData: analyticsData, publishingQueue: publishingQueue, ssoConfig: ssoConfig)
        try? JSONEncoder().encode(state).write(to: stateURL)
    }

    func loadState() {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(RecapEnterpriseState.self, from: data) else { return }
        editorialQueue = state.editorialQueue; brandVoiceConfig = state.brandVoiceConfig
        analyticsData = state.analyticsData; publishingQueue = state.publishingQueue
        ssoConfig = state.ssoConfig
    }
}

struct RecapEnterpriseState: Codable {
    var editorialQueue: [RecapEnterpriseService.EditorialItem]
    var brandVoiceConfig: RecapEnterpriseService.BrandVoiceConfig?
    var analyticsData: RecapEnterpriseService.RecapAnalytics
    var publishingQueue: [RecapEnterpriseService.PublishedRecap]
    var ssoConfig: RecapEnterpriseService.RecapSSOConfig?
}
