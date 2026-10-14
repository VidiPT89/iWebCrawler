import CoreGraphics
import Foundation

/// Positions for the connection map: each explored page is a hub, and its links fan out in their own sector of the outer ring.
struct MapLayout {
    struct Hub { let page: String; let point: CGPoint }
    struct Leaf { let discovery: Discovery; let point: CGPoint; let hub: CGPoint }
    static let capacity = 60
    let hubs: [Hub]
    let leaves: [Leaf]
    /// Links that were themselves explored, drawn from the page that found them to their own hub.
    let paths: [(from: CGPoint, to: CGPoint)]

    /// `explored` lists every visited page, so a page whose links were all found earlier still gets its own hub.
    init(discoveries: [Discovery], explored: [String] = [], size: CGSize) {
        let entries = Array(discoveries.suffix(Self.capacity))
        var pages: [String] = []
        for entry in entries where !pages.contains(entry.page) { pages.append(entry.page) }
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = max(40, min(size.width, size.height) * 0.4)
        let stagger = entries.count > 24
        var hubs: [Hub] = [], leaves: [Leaf] = [], slot = 0
        for page in pages {
            let group = entries.filter { $0.page == page }
            let middle = (Double(slot) + Double(group.count) / 2) / Double(entries.count) * 2 * .pi - .pi / 2
            let hub = pages.count == 1 ? center : CGPoint(x: center.x + cos(middle) * radius * 0.32, y: center.y + sin(middle) * radius * 0.32)
            hubs.append(Hub(page: page, point: hub))
            for (index, entry) in group.enumerated() {
                let angle = (Double(slot) + 0.5) / Double(entries.count) * 2 * .pi - .pi / 2
                let distance = radius * (stagger && !index.isMultiple(of: 2) ? 0.84 : 1)
                leaves.append(Leaf(discovery: entry, point: CGPoint(x: center.x + cos(angle) * distance, y: center.y + sin(angle) * distance), hub: hub))
                slot += 1
            }
        }
        func target(_ leaf: Leaf) -> String { leaf.discovery.url.split(separator: "#", maxSplits: 1).first.map(String.init) ?? leaf.discovery.url }
        let quiet = explored.filter { !pages.contains($0) }
        for (index, page) in quiet.enumerated() {
            // A page reached through a link sits halfway along that link; any other one goes on the inner ring.
            if let link = leaves.first(where: { target($0) == page }) {
                hubs.append(Hub(page: page, point: CGPoint(x: link.hub.x + (link.point.x - link.hub.x) * 0.55, y: link.hub.y + (link.point.y - link.hub.y) * 0.55)))
            } else {
                let angle = Double(index) / Double(quiet.count) * 2 * .pi + .pi / 4
                hubs.append(Hub(page: page, point: CGPoint(x: center.x + cos(angle) * radius * 0.5, y: center.y + sin(angle) * radius * 0.5)))
            }
        }
        let hubByPage = Dictionary(hubs.map { ($0.page, $0.point) }, uniquingKeysWith: { first, _ in first })
        paths = leaves.compactMap { leaf in
            guard target(leaf) != leaf.discovery.page, let point = hubByPage[target(leaf)] else { return nil }
            return (leaf.hub, point)
        }
        self.hubs = hubs; self.leaves = leaves
    }

    /// The link drawn closest to `point`, if one lies within `tolerance`. `transform` maps layout points to the screen.
    func discovery(near point: CGPoint, tolerance: CGFloat, transform: (CGPoint) -> CGPoint = { $0 }) -> Discovery? {
        let nearest = leaves.map { leaf -> (Discovery, CGFloat) in
            let p = transform(leaf.point); return (leaf.discovery, hypot(p.x - point.x, p.y - point.y))
        }.min { $0.1 < $1.1 }
        guard let nearest, nearest.1 <= tolerance else { return nil }
        return nearest.0
    }
}
