import SwiftUI

@main
struct iWebCrawlerApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
        #if os(macOS)
        .defaultSize(width: 1240, height: 850)
        #endif
    }
}
