import Foundation
#if os(iOS)
import WidgetKit
#endif

struct Exploration: Identifiable, Codable {
    let id: UUID
    var date: Date
    var start: String
    var pages: [String]
    var discoveries: [Discovery]
    var host: String { URL(string: start)?.host ?? start }
    var referenceCount: Int { discoveries.filter { $0.type != "Link" }.count }
}

/// The App Group the iOS app shares with its widget. The Mac app has no widget and keeps everything in its own container.
enum SharedStore {
    static let group = "group.dev.ividi.iwebcrawler"
    static var defaults: UserDefaults? {
        #if os(iOS)
        UserDefaults(suiteName: group)
        #else
        nil
        #endif
    }
    static var historyFile: URL {
        let own = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("iWebCrawler", isDirectory: true).appendingPathComponent("history.json")
        #if os(iOS)
        if let shared = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: group)?.appendingPathComponent("history.json") {
            // Explorations saved before the widget existed move into the shared container once.
            if !FileManager.default.fileExists(atPath: shared.path), FileManager.default.fileExists(atPath: own.path) {
                try? FileManager.default.moveItem(at: own, to: shared)
            }
            return shared
        }
        #endif
        return own
    }
    static func reloadWidgets() {
        #if os(iOS)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }
}

/// Saved explorations, kept on this device only, newest first.
@MainActor
final class HistoryStore: ObservableObject {
    static let shared = HistoryStore()
    static let limit = 30
    @Published private(set) var items: [Exploration] = []
    private let file: URL

    init(file: URL? = nil) {
        self.file = file ?? SharedStore.historyFile
        items = Self.load(from: self.file)
    }
    /// Reads saved explorations without touching the main actor; the widget uses it too.
    nonisolated static func load(from file: URL = SharedStore.historyFile) -> [Exploration] {
        guard let data = try? Data(contentsOf: file) else { return [] }
        let decoder = JSONDecoder(); decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Exploration].self, from: data)) ?? []
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
        let encoder = JSONEncoder(); encoder.dateEncodingStrategy = .iso8601
        try? encoder.encode(items).write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        SharedStore.reloadWidgets()
    }
}
