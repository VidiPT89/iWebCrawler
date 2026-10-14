import SwiftUI

struct DiscoveriesView: View {
    @ObservedObject var model: CrawlerModel
    @EnvironmentObject private var prefs: Preferences
    @Environment(\.colorScheme) private var scheme
    var compact = false
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(prefs.text("Descobertas", "Discoveries")).font(.system(.title3, design: .rounded, weight: .semibold))
                Spacer()
                Text(String(model.discoveries.count)).font(.caption.monospacedDigit()).foregroundStyle(Brand.accent(scheme)).padding(7).background(Brand.amber.opacity(0.12), in: RoundedRectangle(cornerRadius: 6))
            }.padding(20)
            if !model.discoveries.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField(prefs.text("Filtrar descobertas…", "Filter discoveries…"), text: $model.search).textFieldStyle(.plain)
                }.padding(10).background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 8)).padding(.horizontal, 20)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(["All", "DOI", "PMID", "ISBN", "Bibcode", "Link"], id: \.self) { type in
                            Button { model.filter = type } label: {
                                Text(type == "All" ? prefs.text("Tudo", "All") : type).font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .padding(.horizontal, 10).padding(.vertical, 7)
                                    .background(model.filter == type ? Brand.amber.opacity(0.22) : .clear, in: RoundedRectangle(cornerRadius: 6))
                                    .foregroundStyle(model.filter == type ? Brand.accent(scheme) : .secondary)
                            }.buttonStyle(.plain).accessibilityAddTraits(model.filter == type ? .isSelected : [])
                        }
                    }
                }.padding(.horizontal, 20).padding(.vertical, 12)
            }
            if model.discoveries.isEmpty {
                Spacer()
                VStack(alignment: .leading, spacing: 14) {
                    Image(systemName: "point.3.connected.trianglepath.dotted").font(.system(size: 32, weight: .ultraLight)).foregroundStyle(Brand.accent(scheme))
                    Text(prefs.text("Os caminhos\naparecem aqui.", "The paths\nappear here.")).font(.system(.title2, design: .serif))
                    Text(prefs.text("Inicia uma exploração. Cada ligação encontrada passa a fazer parte da tua coleção.", "Start exploring. Every link you find becomes part of your collection.")).font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)
                }.padding(24)
                Spacer()
            } else if model.filtered.isEmpty {
                ContentUnavailableView(prefs.text("Sem resultados", "No results"), systemImage: "magnifyingglass", description: Text(prefs.text("Nenhuma descoberta corresponde a “\(model.search)”.", "No discoveries match “\(model.search)”.")))
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(model.filtered.reversed()) { item in
                            Button { model.selectedDiscovery = item } label: {
                            VStack(alignment: .leading, spacing: 7) {
                                HStack {
                                    Text(item.type.uppercased()).font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1).foregroundStyle(Brand.accent(scheme))
                                    Spacer()
                                    Image(systemName: "arrow.up.right").font(.system(size: 10)).foregroundStyle(.tertiary)
                                }
                                Text(item.title).font(.system(size: 13, weight: .medium)).lineLimit(2)
                                Text(item.host).font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary).lineLimit(1)
                            }.padding(.vertical, 15).padding(.horizontal, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Brand.surface(scheme))
                            }.buttonStyle(.plain)
                                .contextMenu {
                                    ShareLink(prefs.text("Partilhar ligação", "Share link"), item: item.url)
                                    Button(prefs.text("Explorar este endereço", "Explore this address")) { model.explore(item.url) }
                                }
                            Divider().padding(.horizontal, 20)
                        }
                    }
                }
            }
            Divider()
            VStack(spacing: 8) {
                if let url = model.exportURL {
                    ShareLink(item: url) { Label(prefs.text("Guardar / partilhar JSON", "Save / share JSON"), systemImage: "square.and.arrow.up") }
                        .buttonStyle(.borderedProminent).tint(Brand.amber)
                } else {
                    Button { model.pause(); model.prepareExport() } label: { Label(prefs.text("Exportar coleção", "Export collection"), systemImage: "square.and.arrow.up") }
                        .buttonStyle(.bordered).disabled(model.discoveries.isEmpty)
                }
                Text(prefs.text("Só nesta sessão. Exporta para guardar.", "Session only. Export to keep your collection.")).font(.system(size: 9)).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity).padding(16)
        }.background(Brand.surface(scheme))
    }
}

struct ConnectionMap: View {
    @ObservedObject var model: CrawlerModel
    @EnvironmentObject private var prefs: Preferences
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduce
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(prefs.text("Uma página. Muitos caminhos.", "One page. Many paths.")).font(.system(.title2, design: .serif))
                    Text(prefs.text("As últimas 32 ligações, agrupadas pela página de origem.", "The latest 32 links, grouped by their source page.")).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "point.3.connected.trianglepath.dotted").foregroundStyle(Brand.accent(scheme))
            }.padding(24)
            TimelineView(.animation(minimumInterval: 1 / 24, paused: !model.running || reduce || prefs.reducedMotion)) { timeline in
                Canvas { context, size in
                    let entries = Array(model.discoveries.suffix(32)), pages = Array(Set(entries.map(\.page))).sorted()
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = max(30, min(size.width, size.height) * 0.34)
                    for r in [0.5, 0.85, 1.2] {
                        context.stroke(Path(ellipseIn: CGRect(x: center.x - radius * r, y: center.y - radius * r, width: radius * r * 2, height: radius * r * 2)), with: .color(Brand.amber.opacity(0.13)), style: StrokeStyle(lineWidth: 1, dash: [2, 6]))
                    }
                    for (i, entry) in entries.enumerated() {
                        let angle = Double(i) * .pi * 2 / Double(max(1, entries.count)) - .pi / 2
                        let p = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
                        let pageIndex = pages.firstIndex(of: entry.page) ?? 0
                        let sourceAngle = Double(pageIndex) * .pi * 2 / Double(max(1, pages.count))
                        let source = pages.count <= 1 ? center : CGPoint(x: center.x + cos(sourceAngle) * radius * 0.28, y: center.y + sin(sourceAngle) * radius * 0.28)
                        var line = Path(); line.move(to: source); line.addLine(to: p)
                        context.stroke(line, with: .color(Brand.amber.opacity(0.35)), lineWidth: 1)
                        if model.running && !reduce && !prefs.reducedMotion {
                            let fraction = (timeline.date.timeIntervalSinceReferenceDate * 0.32 + Double(i) * 0.12).truncatingRemainder(dividingBy: 1)
                            let moving = CGPoint(x: source.x + (p.x - source.x) * fraction, y: source.y + (p.y - source.y) * fraction)
                            context.fill(Path(ellipseIn: CGRect(x: moving.x - 2, y: moving.y - 2, width: 4, height: 4)), with: .color(Brand.orange))
                        }
                        context.fill(Path(ellipseIn: CGRect(x: source.x - 5, y: source.y - 5, width: 10, height: 10)), with: .color(Brand.amber))
                        context.fill(Path(ellipseIn: CGRect(x: p.x - 4, y: p.y - 4, width: 8, height: 8)), with: .color(entry.type == "Link" ? Brand.amber : Brand.orange))
                        if entries.count <= 12 || i.isMultiple(of: 3) {
                            let label = String(entry.host.prefix(19))
                            context.draw(Text(label).font(.system(size: 9, design: .monospaced)).foregroundStyle(Brand.accent(scheme)), at: CGPoint(x: p.x, y: p.y + 17))
                        }
                    }
                }
            }.overlay {
                if model.discoveries.isEmpty {
                    VStack(spacing: 12) { SpiderMark(size: 60); Text(prefs.text("A tua teia começa com uma ligação.", "Your web begins with one link.")).font(.caption).foregroundStyle(.secondary) }
                }
            }.accessibilityElement(children: .ignore).accessibilityLabel(prefs.text("Mapa das ligações descobertas", "Map of discovered links")).accessibilityValue("\(model.discoveries.count)")
            HStack(spacing: 16) {
                Label(prefs.text("Página de origem", "Source page"), systemImage: "circle.fill")
                Label(prefs.text("Ligação descoberta", "Discovered link"), systemImage: "smallcircle.filled.circle")
            }.font(.system(size: 10, design: .monospaced)).foregroundStyle(.secondary).padding(24)
        }.background(Brand.surface(scheme))
    }
}

struct DiscoveryDetail: View {
    let item: Discovery
    @ObservedObject var model: CrawlerModel
    @EnvironmentObject private var prefs: Preferences
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(item.type.uppercased()).font(.caption.monospaced()).foregroundStyle(Brand.amber)
                    Text(item.title).font(.system(.title2, design: .serif))
                    Text(item.url).font(.callout.monospaced()).textSelection(.enabled)
                    Divider()
                    Text(prefs.text("Encontrado em", "Found on")).font(.caption).foregroundStyle(.secondary)
                    Text(item.page).font(.caption.monospaced()).textSelection(.enabled)
                    HStack {
                        ShareLink(prefs.text("Partilhar", "Share"), item: item.url).buttonStyle(.bordered)
                        Button(prefs.text("Explorar endereço", "Explore address")) {
                            model.explore(item.url)
                        }.buttonStyle(ActionButtonStyle())
                    }
                }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(prefs.text("Ligação", "Link"))
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(prefs.text("Fechar", "Close")) { model.selectedDiscovery = nil } } }
        }
        #if os(macOS)
        .frame(width: 560, height: 440)
        #endif
    }
}
