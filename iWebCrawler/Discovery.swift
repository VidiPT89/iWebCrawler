import Foundation

/// One link found by the spider. Shared with the widget, so it stays free of WebKit and SwiftUI.
struct Discovery: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: String
    let type: String
    let page: String
    var status: Int? = nil
    var host: String { URL(string: url)?.host ?? url }
    var health: LinkHealth { LinkHealth(status: status) }
}
