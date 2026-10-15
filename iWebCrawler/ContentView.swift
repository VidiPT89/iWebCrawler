import SwiftUI
import WebKit

struct ContentView: View {
    @StateObject private var model = CrawlerModel()
    @StateObject private var prefs = Preferences.shared
    @Environment(\.colorScheme) private var systemScheme
    @Environment(\.accessibilityReduceMotion) private var reduce
    @Environment(\.scenePhase) private var scenePhase
    private var scheme: ColorScheme { prefs.appearance.scheme ?? systemScheme }
    var body: some View {
        ZStack {
            GeometryReader { geometry in
                let wide = geometry.size.width >= 940
                VStack(spacing: 0) {
                    header(wide: wide)
                    addressBar.padding(.horizontal, wide ? 28 : 16).padding(.bottom, 18)
                    if let error = model.error {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.circle").foregroundStyle(Brand.orange)
                            Text(error).font(.caption)
                            Spacer()
                            Button { model.error = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain).accessibilityLabel(prefs.text("Fechar aviso", "Dismiss message"))
                        }.padding(14).background(Brand.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10)).padding(.horizontal, wide ? 28 : 16).padding(.bottom, 12)
                    }
                    HStack(spacing: 16) {
                        VStack(spacing: 0) {
                            workspaceToolbar(wide: wide)
                            ZStack {
                                WebSurface(webView: model.webView)
                                    .frame(width: model.tab == 0 ? nil : 0, height: model.tab == 0 ? nil : 0)
                                    .opacity(model.tab == 0 ? 1 : 0).allowsHitTesting(model.tab == 0).accessibilityHidden(model.tab != 0)
                                if model.tab == 1 { ConnectionMap(model: model) }
                                if model.tab == 2 { DiscoveriesView(model: model) }
                                if model.phase == .loading && model.tab == 0 {
                                    VStack(spacing: 16) {
                                        ProgressView().tint(Brand.amber)
                                        Text(prefs.text("A preparar um novo caminho…", "Preparing a new path…")).font(.caption).foregroundStyle(.secondary)
                                    }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Brand.surface(scheme))
                                }
                            }
                        }.background(Brand.surface(scheme)).clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(.primary.opacity(0.07)))
                        if wide && model.tab != 2 {
                            DiscoveriesView(model: model).frame(width: 320).clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(.primary.opacity(0.07)))
                        }
                    }.padding(.horizontal, wide ? 28 : 12)
                    controlBar(wide: wide)
                }
            }
            .accessibilityHidden(model.showSplash)
            .allowsHitTesting(!model.showSplash)
            if model.showSplash {
                SplashView { dismissSplash() }.transition(.opacity).zIndex(2)
                    .task {
                        try? await Task.sleep(for: .seconds(2.8))
                        guard !Task.isCancelled else { return }
                        dismissSplash()
                    }
            }
        }
        .background(Brand.background(scheme))
        .environmentObject(prefs)
        .environment(\.locale, Locale(identifier: prefs.language.rawValue))
        .preferredColorScheme(prefs.appearance.scheme)
        .tint(Brand.accent(scheme))
        .sheet(isPresented: $model.showSettings) { SettingsView(model: model).environmentObject(prefs).environment(\.locale, Locale(identifier: prefs.language.rawValue)) }
        .sheet(isPresented: $model.showHistory) { HistoryView(model: model, history: model.history).environmentObject(prefs).preferredColorScheme(prefs.appearance.scheme) }
        .sheet(item: $model.selectedDiscovery) { item in
            DiscoveryDetail(item: item, model: model).environmentObject(prefs).preferredColorScheme(prefs.appearance.scheme)
        }
        .onChange(of: scheme) { _, _ in model.configure(dark: scheme == .dark) }
        .onChange(of: prefs.language) { _, _ in model.configure(dark: scheme == .dark) }
        .onChange(of: prefs.speed) { _, _ in model.configure(dark: scheme == .dark) }
        .onChange(of: prefs.reducedMotion) { _, _ in model.configure(dark: scheme == .dark) }
        .onChange(of: scenePhase) { _, phase in if phase != .active { model.pause() } }
        .onAppear { model.configure(dark: scheme == .dark) }
        .onOpenURL { model.open($0) }
        #if os(iOS)
        .sensoryFeedback(.impact(weight: .light), trigger: model.referenceCount) { old, new in new > old && !prefs.reducedMotion }
        #endif
        #if os(macOS)
        .frame(minWidth: 650, minHeight: 600)
        #endif
    }
    private func dismissSplash() {
        withAnimation(reduce || prefs.reducedMotion ? nil : .easeOut(duration: 0.55)) { model.showSplash = false }
    }
    private func header(wide: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            LogoMark(size: wide ? 48 : 36)
            VStack(alignment: .leading, spacing: 4) {
                Text("iWebCrawler").font(.system(size: wide ? 27 : 21, weight: .semibold, design: .rounded)).tracking(-0.8)
                if wide { Text(prefs.text("EXPLORA. LIGA. DESCOBRE.", "EXPLORE. CONNECT. DISCOVER.")).font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(2.4).foregroundStyle(.secondary) }
            }
            Spacer()
            Button { model.showDemo() } label: {
                Label(prefs.text("Demonstração", "Demo"), systemImage: "sparkle").font(.caption.weight(.medium)).lineLimit(1)
                    .labelStyle(AdaptiveLabelStyle(iconOnly: !wide))
            }.buttonStyle(.bordered).controlSize(.small).accessibilityLabel(prefs.text("Demonstração", "Demo"))
            Button { model.showHistory = true } label: { Image(systemName: "clock.arrow.circlepath").font(.system(size: 17, weight: .regular)).frame(width: 34, height: 34) }
                .buttonStyle(.plain).accessibilityLabel(prefs.text("Histórico", "History")).keyboardShortcut("y", modifiers: .command)
            Button { model.showSettings = true } label: { Image(systemName: "gearshape").font(.system(size: 17, weight: .regular)).frame(width: 34, height: 34) }
                .buttonStyle(.plain).accessibilityLabel(prefs.text("Definições", "Settings")).accessibilityIdentifier("settings.open")
                .keyboardShortcut(",", modifiers: .command)
        }.padding(.horizontal, wide ? 28 : 16).padding(.top, wide ? 24 : 16).padding(.bottom, wide ? 24 : 16)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
    private var addressBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "globe").font(.system(size: 17, weight: .light)).foregroundStyle(Brand.accent(scheme))
            TextField(prefs.text("Introduz um endereço…", "Enter a web address…"), text: $model.address)
                .font(.system(size: 13, design: .monospaced)).textFieldStyle(.plain).autocorrectionDisabled()
                .accessibilityIdentifier("address.input").onSubmit { model.load() }
                #if os(iOS)
                .textInputAutocapitalization(.never).keyboardType(.URL).submitLabel(.go)
                #endif
            Button { model.load() } label: { Image(systemName: "arrow.right").font(.system(size: 14, weight: .semibold)).frame(width: 32, height: 30).background(Brand.amber.opacity(0.15), in: RoundedRectangle(cornerRadius: 7)) }
                .buttonStyle(.plain).accessibilityLabel(prefs.text("Abrir endereço", "Open address"))
        }.padding(12).background(Brand.surface(scheme), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.primary.opacity(0.09)))
    }
    private func workspaceToolbar(wide: Bool) -> some View {
        HStack(spacing: 14) {
            Picker(prefs.text("Vista", "View"), selection: $model.tab) {
                Text(prefs.text("Página", "Page")).tag(0)
                Text(prefs.text("Mapa", "Map")).tag(1)
                Text(prefs.text("Descobertas", "Discoveries")).tag(2)
            }.pickerStyle(.segmented).labelsHidden().frame(maxWidth: wide ? 300 : .infinity).accessibilityIdentifier("workspace.tabs")
            if wide {
                Spacer()
                Text(model.isDemo ? prefs.text("COLEÇÃO LOCAL", "LOCAL COLLECTION") : (model.webView.url?.host ?? "WEB"))
                    .font(.system(size: 9, design: .monospaced)).tracking(1).foregroundStyle(.secondary).lineLimit(1)
            }
        }.padding(12).background(.primary.opacity(0.025))
    }
    private func controlBar(wide: Bool) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: wide ? 30 : 16) {
                metric(model.pageCount, prefs.text("página", "page"), prefs.text("páginas", "pages"))
                metric(model.discoveries.count, prefs.text("ligação", "link"), prefs.text("ligações", "links"))
                if wide { metric(model.referenceCount, prefs.text("referência", "reference"), prefs.text("referências", "references")) }
                Spacer(minLength: 4)
                if wide {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(model.status(prefs)).font(.caption).foregroundStyle(.secondary)
                        Text("\(model.scannedCount) / \(model.linkCount)").font(.system(size: 10, design: .monospaced)).foregroundStyle(Brand.accent(scheme))
                    }
                }
                Button { model.toggle() } label: {
                    Label(model.running ? prefs.text("Pausar", "Pause") : model.phase == .paused ? prefs.text("Retomar", "Resume") : prefs.text("Explorar", "Explore"), systemImage: model.running ? "pause.fill" : "play.fill")
                }.buttonStyle(ActionButtonStyle()).keyboardShortcut("e", modifiers: .command).disabled(!model.loaded || model.linkCount == 0)
                    .opacity(!model.loaded || model.linkCount == 0 ? 0.45 : 1).accessibilityIdentifier("explore.toggle")
            }
            if !wide {
                HStack { Text(model.status(prefs)); Spacer(); Text("\(model.scannedCount) / \(model.linkCount)").monospacedDigit() }.font(.system(size: 10)).foregroundStyle(.secondary)
            }
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.primary.opacity(0.07))
                    Capsule().fill(Brand.gradient).frame(width: max(0, geometry.size.width * model.progress))
                        .animation(reduce || prefs.reducedMotion ? nil : .easeOut(duration: 0.3), value: model.progress)
                }
            }.frame(height: 3).accessibilityLabel(prefs.text("Progresso", "Progress")).accessibilityValue("\(Int(model.progress * 100))%")
        }.padding(.horizontal, wide ? 28 : 16).padding(.top, 18).padding(.bottom, 16)
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }
    private func metric(_ value: Int, _ singular: String, _ plural: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(value)").font(.system(size: 23, weight: .medium, design: .rounded)).monospacedDigit().contentTransition(.numericText())
            Text(value == 1 ? singular : plural).font(.system(size: 10)).foregroundStyle(.secondary)
        }.accessibilityElement(children: .combine)
    }
}

struct AdaptiveLabelStyle: LabelStyle {
    let iconOnly: Bool
    func makeBody(configuration: Configuration) -> some View {
        if iconOnly { configuration.icon } else { HStack(spacing: 6) { configuration.icon; configuration.title } }
    }
}

// The page keeps running behind the Map and Discoveries views so exploration never stalls, but an embedded
// platform view ignores SwiftUI's `allowsHitTesting` and would swallow their clicks. While hidden, the container
// shrinks to zero size, which no click can reach, and the page keeps its last size so its layout and the spider stay put.
#if os(macOS)
final class WebContainer: NSView {
    let webView: WKWebView
    init(_ webView: WKWebView) { self.webView = webView; super.init(frame: .zero); addSubview(webView) }
    required init?(coder: NSCoder) { nil }
    override func layout() { super.layout(); if bounds.width > 0, bounds.height > 0 { webView.frame = bounds } }
}
struct WebSurface: NSViewRepresentable {
    let webView: WKWebView
    func makeNSView(context: Context) -> WebContainer { WebContainer(webView) }
    func updateNSView(_ nsView: WebContainer, context: Context) {}
}
#else
final class WebContainer: UIView {
    let webView: WKWebView
    init(_ webView: WKWebView) { self.webView = webView; super.init(frame: .zero); clipsToBounds = false; addSubview(webView) }
    required init?(coder: NSCoder) { nil }
    override func layoutSubviews() { super.layoutSubviews(); if bounds.width > 0, bounds.height > 0 { webView.frame = bounds } }
}
struct WebSurface: UIViewRepresentable {
    let webView: WKWebView
    func makeUIView(context: Context) -> WebContainer { WebContainer(webView) }
    func updateUIView(_ uiView: WebContainer, context: Context) {}
}
#endif
