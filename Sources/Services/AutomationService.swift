import Foundation
import AppKit

enum AutomationTrigger: Codable, Equatable {
    case onAppLaunch
    case onAppActive(bundleId: String)
    case onSystemWake

    var displayName: String {
        switch self {
        case .onAppLaunch: return "On app launch"
        case .onAppActive(let bundleId): return "When \(bundleId) becomes active"
        case .onSystemWake: return "On system wake"
        }
    }
}

final class AutomationService: ObservableObject {
    static let shared = AutomationService()

    @Published var triggers: [AutomationTrigger] = []
    @Published var isEnabled = true

    private var observerTokens: [Any] = []

    private init() {
        loadTriggers()
        setupObservers()
    }

    func addTrigger(_ trigger: AutomationTrigger) {
        triggers.append(trigger)
        saveTriggers()
    }

    func removeTrigger(_ trigger: AutomationTrigger) {
        triggers.removeAll { $0 == trigger }
        saveTriggers()
    }

    private func setupObservers() {
        // App launch
        if triggers.contains(.onAppLaunch) {
            // Already launched if this is called
        }

        // System wake
        if triggers.contains(.onSystemWake) {
            let wakeObserver = NSWorkspace.shared.notificationCenter.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.handleSystemWake()
            }
            observerTokens.append(wakeObserver)
        }
    }

    private func handleSystemWake() {
        NotificationCenter.default.post(name: .systemDidWake, object: nil)
    }

    private func loadTriggers() {
        guard let data = UserDefaults.standard.data(forKey: "automationTriggers"),
              let decoded = try? JSONDecoder().decode([AutomationTrigger].self, from: data) else {
            return
        }
        triggers = decoded
    }

    private func saveTriggers() {
        if let data = try? JSONEncoder().encode(triggers) {
            UserDefaults.standard.set(data, forKey: "automationTriggers")
        }
    }
}
