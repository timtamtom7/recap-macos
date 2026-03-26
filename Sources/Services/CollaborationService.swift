import Foundation
import Combine

// MARK: - Recap R12: Collaboration & Team Recaps

/// Team recap feed, collaborative curation, team digest, shared sources
final class RecapCollaborationService: ObservableObject {
    static let shared = RecapCollaborationService()

    @Published var teamFeeds: [TeamFeed] = []
    @Published var curations: [CuratedArticle] = []
    @Published var teamDigests: [TeamDigest] = []
    @Published var sharedSources: [SharedSource] = []
    @Published var comments: [RecapComment] = []
    @Published var guestInvites: [RecapGuestInvite] = []

    private init() { loadState() }

    func createTeamFeed(name: String, members: [String]) -> TeamFeed {
        let feed = TeamFeed(id: UUID(), name: name, members: members, articles: [], createdAt: Date())
        teamFeeds.append(feed); saveState(); return feed
    }

    func upvoteArticle(_ articleId: UUID, by user: String) {
        let curation = CuratedArticle(id: UUID(), articleId: articleId, upvotedBy: [user], votes: 1, status: .pending)
        curations.append(curation); saveState()
    }

    func generateTeamDigest(feedId: UUID, period: TeamDigest.DigestPeriod) -> TeamDigest {
        let digest = TeamDigest(id: UUID(), feedId: feedId, period: period, articles: [], generatedAt: Date())
        teamDigests.append(digest); saveState(); return digest
    }

    func addSharedSource(feedId: UUID, url: String, addedBy: String) -> SharedSource {
        let source = SharedSource(id: UUID(), feedId: feedId, url: url, addedBy: addedBy, createdAt: Date())
        sharedSources.append(source); saveState(); return source
    }

    func addComment(articleId: UUID, author: String, text: String) -> RecapComment {
        let comment = RecapComment(id: UUID(), articleId: articleId, author: author, text: text, createdAt: Date())
        comments.append(comment); saveState(); return comment
    }

    func inviteGuest(feedId: UUID, email: String, accessLevel: RecapGuestAccess) -> RecapGuestInvite {
        let invite = RecapGuestInvite(id: UUID(), feedId: feedId, email: email, accessLevel: accessLevel, expiresAt: Calendar.current.date(byAdding: .day, value: 30, to: Date()), createdAt: Date())
        guestInvites.append(invite); saveState(); return invite
    }

    private var stateURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RECAP/collaboration.json")
    }

    func saveState() {
        try? FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let state = RecapCollabState(teamFeeds: teamFeeds, curations: curations, teamDigests: teamDigests, sharedSources: sharedSources, comments: comments, guestInvites: guestInvites)
        try? JSONEncoder().encode(state).write(to: stateURL)
    }

    func loadState() {
        guard let data = try? Data(contentsOf: stateURL),
              let state = try? JSONDecoder().decode(RecapCollabState.self, from: data) else { return }
        teamFeeds = state.teamFeeds; curations = state.curations
        teamDigests = state.teamDigests; sharedSources = state.sharedSources
        comments = state.comments; guestInvites = state.guestInvites
    }
}

// MARK: - Models

struct TeamFeed: Identifiable, Codable {
    let id: UUID; var name: String; var members: [String]; var articles: [UUID]
    let createdAt: Date
}

struct CuratedArticle: Identifiable, Codable {
    let id: UUID; let articleId: UUID; var upvotedBy: [String]; var votes: Int
    var status: CurationStatus
    enum CurationStatus: String, Codable { case pending, approved, rejected }
}

struct TeamDigest: Identifiable, Codable {
    let id: UUID; let feedId: UUID; var period: DigestPeriod; var articles: [UUID]
    let generatedAt: Date
    enum DigestPeriod: String, Codable { case weekly, monthly }
}

struct SharedSource: Identifiable, Codable {
    let id: UUID; let feedId: UUID; var url: String; var addedBy: String
    let createdAt: Date
}

struct RecapComment: Identifiable, Codable {
    let id: UUID; let articleId: UUID; var author: String; var text: String
    let createdAt: Date
}

struct RecapGuestInvite: Identifiable, Codable {
    let id: UUID; let feedId: UUID; var email: String
    var accessLevel: RecapGuestAccess; var expiresAt: Date?; let createdAt: Date
}

enum RecapGuestAccess: String, Codable { case readOnly, contributor }

struct RecapCollabState: Codable {
    var teamFeeds: [TeamFeed]; var curations: [CuratedArticle]
    var teamDigests: [TeamDigest]; var sharedSources: [SharedSource]
    var comments: [RecapComment]; var guestInvites: [RecapGuestInvite]
}
