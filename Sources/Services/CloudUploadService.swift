import Foundation
import AVFoundation

// MARK: - Cloud Upload Service Protocol

protocol CloudUploadService {
    var isConnected: Bool { get }
    var serviceName: String { get }
    
    func connect() async throws
    func disconnect()
    func upload(recording: Recording, progress: @escaping (Double) -> Void) async throws -> URL
}

// MARK: - Cloud Upload Manager

final class CloudUploadManager: ObservableObject {
    static let shared = CloudUploadManager()
    
    @Published var connectedServices: [String] = []
    @Published var uploadQueue: [CloudUploadTask] = []
    @Published var isUploading = false
    
    private var services: [String: CloudUploadService] = [:]
    private let uploadHistoryKey = "cloud_upload_history"
    
    private init() {
        loadConnectedServices()
    }
    
    func registerService(_ service: CloudUploadService) {
        services[service.serviceName] = service
    }
    
    func connect(service: String) async throws {
        guard let uploadService = services[service] else {
            throw CloudUploadError.serviceNotFound
        }
        
        try await uploadService.connect()
        
        if !connectedServices.contains(service) {
            connectedServices.append(service)
            saveConnectedServices()
        }
    }
    
    func disconnect(service: String) {
        services[service]?.disconnect()
        connectedServices.removeAll { $0 == service }
        saveConnectedServices()
    }
    
    func upload(recording: Recording, to service: String, progress: @escaping (Double) -> Void) async throws -> URL {
        guard let uploadService = services[service] else {
            throw CloudUploadError.serviceNotFound
        }
        
        isUploading = true
        defer { isUploading = false }
        
        let url = try await uploadService.upload(recording: recording, progress: progress)
        
        // Record in history
        recordUpload(recording: recording, service: service, url: url)
        
        return url
    }
    
    private func saveConnectedServices() {
        UserDefaults.standard.set(connectedServices, forKey: "connected_cloud_services")
    }
    
    private func loadConnectedServices() {
        connectedServices = UserDefaults.standard.stringArray(forKey: "connected_cloud_services") ?? []
    }
    
    private func recordUpload(recording: Recording, service: String, url: URL) {
        var history = getUploadHistory()
        history.append(CloudUploadRecord(
            recordingId: recording.id,
            service: service,
            url: url.absoluteString,
            uploadedAt: Date()
        ))
        
        // Keep last 100 records
        if history.count > 100 {
            history = Array(history.suffix(100))
        }
        
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: uploadHistoryKey)
        }
    }
    
    func getUploadHistory() -> [CloudUploadRecord] {
        guard let data = UserDefaults.standard.data(forKey: uploadHistoryKey),
              let history = try? JSONDecoder().decode([CloudUploadRecord].self, from: data) else {
            return []
        }
        return history
    }
}

struct CloudUploadTask: Identifiable {
    let id = UUID()
    let recording: Recording
    let service: String
    var progress: Double = 0
    var status: Status = .pending
    
    enum Status {
        case pending
        case uploading
        case completed(URL)
        case failed(Error)
    }
}

struct CloudUploadRecord: Codable {
    let recordingId: UUID
    let service: String
    let url: String
    let uploadedAt: Date
}

enum CloudUploadError: Error {
    case serviceNotFound
    case notConnected
    case uploadFailed
    case cancelled
}

// MARK: - Dropbox Upload Service (Stub)

final class DropboxUploadService: CloudUploadService {
    var isConnected: Bool = false
    let serviceName = "Dropbox"
    
    func connect() async throws {
        // In production, implement OAuth flow
        isConnected = true
    }
    
    func disconnect() {
        isConnected = false
    }
    
    func upload(recording: Recording, progress: @escaping (Double) -> Void) async throws -> URL {
        // Simulate upload
        for i in 0...10 {
            try await Task.sleep(nanoseconds: 100_000_000)
            progress(Double(i) / 10.0)
        }
        
        return URL(string: "https://www.dropbox.com/recap/\(recording.id)")!
    }
}

// MARK: - Google Drive Upload Service (Stub)

final class GoogleDriveUploadService: CloudUploadService {
    var isConnected: Bool = false
    let serviceName = "Google Drive"
    
    func connect() async throws {
        isConnected = true
    }
    
    func disconnect() {
        isConnected = false
    }
    
    func upload(recording: Recording, progress: @escaping (Double) -> Void) async throws -> URL {
        for i in 0...10 {
            try await Task.sleep(nanoseconds: 100_000_000)
            progress(Double(i) / 10.0)
        }
        
        return URL(string: "https://drive.google.com/recap/\(recording.id)")!
    }
}

// MARK: - YouTube Upload Service (Stub)

final class YouTubeUploadService: CloudUploadService {
    var isConnected: Bool = false
    let serviceName = "YouTube"
    
    func connect() async throws {
        isConnected = true
    }
    
    func disconnect() {
        isConnected = false
    }
    
    func upload(recording: Recording, progress: @escaping (Double) -> Void) async throws -> URL {
        for i in 0...10 {
            try await Task.sleep(nanoseconds: 100_000_000)
            progress(Double(i) / 10.0)
        }
        
        return URL(string: "https://www.youtube.com/watch?v=recap\(recording.id.uuidString.prefix(8))")!
    }
}
