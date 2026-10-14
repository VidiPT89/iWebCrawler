import Foundation

enum LinkHealth: Equatable {
    case unchecked, ok, redirected, restricted, broken, unreachable, skipped
    /// Answers that usually mean the website refuses automated checks, not that the page is gone.
    static let restrictedCodes: Set<Int> = [401, 403, 405, 429, 999]
    init(status: Int?) {
        switch status {
        case nil: self = .unchecked
        case -2: self = .skipped
        case -1: self = .unreachable
        case let code? where code < 300: self = .ok
        case let code? where code < 400: self = .redirected
        case let code? where Self.restrictedCodes.contains(code): self = .restricted
        default: self = .broken
        }
    }
    var isProblem: Bool { self == .broken || self == .unreachable }
}

/// Checks a link without following redirects, so a 3xx answer is reported as a redirect.
enum LinkChecker {
    private final class NoRedirect: NSObject, URLSessionTaskDelegate, Sendable {
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest) async -> URLRequest? { nil }
    }
    private static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        config.httpAdditionalHeaders = ["User-Agent": "iWebCrawler/1.2 (link check)"]
        return URLSession(configuration: config, delegate: NoRedirect(), delegateQueue: nil)
    }()

    /// HTTP status code, -1 when the server cannot be reached, -2 for plain HTTP links, which App Transport Security blocks outside the browser.
    static func status(of address: String) async -> Int {
        guard let url = URL(string: address), url.scheme?.lowercased() == "https" else { return -2 }
        var request = URLRequest(url: url); request.httpMethod = "HEAD"
        guard let code = await code(for: request) else { return -1 }
        guard [403, 405, 501].contains(code) else { return code }
        var fallback = URLRequest(url: url); fallback.setValue("bytes=0-0", forHTTPHeaderField: "Range")
        return await self.code(for: fallback) ?? code
    }
    private static func code(for request: URLRequest) async -> Int? {
        guard let (_, response) = try? await session.data(for: request) else { return nil }
        return (response as? HTTPURLResponse)?.statusCode
    }
}

/// A small robots.txt reader (RFC 9309): user-agent groups, Allow/Disallow, `*` and `$`, longest match wins.
struct RobotsRules {
    private var rules: [(allow: Bool, pattern: String)] = []
    static let allowAll = RobotsRules()
    static let disallowAll: RobotsRules = { var rules = RobotsRules(); rules.rules = [(false, "/")]; return rules }()
    private init() {}

    init(_ text: String, agent: String = "iwebcrawler") {
        var groups: [(agents: [String], rules: [(Bool, String)])] = []
        var collectingAgents = false
        for raw in text.components(separatedBy: .newlines) {
            let line = raw.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? ""
            guard let colon = line.firstIndex(of: ":") else { continue }
            let key = line[..<colon].trimmingCharacters(in: .whitespaces).lowercased()
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            switch key {
            case "user-agent":
                if !collectingAgents || groups.isEmpty { groups.append(([], [])) }
                groups[groups.count - 1].agents.append(value.lowercased()); collectingAgents = true
            case "allow", "disallow":
                collectingAgents = false
                guard !groups.isEmpty, !value.isEmpty else { continue }
                groups[groups.count - 1].rules.append((key == "allow", value))
            default: continue
            }
        }
        let specific = groups.filter { $0.agents.contains { $0 != "*" && agent.contains($0) } }
        let chosen = specific.isEmpty ? groups.filter { $0.agents.contains("*") } : specific
        rules = chosen.flatMap(\.rules).map { (allow: $0.0, pattern: $0.1) }
    }

    func allows(_ path: String) -> Bool {
        var best: (allow: Bool, length: Int)?
        for rule in rules where Self.matches(rule.pattern, path) {
            let length = rule.pattern.count
            if best == nil || length > best!.length || (length == best!.length && rule.allow) { best = (rule.allow, length) }
        }
        return best?.allow ?? true
    }
    private static func matches(_ pattern: String, _ path: String) -> Bool {
        let anchored = pattern.hasSuffix("$")
        let body = anchored ? String(pattern.dropLast()) : pattern
        let regex = "^" + body.components(separatedBy: "*").map(NSRegularExpression.escapedPattern).joined(separator: ".*") + (anchored ? "$" : "")
        return path.range(of: regex, options: .regularExpression) != nil
    }

    private static let session = URLSession(configuration: .ephemeral)
    static func fetch(scheme: String, host: String) async -> RobotsRules {
        guard let url = URL(string: "\(scheme)://\(host)/robots.txt") else { return .allowAll }
        var request = URLRequest(url: url, timeoutInterval: 8)
        request.setValue("iWebCrawler/1.2", forHTTPHeaderField: "User-Agent")
        guard let (data, response) = try? await session.data(for: request),
              let code = (response as? HTTPURLResponse)?.statusCode else { return .disallowAll }
        if code >= 500 { return .disallowAll }
        guard code < 300 else { return .allowAll }
        return RobotsRules(String(decoding: data, as: UTF8.self))
    }
}

enum CollectionExport {
    static func csv(_ items: [Discovery]) -> String {
        func field(_ value: String) -> String { "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\"" }
        let rows = items.map { [field($0.title), field($0.url), field($0.type), field($0.page), $0.status.map(String.init) ?? ""].joined(separator: ",") }
        return (["title,url,type,page,status"] + rows).joined(separator: "\r\n") + "\r\n"
    }
}
