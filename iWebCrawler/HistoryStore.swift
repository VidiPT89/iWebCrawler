import Foundation

struct Exploration: Identifiable, Codable {
    let id: UUID
    var date: Date
    var start: String
    var pages: [String]
    var discoveries: [Discovery]
    var host: String { URL(string: start)?.host ?? start }
    var referenceCount: Int { discoveries.filter { $0.type != "Link" }.count }
}

/// Saved explorations, kept on this device only, newest first.
@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    static let limit = 30
    @Published private(set) var items: [Exploration] = []
    private let file: URL

    init(file: URL? = nil) {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("iWebCrawler", isDirectory: true)
        self.file = file ?? base.appendingPathComponent("history.json")
        if let data = try? Data(contentsOf: self.file), let saved = try? Self.decoder.decode([Exploration].self, from: data) { items = saved }
    }
    func save(_ exploration: Exploration) {
        items.removeAll { $0.id == exploration.id }
        items.insert(exploration, at: 0)
        items = Array(items.sorted { $0.date > $1.date }.prefix(Self.limit))
        persist()
    }
    func delete(_ id: UUID) { items.removeAll { $0.id == id }; persist() }
    func clear() { items = []; persist() }

    private func persist() {
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? Self.encoder.encode(items).write(to: file, options: [.atomic, .completeFileProtection])
    }
    private static let encoder: JSONEncoder = { let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601; return encoder }()
    private static let decoder: JSONDecoder = { let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601; return decoder }()
}
