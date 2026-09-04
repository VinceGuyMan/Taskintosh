import Foundation

/// Classification of a fake update item
public enum UpdateCategory: String, CaseIterable, Codable, Sendable {
    case security = "Security Update"
    case critical = "Critical Update"
    case rollup = "Cumulative Update"
    case compatibility = "Compatibility Rollup"
    case vibes = "Taskintosh Vibe Service"
    case driver = "Device Component Update"
    case servicePack = "Service Pack"
}

/// A procedurally generated fake update item with realistic metadata.
public struct FakeUpdateItem: Codable, Sendable, Identifiable {
    public let id: String
    public let kbIdentifier: String
    public let title: String
    public let category: UpdateCategory
    public let downloadSizeMB: Double
    public let installSizeMB: Double
    public let simulatedComponents: [String]

    public init(
        id: String = UUID().uuidString,
        kbIdentifier: String,
        title: String,
        category: UpdateCategory = .security,
        downloadSizeMB: Double,
        installSizeMB: Double,
        simulatedComponents: [String] = []
    ) {
        self.id = id
        self.kbIdentifier = kbIdentifier
        self.title = title
        self.category = category
        self.downloadSizeMB = downloadSizeMB
        self.installSizeMB = installSizeMB
        self.simulatedComponents = simulatedComponents
    }
}
