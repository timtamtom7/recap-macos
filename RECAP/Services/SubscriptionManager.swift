import Foundation
import StoreKit

@available(macOS 13.0, *)
public final class RecapSubscriptionManager: ObservableObject {
    public static let shared = RecapSubscriptionManager()
    @Published public private(set) var subscription: RecapSubscription?
    @Published public private(set) var products: [Product] = []
    private init() {}
    public func loadProducts() async {
        do { products = try await Product.products(for: ["com.recap.macos.pro.monthly","com.recap.macos.pro.yearly","com.recap.macos.team.monthly","com.recap.macos.team.yearly"]) }
        catch { print("Failed to load products") }
    }
    public func canAccess(_ feature: RecapFeature) -> Bool {
        guard let sub = subscription else { return false }
        switch feature {
        case .widgets: return sub.tier != .free
        case .shortcuts: return sub.tier != .free
        case .teamSharing: return sub.tier == .team
        }
    }
    public func updateStatus() async {
        var found: RecapSubscription = RecapSubscription(tier: .free)
        for await result in Transaction.currentEntitlements {
            do {
                let t = try checkVerified(result)
                if t.productID.contains("team") { found = RecapSubscription(tier: .team, status: t.revocationDate == nil ? "active" : "expired") }
                else if t.productID.contains("pro") { found = RecapSubscription(tier: .pro, status: t.revocationDate == nil ? "active" : "expired") }
            } catch { continue }
        }
        await MainActor.run { self.subscription = found }
    }
    public func restore() async throws { try await AppStore.sync(); await updateStatus() }
    private func checkVerified<T>(_ r: VerificationResult<T>) throws -> T { switch r { case .unverified: throw NSError(domain: "Recap", code: -1); case .verified(let s): return s } }
}
public enum RecapFeature { case widgets, shortcuts, teamSharing }
