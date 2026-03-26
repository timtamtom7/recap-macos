import Foundation
import Combine
import Network

// MARK: - Recap R14: REST API (port 8778) & Webhooks

final class RecapAPIService: ObservableObject {
    static let shared = RecapAPIService()

    private var listener: NWListener?
    private let port: UInt16 = 8778
    @Published var isRunning = false

    private init() {}

    func start() {
        guard listener == nil else { return }
        do {
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
            listener?.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async { self?.isRunning = state == .ready }
            }
            listener?.newConnectionHandler = { [weak self] conn in
                self?.handle(conn)
            }
            listener?.start(queue: .global())
        } catch { print("RecapAPI error: \(error)") }
    }

    func stop() {
        listener?.cancel(); listener = nil
        DispatchQueue.main.async { self.isRunning = false }
    }

    private func handle(_ conn: NWConnection) {
        conn.start(queue: .global())
        conn.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, _ in
            guard let data = data, let req = String(data: data, encoding: .utf8) else { conn.cancel(); return }
            let resp = self?.route(req) ?? RecapHTTPResp(code: 404, body: "{\"error\":\"Not found\"}")
            let http = "HTTP/1.1 \(resp.code)\r\nContent-Type: application/json\r\nContent-Length: \(resp.body.count)\r\n\r\n\(resp.body)"
            conn.send(content: http.data(using: .utf8), completion: .contentProcessed { _ in conn.cancel() })
        }
    }

    struct RecapHTTPResp { let code: Int; let body: String }

    private func route(_ req: String) -> RecapHTTPResp {
        let lines = req.split(separator: "\r\n")
        guard let rl = lines.first else { return RecapHTTPResp(code: 404, body: "{\"error\":\"Not found\"}") }
        let parts = String(rl).split(separator: " ")
        guard parts.count >= 2 else { return RecapHTTPResp(code: 404, body: "{\"error\":\"Not found\"}") }
        let path = String(parts[1])
        guard lines.contains(where: { $0.hasPrefix("X-API-Key:") }) else {
            return RecapHTTPResp(code: 401, body: "{\"error\":\"Unauthorized\"}")
        }
        switch path {
        case "/sources": return RecapHTTPResp(code: 200, body: "[]")
        case "/articles": return RecapHTTPResp(code: 200, body: "[]")
        case "/recaps": return RecapHTTPResp(code: 200, body: "[]")
        case "/team": return RecapHTTPResp(code: 200, body: "[]")
        case "/share": return RecapHTTPResp(code: 200, body: "{\"shareUrl\":\"\"}")
        case "/openapi.json": return RecapHTTPResp(code: 200, body: openAPISpec())
        default: return RecapHTTPResp(code: 404, body: "{\"error\":\"Not found\"}")
        }
    }

    private func openAPISpec() -> String {
        return "{\"openapi\":\"3.0.0\",\"info\":{\"title\":\"Recap API\",\"version\":\"1.0\"},\"paths\":{\"/sources\":{\"get\":{\"summary\":\"List content sources\"}},\"/articles\":{\"get\":{\"summary\":\"List articles\"}},\"/recaps\":{\"get\":{\"summary\":\"List recaps\"}},\"/team\":{\"get\":{\"summary\":\"Team members\"}},\"/share\":{\"post\":{\"summary\":\"Share recap\"}}}}"
    }
}

// MARK: - Recap R15: iOS Companion Stub

final class RecapiOSService: ObservableObject {
    static let shared = RecapiOSService()
    @Published var latestRecap: iOSRecapRef?
    @Published var widgetData: [String: Any] = [:]

    struct iOSRecapRef: Identifiable {
        let id = UUID(); let title: String; let source: String; let readingTime: Int // minutes
    }

    private init() {}
}
