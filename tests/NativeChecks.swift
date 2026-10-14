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
        print("Native checks passed: URL validation, locale selection, appearance mapping, preference restoration and bounds.")
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
