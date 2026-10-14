import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case portuguese = "pt-PT", english = "en"
    var id: String { rawValue }
    var title: String { self == .portuguese ? "Português (Portugal)" : "English" }
}

enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var scheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
}

@MainActor
final class Preferences: ObservableObject {
    static let shared = Preferences()
    private let defaults: UserDefaults
    @Published var language: AppLanguage { didSet { defaults.set(language.rawValue, forKey: "language") } }
    @Published var appearance: AppAppearance { didSet { defaults.set(appearance.rawValue, forKey: "appearance") } }
    @Published var speed: Double { didSet { defaults.set(speed, forKey: "speed") } }
    @Published var followLinks: Bool { didSet { defaults.set(followLinks, forKey: "followLinks") } }
    @Published var pageLimit: Int { didSet { defaults.set(pageLimit, forKey: "pageLimit") } }
    @Published var reducedMotion: Bool { didSet { defaults.set(reducedMotion, forKey: "reducedMotion") } }
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let initial = Locale.preferredLanguages.first?.hasPrefix("pt") == true ? AppLanguage.portuguese : .english
        language = defaults.string(forKey: "language").flatMap(AppLanguage.init(rawValue:)) ?? initial
        appearance = defaults.string(forKey: "appearance").flatMap(AppAppearance.init(rawValue:)) ?? .system
        let savedSpeed = defaults.double(forKey: "speed")
        speed = [0.5, 1, 2, 4].contains(savedSpeed) ? savedSpeed : 1
        followLinks = defaults.bool(forKey: "followLinks")
        pageLimit = min(20, max(1, defaults.object(forKey: "pageLimit") as? Int ?? 5))
        reducedMotion = defaults.bool(forKey: "reducedMotion")
    }
    func text(_ pt: String, _ en: String) -> String { language == .portuguese ? pt : en }
}

enum Brand {
    static let orange = Color(red: 0.93, green: 0.40, blue: 0.12)
    static let amber = Color(red: 0.85, green: 0.47, blue: 0.024)
    static let gold = Color(red: 0.98, green: 0.75, blue: 0.14)
    static let gradient = LinearGradient(colors: [gold, orange], startPoint: .topLeading, endPoint: .bottomTrailing)
    static func background(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color(red: 0.045, green: 0.043, blue: 0.041) : Color(red: 0.96, green: 0.945, blue: 0.92) }
    static func surface(_ scheme: ColorScheme) -> Color { scheme == .dark ? Color(red: 0.085, green: 0.08, blue: 0.07) : Color(red: 0.995, green: 0.985, blue: 0.965) }
    static func accent(_ scheme: ColorScheme) -> Color { scheme == .dark ? gold : Color(red: 0.64, green: 0.28, blue: 0.035) }
}
