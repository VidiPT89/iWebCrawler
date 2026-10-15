import SwiftUI
import WidgetKit

struct HistoryEntry: TimelineEntry {
    let date: Date
    let explorations: [Exploration]
    let portuguese: Bool
    func text(_ pt: String, _ en: String) -> String { portuguese ? pt : en }

    static func current() -> HistoryEntry {
        let saved = SharedStore.defaults?.string(forKey: "language")
        let portuguese = saved.map { $0 == "pt-PT" } ?? (Locale.preferredLanguages.first?.hasPrefix("pt") == true)
        return HistoryEntry(date: Date(), explorations: HistoryStore.load(), portuguese: portuguese)
    }
    static let sample: HistoryEntry = {
        func link(_ type: String) -> Discovery { Discovery(id: UUID(), title: type, url: "https://example.org", type: type, page: "https://en.wikipedia.org/wiki/Spider") }
        let wiki = Exploration(id: UUID(), date: Date().addingTimeInterval(-3_600), start: "https://en.wikipedia.org/wiki/Spider", pages: ["https://en.wikipedia.org/wiki/Spider"],
                               discoveries: [link("DOI"), link("PMID"), link("Link"), link("Link")])
        let quotes = Exploration(id: UUID(), date: Date().addingTimeInterval(-86_400), start: "https://quotes.toscrape.com", pages: [], discoveries: [link("Link")])
        return HistoryEntry(date: Date(), explorations: [wiki, quotes], portuguese: Locale.preferredLanguages.first?.hasPrefix("pt") == true)
    }()
}

struct HistoryProvider: TimelineProvider {
    func placeholder(in context: Context) -> HistoryEntry { .sample }
    func getSnapshot(in context: Context, completion: @escaping (HistoryEntry) -> Void) {
        let entry = HistoryEntry.current()
        completion(context.isPreview && entry.explorations.isEmpty ? .sample : entry)
    }
    // The app reloads the widget whenever the history or the language changes; the hourly refresh is only a safety net.
    func getTimeline(in context: Context, completion: @escaping (Timeline<HistoryEntry>) -> Void) {
        completion(Timeline(entries: [.current()], policy: .after(Date().addingTimeInterval(3_600))))
    }
}

private enum WidgetLink {
    static let history = URL(string: "iwebcrawler://history")!
    static func open(_ item: Exploration) -> URL { URL(string: "iwebcrawler://history/\(item.id.uuidString)")! }
}

private let widgetBackground = LinearGradient(colors: [Color(red: 0.07, green: 0.06, blue: 0.05), Color(red: 0.02, green: 0.02, blue: 0.04)], startPoint: .top, endPoint: .bottom)

struct HistoryWidgetView: View {
    @Environment(\.widgetFamily) private var systemFamily
    let entry: HistoryEntry
    /// Lets previews and snapshot checks render a given size outside the widget host.
    var forcedFamily: WidgetFamily? = nil
    private var family: WidgetFamily { forcedFamily ?? systemFamily }

    var body: some View {
        content
            .environment(\.locale, Locale(identifier: entry.portuguese ? "pt-PT" : "en"))
            .containerBackground(for: .widget) { if family == .systemSmall || family == .systemMedium { widgetBackground } else { Color.clear } }
    }

    @ViewBuilder private var content: some View {
        switch family {
        case .systemMedium: medium
        case .accessoryRectangular: rectangular
        case .accessoryCircular: circular
        default: small
        }
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                logo(38)
                Spacer()
                if !entry.explorations.isEmpty { count(entry.explorations.count) }
            }
            Spacer(minLength: 6)
            if let last = entry.explorations.first {
                Text(last.host).font(.system(.subheadline, design: .rounded, weight: .semibold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.75)
                Text(summary(last)).font(.caption2).foregroundStyle(Brand.gold)
                Text(ago(last.date)).font(.caption2).foregroundStyle(.white.opacity(0.55)).lineLimit(1)
            } else {
                emptyText
            }
        }
        .widgetURL(entry.explorations.first.map(WidgetLink.open) ?? WidgetLink.history)
    }

    private var medium: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                logo(46)
                Spacer(minLength: 4)
                Text("iWebCrawler").font(.system(.headline, design: .rounded, weight: .semibold)).foregroundStyle(.white).lineLimit(1).minimumScaleFactor(0.7)
                Text(entry.text("Explorações", "Explorations")).font(.caption2).foregroundStyle(.white.opacity(0.55))
            }.frame(width: 104, alignment: .leading)
            if entry.explorations.isEmpty {
                emptyText.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entry.explorations.prefix(3).enumerated()), id: \.element.id) { index, item in
                        Link(destination: WidgetLink.open(item)) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.host).font(.system(.footnote, design: .rounded, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                                HStack(spacing: 4) {
                                    Text(summary(item)).foregroundStyle(Brand.gold)
                                    Text("·").foregroundStyle(.white.opacity(0.35))
                                    Text(ago(item.date)).foregroundStyle(.white.opacity(0.55)).lineLimit(1)
                                }.font(.caption2)
                            }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 6)
                        }
                        if index < min(entry.explorations.count, 3) - 1 { Divider().overlay(Color.white.opacity(0.12)) }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .widgetURL(WidgetLink.history)
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("iWebCrawler").font(.headline).widgetAccentable()
            if let last = entry.explorations.first {
                Text(last.host).font(.caption).lineLimit(1)
                Text(summary(last)).font(.caption2).foregroundStyle(.secondary)
            } else {
                Text(entry.text("Sem explorações", "No explorations")).font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .widgetURL(entry.explorations.first.map(WidgetLink.open) ?? WidgetLink.history)
    }

    private var circular: some View {
        ZStack {
            AccessoryWidgetBackground()
            Image("Logo").resizable().scaledToFit().padding(5).widgetAccentable()
        }
        .widgetURL(WidgetLink.history)
        .accessibilityLabel("iWebCrawler")
    }

    private var emptyText: some View {
        Text(entry.text("Explora um site na app: a última exploração aparece aqui.", "Explore a website in the app: your latest exploration appears here."))
            .font(.caption).foregroundStyle(.white.opacity(0.75)).lineLimit(4)
    }
    private func logo(_ size: CGFloat) -> some View {
        Image("Logo").resizable().interpolation(.high).frame(width: size, height: size)
            .shadow(color: Brand.orange.opacity(0.5), radius: size * 0.18)
            .accessibilityHidden(true)
    }
    private func count(_ value: Int) -> some View {
        Text("\(value)").font(.system(.caption, design: .rounded, weight: .bold)).foregroundStyle(.black)
            .padding(.horizontal, 7).padding(.vertical, 3).background(Brand.gradient, in: Capsule())
            .accessibilityLabel(entry.text("\(value) explorações", "\(value) explorations"))
    }
    /// "há 2 h" / "2 hr. ago", refreshed by the hourly timeline and whenever the app saves.
    private func ago(_ date: Date) -> String {
        date.formatted(.relative(presentation: .named, unitsStyle: .abbreviated).locale(Locale(identifier: entry.portuguese ? "pt-PT" : "en")))
    }
    private func summary(_ item: Exploration) -> String {
        let links = item.discoveries.count, refs = item.referenceCount
        let linkWord = links == 1 ? entry.text("ligação", "link") : entry.text("ligações", "links")
        let refWord = refs == 1 ? entry.text("ref.", "ref.") : entry.text("refs.", "refs.")
        return "\(links) \(linkWord) · \(refs) \(refWord)"
    }
}

struct HistoryWidget: Widget {
    var body: some WidgetConfiguration {
        let entry = HistoryEntry.current()
        return StaticConfiguration(kind: "iWebCrawlerHistory", provider: HistoryProvider()) { HistoryWidgetView(entry: $0) }
            .configurationDisplayName(entry.text("Explorações", "Explorations"))
            .description(entry.text("As tuas explorações mais recentes. Toca para reabrir e continuar.", "Your latest explorations. Tap to reopen and continue."))
            .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular])
    }
}
