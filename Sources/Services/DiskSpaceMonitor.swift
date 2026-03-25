import Foundation

final class DiskSpaceMonitor: ObservableObject {
    static let shared = DiskSpaceMonitor()
    
    @Published var availableSpace: Int64 = 0
    @Published var isLowSpace = false
    @Published var criticalSpace = false
    
    private let warningThreshold: Int64 = 5 * 1024 * 1024 * 1024 // 5GB
    private let criticalThreshold: Int64 = 1 * 1024 * 1024 * 1024 // 1GB
    private var timer: Timer?
    
    private init() {
        checkDiskSpace()
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    func checkDiskSpace() {
        let fileManager = FileManager.default
        
        do {
            let homeURL = URL(fileURLWithPath: NSHomeDirectory())
            let values = try homeURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                availableSpace = capacity
                isLowSpace = capacity < warningThreshold
                criticalSpace = capacity < criticalThreshold
            }
        } catch {
            print("Error checking disk space: \(error)")
        }
    }
    
    private func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.checkDiskSpace()
        }
    }
    
    var formattedAvailableSpace: String {
        ByteCountFormatter.string(fromByteCount: availableSpace, countStyle: .file)
    }
    
    var warningMessage: String? {
        if criticalSpace {
            return "Critical: Only \(formattedAvailableSpace) remaining. Recording will stop automatically."
        } else if isLowSpace {
            return "Warning: Only \(formattedAvailableSpace) remaining. Consider freeing up space."
        }
        return nil
    }
}

// MARK: - Recording Auto-Stop

final class RecordingAutoStopManager {
    static let shared = RecordingAutoStopManager()
    
    private init() {}
    
    func shouldAutoStop() -> Bool {
        return DiskSpaceMonitor.shared.criticalSpace
    }
    
    func handleLowDiskSpace() {
        // Post notification to stop recording
        NotificationCenter.default.post(name: .stopRecordingDueToDiskSpace, object: nil)
    }
}

extension Notification.Name {
    static let stopRecordingDueToDiskSpace = Notification.Name("RECAPStopRecordingDueToDiskSpace")
}
