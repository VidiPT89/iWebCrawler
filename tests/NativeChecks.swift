import Foundation

@main
struct NativeChecks {
    @MainActor static func main() {
        let samples: [(String, String?)] = [
            ("example.com", "https://example.com"),
            ("  https://example.com/path?q=test#section  ", "https://example.com/path?q=test#section"),
            ("http://localhost:8080", "http://localhost:8080"),
            ("ftp://example.com/file", nil),
            ("https://user:password@example.com", nil),
            ("hello world", nil),
            ("", nil)
        ]
        for (input, expected) in samples {
            precondition(CrawlerModel.normalizedURL(input)?.absoluteString == expected, "URL validation failed: \(input)")
        }
        precondition(AppAppearance.system.scheme == nil)
        precondition(AppAppearance.light.scheme == .light)
        precondition(AppAppearance.dark.scheme == .dark)
        precondition(AppLanguage.portuguese.rawValue == "pt-PT")
        precondition(AppLanguage.english.rawValue == "en")
        let defaults = MemoryDefaults()
        defaults.values = ["language": "pt-PT", "appearance": "dark", "pageLimit": 999, "speed": -1]
        let prefs = Preferences(defaults: defaults)
        precondition(prefs.pageLimit == 20 && prefs.speed == 1)
        precondition(prefs.language == .portuguese && prefs.appearance == .dark)
        precondition(prefs.text("Olá", "Hello") == "Olá")
        prefs.language = .english; prefs.appearance = .light; prefs.speed = 2; prefs.reducedMotion = true
        let restored = Preferences(defaults: defaults)
        precondition(restored.text("Olá", "Hello") == "Hello")
        precondition(restored.appearance == .light && restored.speed == 2 && restored.reducedMotion)
        checkRobots(); checkExportAndHealth(); checkHistory(); checkMapLayout()
        print("Native checks passed: URL validation, locale selection, appearance mapping, preference restoration and bounds, robots.txt rules, CSV export, link health, saved history and map layout.")
    }

    @MainActor static func checkRobots() {
        let robots = RobotsRules("""
        # comment
        User-agent: Googlebot
        Disallow: /

        User-agent: *
        Disallow: /private
        Allow: /private/open
        Disallow: /*.pdf$
        Disallow:
        """)
        precondition(robots.allows("/"))
        precondition(!robots.allows("/private/data"))
        precondition(robots.allows("/private/open/page"))
        precondition(!robots.allows("/files/report.pdf") && robots.allows("/files/report.pdf.html"))
        let specific = RobotsRules("User-agent: *\nDisallow: /\n\nUser-agent: iWebCrawler\nUser-agent: other\nDisallow: /admin")
        precondition(specific.allows("/wiki") && !specific.allows("/admin/x"))
        precondition(RobotsRules("").allows("/anything") && !RobotsRules.disallowAll.allows("/") && RobotsRules.allowAll.allows("/"))
        precondition(CrawlerModel.robotsPath(URL(string: "https://example.com")!) == "/")
        precondition(CrawlerModel.robotsPath(URL(string: "https://example.com/a%20b/c")!) == "/a%20b/c")
    }

    @MainActor static func checkExportAndHealth() {
        let item = Discovery(id: UUID(), title: "Say \"hi\", world", url: "https://example.com/a", type: "DOI", page: "https://example.com", status: 404)
        let csv = CollectionExport.csv([item])
        precondition(csv == "title,url,type,page,status\r\n\"Say \"\"hi\"\", world\",\"https://example.com/a\",\"DOI\",\"https://example.com\",404\r\n", "CSV escaping failed")
        precondition(LinkHealth(status: nil) == .unchecked && LinkHealth(status: 200) == .ok && LinkHealth(status: 301) == .redirected)
        precondition(LinkHealth(status: 404) == .broken && LinkHealth(status: -1) == .unreachable && LinkHealth(status: -2) == .skipped)
        precondition(LinkHealth(status: 500).isProblem && !LinkHealth(status: -2).isProblem)
        precondition(LinkHealth(status: 403) == .restricted && LinkHealth(status: 429) == .restricted && !LinkHealth(status: 403).isProblem && LinkHealth(status: 410) == .broken)
    }

    @MainActor static func checkHistory() {
        let file = FileManager.default.temporaryDirectory.appendingPathComponent("iwebcrawler-history-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: file) }
        let store = HistoryStore(file: file)
        let first = Exploration(id: UUID(), date: Date(timeIntervalSince1970: 100), start: "https://example.com", pages: ["https://example.com"], discoveries: [])
        store.save(first)
        for i in 0..<(HistoryStore.limit + 5) { store.save(Exploration(id: UUID(), date: Date(timeIntervalSince1970: Double(200 + i)), start: "https://site\(i).org", pages: [], discoveries: [])) }
        precondition(store.items.count == HistoryStore.limit && !store.items.contains { $0.id == first.id }, "History limit failed")
        var updated = store.items[3]; updated.date = Date(timeIntervalSince1970: 10_000); store.save(updated)
        let reloaded = HistoryStore(file: file)
        precondition(reloaded.items.first?.id == updated.id && reloaded.items.count == HistoryStore.limit, "History persistence failed")
        reloaded.delete(updated.id); precondition(HistoryStore(file: file).items.count == HistoryStore.limit - 1)
        reloaded.clear(); precondition(HistoryStore(file: file).items.isEmpty)
    }

    @MainActor static func checkMapLayout() {
        let home = "https://example.com/", next = "https://example.com/next"
        let items = [
            Discovery(id: UUID(), title: "Next", url: next + "#top", type: "Link", page: home),
            Discovery(id: UUID(), title: "Paper", url: "https://doi.org/10.1/x", type: "DOI", page: home),
            Discovery(id: UUID(), title: "Other", url: "https://other.org", type: "Link", page: next)
        ]
        let layout = MapLayout(discoveries: items, size: CGSize(width: 400, height: 400))
        precondition(layout.hubs.map(\.page) == [home, next] && layout.leaves.count == 3, "Map hubs failed")
        precondition(layout.paths.count == 1, "Explored link path missing")
        let target = layout.leaves[1].point
        precondition(layout.discovery(near: CGPoint(x: target.x + 3, y: target.y), tolerance: 10)?.title == "Paper")
        precondition(layout.discovery(near: .zero, tolerance: 10) == nil)
        precondition(MapLayout(discoveries: [], size: .zero).leaves.isEmpty)
        let quiet = MapLayout(discoveries: items, explored: [home, next, "https://example.com/login"], size: CGSize(width: 400, height: 400))
        precondition(quiet.hubs.count == 3 && quiet.paths.count == 1, "Explored pages without new links need a hub")
        let many = (0..<100).map { Discovery(id: UUID(), title: "\($0)", url: "https://e.com/\($0)", type: "Link", page: home) }
        precondition(MapLayout(discoveries: many, size: CGSize(width: 300, height: 300)).leaves.count == MapLayout.capacity)
    }
}

final class MemoryDefaults: UserDefaults {
    var values: [String: Any] = [:]
    override func object(forKey key: String) -> Any? { values[key] }
    override func string(forKey key: String) -> String? { values[key] as? String }
    override func double(forKey key: String) -> Double { values[key] as? Double ?? 0 }
    override func bool(forKey key: String) -> Bool { values[key] as? Bool ?? false }
    override func set(_ value: Any?, forKey key: String) { values[key] = value }
}
