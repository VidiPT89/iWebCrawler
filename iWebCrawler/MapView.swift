import SwiftUI

struct ConnectionMap: View {
    @ObservedObject var model: CrawlerModel
    @EnvironmentObject private var prefs: Preferences
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduce
    @State private var scale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var gestureScale: CGFloat = 1
    @State private var gestureOffset: CGSize = .zero
    private var zoom: CGFloat { min(4, max(0.6, scale * gestureScale)) }
    private var shift: CGSize { CGSize(width: offset.width + gestureOffset.width, height: offset.height + gestureOffset.height) }
    private var moving: Bool { model.running && !reduce && !prefs.reducedMotion }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            GeometryReader { geometry in
                let layout = MapLayout(discoveries: model.discoveries, explored: model.exploredPages, size: geometry.size)
                let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                let place = { (p: CGPoint) in CGPoint(x: center.x + (p.x - center.x) * zoom + shift.width, y: center.y + (p.y - center.y) * zoom + shift.height) }
                TimelineView(.animation(minimumInterval: 1 / 24, paused: !moving)) { timeline in
                    Canvas { context, size in draw(layout, in: &context, place: place, time: timeline.date.timeIntervalSinceReferenceDate) }
                }
                .contentShape(Rectangle())
                .gesture(SpatialTapGesture().onEnded { tap in
                    if let item = layout.discovery(near: tap.location, tolerance: 18, transform: place) { model.selectedDiscovery = item }
                })
                .gesture(DragGesture(minimumDistance: 6).onChanged { gestureOffset = $0.translation }.onEnded { value in
                    offset.width += value.translation.width; offset.height += value.translation.height; gestureOffset = .zero
                })
                .simultaneousGesture(MagnifyGesture().onChanged { gestureScale = $0.magnification }.onEnded { value in
                    scale = min(4, max(0.6, scale * value.magnification)); gestureScale = 1
                })
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(prefs.text("Mapa das ligações descobertas", "Map of discovered links"))
                .accessibilityValue(prefs.text("\(model.discoveries.count) ligações em \(model.pageCount) páginas", "\(model.discoveries.count) links across \(model.pageCount) pages"))
            }
            .clipped()
            .overlay {
                if model.discoveries.isEmpty {
                    VStack(spacing: 12) { SpiderMark(size: 60); Text(prefs.text("A tua teia começa com uma ligação.", "Your web begins with one link.")).font(.caption).foregroundStyle(.secondary) }
                }
            }
            legend
        }.background(Brand.surface(scheme))
    }

    private var header: some View {
        let pages = model.isDemo ? 1 : model.pageCount
        return HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text(pages > 1 ? prefs.text("\(pages) páginas. Muitos caminhos.", "\(pages) pages. Many paths.") : prefs.text("Uma página. Muitos caminhos.", "One page. Many paths.")).font(.system(.title2, design: .serif))
                Text(prefs.text("As últimas 60 ligações, ligadas à página onde foram encontradas. Toca num ponto para ver os detalhes.", "The latest 60 links, connected to the page where they were found. Tap a point for details.")).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if model.discoveries.isEmpty { Image(systemName: "point.3.connected.trianglepath.dotted").foregroundStyle(Brand.accent(scheme)) } else { zoomControls }
        }.padding(24)
    }

    private var zoomControls: some View {
        HStack(spacing: 2) {
            zoomButton("minus", prefs.text("Afastar", "Zoom out")) { scale = max(0.6, scale / 1.4) }
            zoomButton("plus", prefs.text("Aproximar", "Zoom in")) { scale = min(4, scale * 1.4) }
            if scale != 1 || offset != .zero {
                zoomButton("arrow.counterclockwise", prefs.text("Repor vista", "Reset view")) { scale = 1; offset = .zero }
            }
        }.padding(4).background(.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 9))
    }
    private func zoomButton(_ icon: String, _ label: String, action: @escaping () -> Void) -> some View {
        Button { withAnimation(reduce || prefs.reducedMotion ? nil : .easeOut(duration: 0.25)) { action() } } label: {
            Image(systemName: icon).font(.system(size: 12, weight: .semibold)).frame(width: 30, height: 28).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(label)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            Label { Text(prefs.text("Página explorada", "Explored page")) } icon: { Image(systemName: "circle.fill").foregroundStyle(Brand.amber) }
            Label { Text(prefs.text("Referência", "Reference")) } icon: { Image(systemName: "circle.fill").foregroundStyle(Brand.orange) }
            Label { Text(prefs.text("Ligação", "Link")) } icon: { Image(systemName: "circle").foregroundStyle(Brand.amber) }
            if model.problemCount > 0 { Label { Text(prefs.text("Partida", "Broken")) } icon: { Image(systemName: "circle.fill").foregroundStyle(Brand.broken) } }
        }.font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary).padding(24)
    }

    private func draw(_ layout: MapLayout, in context: inout GraphicsContext, place: (CGPoint) -> CGPoint, time: Double) {
        let center = place(CGPoint(x: context.clipBoundingRect.midX, y: context.clipBoundingRect.midY))
        let radius = max(40, min(context.clipBoundingRect.width, context.clipBoundingRect.height) * 0.4) * zoom
        for ring in [0.32, 0.84, 1.0] {
            let r = radius * ring
            context.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)), with: .color(Brand.amber.opacity(0.12)), style: StrokeStyle(lineWidth: 1, dash: [2, 6]))
        }
        for (i, leaf) in layout.leaves.enumerated() {
            let hub = place(leaf.hub), point = place(leaf.point)
            var line = Path(); line.move(to: hub); line.addLine(to: point)
            context.stroke(line, with: .color(Brand.amber.opacity(0.3)), lineWidth: 1)
            if moving {
                let fraction = (time * 0.32 + Double(i) * 0.12).truncatingRemainder(dividingBy: 1)
                let dot = CGPoint(x: hub.x + (point.x - hub.x) * fraction, y: hub.y + (point.y - hub.y) * fraction)
                context.fill(Path(ellipseIn: CGRect(x: dot.x - 2, y: dot.y - 2, width: 4, height: 4)), with: .color(Brand.orange))
            }
        }
        for path in layout.paths {
            var line = Path(); line.move(to: place(path.from)); line.addLine(to: place(path.to))
            context.stroke(line, with: .color(Brand.orange.opacity(0.8)), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 4]))
        }
        let showAll = layout.leaves.count <= 24 || zoom >= 1.6
        for (i, leaf) in layout.leaves.enumerated() {
            let p = place(leaf.point), node = Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8))
            if leaf.discovery.health.isProblem { context.fill(node, with: .color(Brand.broken)) }
            else if leaf.discovery.type == "Link" { context.stroke(node, with: .color(Brand.amber), lineWidth: 1.5) }
            else { context.fill(node, with: .color(Brand.orange)) }
            if showAll || i.isMultiple(of: 3) {
                context.draw(Text(Self.shortLabel(leaf.discovery)).font(.system(size: 9, design: .monospaced)).foregroundStyle(Brand.accent(scheme)), at: CGPoint(x: p.x, y: p.y + 15))
            }
        }
        for hub in layout.hubs {
            let p = place(hub.point)
            context.fill(Path(ellipseIn: CGRect(x: p.x - 6, y: p.y - 6, width: 12, height: 12)), with: .color(Brand.amber))
            if layout.hubs.count > 1 {
                context.draw(Text(Self.shortPage(hub.page)).font(.system(size: 9, weight: .semibold, design: .monospaced)).foregroundStyle(.primary), at: CGPoint(x: p.x, y: p.y - 15))
            }
        }
    }

    /// A link's title says more than its host, which repeats for every link inside one website.
    static func shortLabel(_ item: Discovery) -> String {
        let host = item.host.hasPrefix("www.") ? String(item.host.dropFirst(4)) : item.host
        let text = item.title.isEmpty ? host : item.title
        return text.count > 20 ? text.prefix(19) + "…" : text
    }
    static func shortPage(_ page: String) -> String {
        guard let url = URL(string: page) else { return String(page.prefix(22)) }
        let name = url.lastPathComponent.isEmpty || url.lastPathComponent == "/" ? (url.host ?? page) : "/" + url.lastPathComponent
        return name.count > 22 ? name.prefix(21) + "…" : name
    }
}
