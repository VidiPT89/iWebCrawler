import SwiftUI

struct DiscoveriesView: View {
    @ObservedObject var model: CrawlerModel
    @EnvironmentObject private var prefs: Preferences
    @Environment(\.colorScheme) private var scheme
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
                    HStack(spacing: 4) {
                        ForEach(model.availableFilters, id: \.self) { type in
                            Button { model.filter = type } label: {
                                Text(type == "All" ? prefs.text("Tudo", "All") : type == "Broken" ? prefs.text("Partidas", "Broken") : type).font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .padding(.horizontal, 8).padding(.vertical, 7)
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
                                    HealthBadge(health: item.health, status: item.status)
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
                if !model.discoveries.isEmpty {
                    Button { model.checkLinks() } label: {
                        Label(model.checking ? prefs.text("A verificar \(model.checkedCount) / \(model.checkTotal) · Parar", "Checking \(model.checkedCount) / \(model.checkTotal) · Stop") : prefs.text("Verificar ligações", "Check links"), systemImage: model.checking ? "stop.circle" : "checkmark.shield")
                    }.buttonStyle(.bordered).disabled(!model.checking && !model.discoveries.contains { $0.status == nil })
                }
                if model.exportFiles.count == 2 {
                    HStack {
                        ShareLink(item: model.exportFiles[0]) { Label("JSON", systemImage: "curlybraces") }
                        ShareLink(item: model.exportFiles[1]) { Label("CSV", systemImage: "tablecells") }
                    }.buttonStyle(.borderedProminent).tint(Brand.amber)
                } else {
                    Button { model.pause(); model.prepareExport() } label: { Label(prefs.text("Exportar coleção", "Export collection"), systemImage: "square.and.arrow.up") }
                        .buttonStyle(.bordered).disabled(model.discoveries.isEmpty)
                }
                Text(model.isDemo ? prefs.text("A demonstração não é guardada no histórico.", "The demonstration is not saved to your history.") : prefs.text("Guardada no histórico deste dispositivo.", "Saved to this device’s history.")).font(.system(size: 9)).foregroundStyle(.secondary)
            }.frame(maxWidth: .infinity).padding(16)
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
                    if item.health != .unchecked { HealthBadge(health: item.health, status: item.status, detailed: true) }
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

struct HealthBadge: View {
    let health: LinkHealth
    let status: Int?
    var detailed = false
    @EnvironmentObject private var prefs: Preferences
    var body: some View {
        if health != .unchecked {
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(detailed ? description : short).font(.system(size: detailed ? 11 : 9, weight: .medium, design: .monospaced))
            }.foregroundStyle(health.isProblem ? Brand.broken : .secondary)
            .accessibilityElement(children: .combine)
        }
    }
    private var color: Color {
        switch health { case .ok: .green; case .redirected, .restricted: Brand.amber; case .broken, .unreachable: Brand.broken; case .skipped, .unchecked: .gray }
    }
    private var short: String {
        switch health { case .unreachable: prefs.text("SEM RESPOSTA", "NO RESPONSE"); case .skipped: "HTTP"; default: status.map(String.init) ?? "" }
    }
    private var description: String {
        switch health {
        case .ok: prefs.text("Disponível", "Available") + " · \(status ?? 0)"
        case .redirected: prefs.text("Redireciona", "Redirects") + " · \(status ?? 0)"
        case .restricted: prefs.text("Acesso restrito a verificações automáticas", "Restricted for automated checks") + " · \(status ?? 0)"
        case .broken: prefs.text("Partida", "Broken") + " · \(status ?? 0)"
        case .unreachable: prefs.text("Sem resposta do servidor", "No response from the server")
        case .skipped: prefs.text("Não verificada: ligação HTTP sem encriptação", "Not checked: unencrypted HTTP link")
        case .unchecked: ""
        }
    }
}
