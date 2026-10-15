import SwiftUI
import WebKit

enum CrawlPhase { case loading, ready, scanning, paused, complete, waiting, failed }

@MainActor
final class CrawlerModel: NSObject, ObservableObject, WKNavigationDelegate, WKScriptMessageHandler {
    @Published var selectedDiscovery: Discovery?
    @Published var showSettings = false
    @Published var showHistory = false
    @Published var showSplash = true
    @Published var tab = 0
    @Published var search = ""
    @Published var filter = "All"
    @Published var address = "https://en.wikipedia.org/wiki/Spider"
    @Published var phase: CrawlPhase = .loading
    @Published var loaded = false
    @Published var discoveries: [Discovery] = []
    @Published var pageCount = 0
    @Published var linkCount = 0
    @Published var scannedCount = 0
    @Published var error: String?
    @Published var exportFiles: [URL] = []
    @Published var isDemo = true
    @Published var checking = false
    @Published var checkedCount = 0
    @Published var checkTotal = 0
    let webView: WKWebView
    let history: HistoryStore
    private var explorationID = UUID()
    private var startAddress = ""
    private var checkTask: Task<Void, Never>?
    private var robots: (host: String, rules: RobotsRules)?
    private var visited = Set<String>()
    private var seen = Set<String>()
    private var queue: [URL] = []
    private var rootHost: String?
    private var autoStart = false
    private var nextPage: Task<Void, Never>?
    private var preferences: Preferences { .shared }
    private let world = WKContentWorld.world(name: "iWebCrawler")
    private var activeNavigation: WKNavigation?
    private var darkPage = false
    var running: Bool { phase == .scanning || phase == .waiting }
    var progress: Double { linkCount > 0 ? min(1, Double(scannedCount) / Double(linkCount)) : 0 }
    var referenceCount: Int { discoveries.filter { $0.type != "Link" }.count }
    var exploredPages: [String] { isDemo ? [] : visited.sorted() }
    var problemCount: Int { discoveries.filter { $0.health.isProblem }.count }
    var availableFilters: [String] {
        ["All"] + ["DOI", "PMID", "ISBN", "Bibcode", "Link"].filter { type in discoveries.contains { $0.type == type } } + (problemCount > 0 ? ["Broken"] : [])
    }
    var filtered: [Discovery] {
        discoveries.filter { item in
            let matchesFilter = filter == "All" || (filter == "Broken" ? item.health.isProblem : item.type == filter)
            return matchesFilter && (search.isEmpty || (item.title + item.url).localizedCaseInsensitiveContains(search))
        }
    }

    init(history: HistoryStore? = nil) {
        self.history = history ?? .shared
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        webView = WKWebView(frame: .zero, configuration: config)
        super.init()
        webView.navigationDelegate = self
        config.userContentController.add(self, contentWorld: world, name: "crawler")
        showDemo()
    }
    func status(_ prefs: Preferences) -> String {
        switch phase {
        case .loading: prefs.text("A abrir página…", "Opening page…")
        case .ready: linkCount == 0 ? prefs.text("Sem ligações nesta página", "No links on this page") : prefs.text("Pronto para explorar", "Ready to explore")
        case .scanning: prefs.text("A seguir o fio", "Following the thread")
        case .paused: prefs.text("Exploração em pausa", "Exploration paused")
        case .complete: prefs.text("Exploração concluída", "Exploration complete")
        case .waiting: prefs.text("A preparar a próxima página…", "Preparing the next page…")
        case .failed: prefs.text("Não foi possível continuar", "Unable to continue")
        }
    }
    func showDemo() {
        reset(); isDemo = true; rootHost = nil
        if let url = Bundle.main.url(forResource: "Demo", withExtension: "html") {
            activeNavigation = webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }
    }
    private func reset() {
        pause(); activeNavigation = nil; webView.stopLoading()
        loaded = false; autoStart = false; phase = .loading; linkCount = 0; scannedCount = 0; error = nil
        clearCollection()
    }
    private func clearCollection() {
        checkTask?.cancel(); checkTask = nil; checking = false
        explorationID = UUID(); startAddress = ""
        discoveries = []; seen = []; visited = []; queue = []; pageCount = 0; exportFiles = []; filter = "All"; search = ""
    }
    /// Stores the current collection in the history. The offline demonstration is never saved.
    func saveExploration() {
        guard !isDemo, !discoveries.isEmpty else { return }
        history.save(Exploration(id: explorationID, date: Date(), start: startAddress.isEmpty ? discoveries[0].page : startAddress, pages: visited.sorted(), discoveries: discoveries))
    }
    /// Links from the widget: `iwebcrawler://history/<id>` reopens an exploration, `iwebcrawler://history` shows the list.
    func open(_ link: URL) {
        guard link.scheme == "iwebcrawler", link.host == "history" else { return }
        showSplash = false
        if let id = UUID(uuidString: link.lastPathComponent), let item = history.items.first(where: { $0.id == id }) { restore(item) }
        else { showHistory = true }
    }
    /// Reopens a saved exploration: its collection comes back and its first page loads, ready to continue.
    func restore(_ exploration: Exploration) {
        reset(); isDemo = false
        explorationID = exploration.id; startAddress = exploration.start
        discoveries = exploration.discoveries; seen = Set(exploration.discoveries.map(\.url))
        visited = Set(exploration.pages); pageCount = visited.count
        showHistory = false; tab = 2
        guard let url = URL(string: exploration.start), ["http", "https"].contains(url.scheme ?? "") else { phase = .complete; return }
        address = url.absoluteString; rootHost = url.host
        activeNavigation = webView.load(URLRequest(url: url, timeoutInterval: 30))
    }
    static func normalizedURL(_ raw: String) -> URL? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.contains("://") { text = "https://" + text }
        guard let url = URL(string: text), ["https", "http"].contains(url.scheme?.lowercased() ?? ""), let host = url.host, !host.isEmpty, url.user == nil, url.password == nil, !text.contains(" ") else { return nil }
        return url
    }
    func explore(_ url: String) {
        selectedDiscovery = nil; address = url; load(); tab = 0
    }
    func load() {
        guard let url = Self.normalizedURL(address) else { error = preferences.text("Introduz um endereço HTTP ou HTTPS válido.", "Enter a valid HTTP or HTTPS address."); return }
        reset(); isDemo = false; rootHost = url.host; address = url.absoluteString; startAddress = address
        activeNavigation = webView.load(URLRequest(url: url, timeoutInterval: 30))
    }
    func toggle() {
        if running { pause(); return }
        guard loaded, linkCount > 0 else { return }
        if scannedCount >= linkCount && preferences.followLinks && !isDemo && pageCount < preferences.pageLimit && !queue.isEmpty { scheduleNext(); return }
        phase = .scanning; configure(dark: darkPage)
        evaluate("window.__crawler?.start()")
    }
    func pause() {
        nextPage?.cancel(); nextPage = nil; autoStart = false
        if running { phase = .paused }
        evaluate("window.__crawler?.pause()")
        saveExploration()
    }
    func configure(dark: Bool) {
        darkPage = dark
        let options: [String: Any] = ["speed": preferences.speed, "reducedMotion": preferences.reducedMotion, "language": preferences.language.rawValue, "dark": dark]
        guard let data = try? JSONSerialization.data(withJSONObject: options), let json = String(data: data, encoding: .utf8) else { return }
        evaluate("window.__crawler?.configure(\(json))")
    }
    private func evaluate(_ script: String) { webView.evaluateJavaScript(script, in: nil, in: world) { _ in } }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        guard navigation === activeNavigation else { return }
        if let url = webView.url { visited.insert(canonical(url).absoluteString) }
        pageCount = visited.count
        if !isDemo, let url = webView.url { address = url.absoluteString }
        guard let path = Bundle.main.url(forResource: "Spider", withExtension: "js"), let script = try? String(contentsOf: path, encoding: .utf8) else {
            error = preferences.text("Não foi possível carregar a animação.", "The animation could not be loaded."); phase = .failed; return
        }
        webView.evaluateJavaScript(script, in: nil, in: world) { [weak self] result in
            if case .failure(let error) = result { self?.fail(error) }
        }
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        activeNavigation = navigation; loaded = false; scannedCount = 0; linkCount = 0; phase = .loading
    }
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) { if navigation === activeNavigation { fail(error) } }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { if navigation === activeNavigation { fail(error) } }
    private func fail(_ error: Error) {
        guard (error as NSError).code != NSURLErrorCancelled else { return }
        pause(); loaded = false; phase = .failed
        self.error = preferences.text("Não foi possível abrir a página. Verifica o endereço e a ligação à internet.", "Could not open this page. Check the address and your internet connection.")
    }
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        pause(); loaded = false; phase = .failed
        error = preferences.text("A página foi interrompida. Abre-a novamente para continuar.", "The page was interrupted. Open it again to continue.")
    }
    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard action.targetFrame?.isMainFrame != false else { return .allow }
        guard let url = action.request.url, ["http", "https", "file"].contains(url.scheme ?? "") else { return .cancel }
        if autoStart, url.host != rootHost { pause(); phase = .complete; return .cancel }
        if action.navigationType == .linkActivated {
            pause()
            if isDemo { clearCollection(); isDemo = false; startAddress = url.absoluteString }
            rootHost = url.host
            if action.targetFrame == nil { activeNavigation = webView.load(action.request); return .cancel }
        }
        return .allow
    }
    func webView(_ webView: WKWebView, decidePolicyFor response: WKNavigationResponse) async -> WKNavigationResponsePolicy {
        guard response.isForMainFrame else { return .allow }
        if let http = response.response as? HTTPURLResponse, http.statusCode >= 400 {
            pause(); phase = .failed; loaded = false
            error = preferences.text("O site devolveu um erro", "The website returned an error") + " (HTTP \(http.statusCode))."
            return .cancel
        }
        guard response.response.mimeType == "text/html" || response.response.mimeType == "application/xhtml+xml" else {
            pause(); loaded = false; phase = .failed
            error = preferences.text("Este explorador trabalha com páginas HTML. Abre um endereço de página, em vez de um ficheiro.", "This explorer works with HTML pages. Open a page address rather than a file.")
            return .cancel
        }
        return .allow
    }
    private func canonical(_ url: URL) -> URL {
        var parts = URLComponents(url: url, resolvingAgainstBaseURL: false); parts?.fragment = nil
        return parts?.url ?? url
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, let data = message.body as? [String: Any], let kind = data["kind"] as? String else { return }
        // A page that is being replaced can still report a few links; they must not join the new collection.
        if kind != "ready" && phase != .scanning { return }
        switch kind {
        case "ready":
            loaded = true; linkCount = data["count"] as? Int ?? 0; phase = .ready
            configure(dark: darkPage)
            if autoStart { autoStart = false; if linkCount > 0 { toggle() } else { finishPage() } }
        case "progress": scannedCount = data["scanned"] as? Int ?? scannedCount
        case "link":
            guard let url = data["url"] as? String, let title = data["title"] as? String, seen.insert(url).inserted else { return }
            discoveries.append(Discovery(id: UUID(), title: title, url: url, type: data["type"] as? String ?? "Link", page: isDemo ? "iWebCrawler Demo" : webView.url.map { canonical($0).absoluteString } ?? ""))
            exportFiles = []
            if let next = URL(string: url), next.host == rootHost, next.query == nil, ["http", "https"].contains(next.scheme ?? "") {
                let candidate = canonical(next)
                if !visited.contains(candidate.absoluteString), !queue.contains(candidate) { queue.append(candidate) }
            }
        case "complete": finishPage()
        default: break
        }
    }
    private func finishPage() {
        phase = .complete
        saveExploration()
        if preferences.followLinks && !isDemo && pageCount < preferences.pageLimit && !queue.isEmpty { scheduleNext() }
    }
    private func scheduleNext() {
        nextPage?.cancel(); phase = .waiting
        nextPage = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled, let self else { return }
            guard self.preferences.followLinks, self.pageCount < self.preferences.pageLimit else { self.phase = .complete; return }
            let rules = await self.robotsRules()
            guard !Task.isCancelled else { return }
            while let first = self.queue.first, self.visited.contains(first.absoluteString) || !rules.allows(Self.robotsPath(first)) { self.queue.removeFirst() }
            guard !self.queue.isEmpty else { self.phase = .complete; return }
            let next = self.queue.removeFirst(); self.autoStart = true
            self.activeNavigation = self.webView.load(URLRequest(url: next, timeoutInterval: 30))
        }
    }
    private func robotsRules() async -> RobotsRules {
        guard let host = rootHost else { return .allowAll }
        if let robots, robots.host == host { return robots.rules }
        let rules = await RobotsRules.fetch(scheme: URL(string: startAddress)?.scheme ?? "https", host: host)
        robots = (host, rules)
        return rules
    }
    nonisolated static func robotsPath(_ url: URL) -> String {
        let path = URLComponents(url: url, resolvingAgainstBaseURL: false)?.percentEncodedPath ?? url.path
        return path.isEmpty ? "/" : path
    }
    /// Checks every unchecked link, four at a time. Calling it again while it runs stops the check.
    func checkLinks() {
        if checking { checkTask?.cancel(); checkTask = nil; checking = false; saveExploration(); return }
        let pending = discoveries.filter { $0.status == nil }.map { ($0.id, $0.url) }
        guard !pending.isEmpty else { return }
        checking = true; checkedCount = 0; checkTotal = pending.count
        checkTask = Task { [weak self] in
            await withTaskGroup(of: (UUID, Int).self) { group in
                var remaining = pending[...]
                func enqueue() {
                    guard let (id, url) = remaining.popFirst() else { return }
                    group.addTask { (id, await LinkChecker.status(of: url)) }
                }
                for _ in 0..<4 { enqueue() }
                for await (id, status) in group {
                    guard let self, !Task.isCancelled else { group.cancelAll(); return }
                    if let index = self.discoveries.firstIndex(where: { $0.id == id }) { self.discoveries[index].status = status }
                    self.checkedCount += 1; self.exportFiles = []
                    enqueue()
                }
            }
            guard let self, !Task.isCancelled else { return }
            self.checking = false; self.saveExploration()
        }
    }
    func prepareExport() {
        do {
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let stamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
            let folder = FileManager.default.temporaryDirectory
            let json = folder.appendingPathComponent("iWebCrawler-\(stamp).json"), csv = folder.appendingPathComponent("iWebCrawler-\(stamp).csv")
            try encoder.encode(discoveries).write(to: json, options: .atomic)
            try Data(CollectionExport.csv(discoveries).utf8).write(to: csv, options: .atomic)
            exportFiles = [json, csv]
        } catch { self.error = preferences.text("Não foi possível preparar os ficheiros.", "Could not prepare the files.") }
    }
}
