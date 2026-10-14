# 🕷️ iWebCrawler

> Follow the thread. A native visual web explorer for iPhone, iPad and Mac, with an animated spider that brings the connections between pages to life.

[![Report Bug](https://img.shields.io/badge/Report-Bug-red)](https://github.com/VidiPT89/iWebCrawler/issues)
[![Request Feature](https://img.shields.io/badge/Request-Feature-blue)](https://github.com/VidiPT89/iWebCrawler/issues)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20iPadOS%20%7C%20macOS-d97706)](#-quick-start)

<p align="center">
  <img src="iWebCrawler/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png" width="144" alt="iWebCrawler: an amber and burnt-orange spider on a dark background">
</p>

## ✨ Features

- ✅ Eight articulated legs, glowing joints and a silk trail: the spider moves across real web pages and highlights the links it discovers
- ✅ Native SwiftUI workspace with an embedded WebKit browser, an adaptive discoveries panel and a live connection map
- ✅ A warm visual identity inspired by [ividi.dev](https://ividi.dev/): burnt orange, amber, charcoal and a paper-like light theme
- ✅ Brief animated introduction with developer credits, automatic dismissal and a skip button
- ✅ Portuguese (Portugal) and English, switchable instantly from Settings and remembered between launches
- ✅ System, Light and Dark appearance modes, also saved in Settings
- ✅ Explore, pause, resume and restart, with four animation speeds and a real progress indicator
- ✅ Deduplicated link collection with DOI, PMID, ISBN and Bibcode pattern recognition, including image and icon links named by their accessible label
- ✅ Search, reference filters, link details and individual link sharing
- ✅ Export the current collection as a dated JSON file using the system share menu
- ✅ Optional same-site link following, with a configurable limit of 1–20 pages and a two-second delay between pages
- ✅ An offline, bilingual demonstration with eight real references to science and natural history
- ✅ Ephemeral browsing storage, no account, no analytics and no application backend
- ✅ VoiceOver labels, system Reduce Motion support and an additional in-app reduced-motion option
- ✅ A shared codebase for iOS, iPadOS and macOS, with a matching custom app icon

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| Language | Swift 5 language mode |
| Native interface | SwiftUI |
| Browser | WebKit / WKWebView |
| Spider rendering | JavaScript and Canvas 2D |
| Connection map | SwiftUI Canvas and TimelineView |
| Preferences | UserDefaults |
| Export | Codable / JSONEncoder and ShareLink |
| Project generation | XcodeGen |
| Testing | Node.js test runner and native Swift checks |
| Minimum iOS / iPadOS | 17.0 |
| Minimum macOS | 14.0 |

No external runtime dependencies.

## 🚀 Quick Start

### Prerequisites

- macOS with Xcode (verified with Xcode 27)
- An iOS 17+ simulator or device, or a Mac running macOS 14+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) only if you change the project structure
- Node.js 18+ to run the JavaScript tests

### Installation

```bash
git clone https://github.com/VidiPT89/iWebCrawler.git
cd iWebCrawler
open iWebCrawler.xcodeproj
```

1. Select **iWebCrawler** for iPhone/iPad or **iWebCrawler-macOS** for Mac.
2. Choose your simulator, device or **My Mac**.
3. Press **⌘R** to build and run. For a physical iPhone or iPad, select your development team under Signing & Capabilities.

The Xcode project is included. After adding or moving source files, regenerate it with `xcodegen generate`.

## 📖 Usage

1. The introduction fades into the workspace automatically. Choose **Explore** to try the offline collection.
2. Enter a website address and press the arrow or Return to open a real page.
3. Choose **Explore** (or press **⌘↩** on Mac or with a keyboard), then watch the spider follow and highlight its links. Pause and resume at any time.
4. Switch to **Map** to see the connections, or **Discoveries** to search and filter the collected links.
5. Select a discovery to inspect its full address, share it or explore that address.
6. Choose **Export collection**, then **Save / share JSON** to keep your results.
7. Open **Settings** for language, appearance, speed, reduced motion and same-site exploration. On Mac, use **⌘,**.

The collection is session-only. Opening a new address or the demonstration starts a new collection. Export before switching pages manually or closing the app. Backgrounding the app pauses exploration.

### JSON format

The export is a UTF-8 JSON array. Each entry includes its title, full URL, reference type and the page where it was discovered:

```json
[
  {
    "id": "B2CA81D8-6D62-4E53-B058-443A2328E910",
    "page": "https://example.org/references",
    "title": "Fossil mesothele spiders",
    "type": "DOI",
    "url": "https://doi.org/10.1038/379498b0"
  }
]
```

### Scope and limits

This is an interactive, foreground explorer, not a large-scale indexing service. It scans up to 1,500 rendered links in the main document. It does not extract PDF contents or iframe contents, and does not rescan links added dynamically after the page loads. Reference classification recognises patterns; it does not verify bibliographic metadata.

Automatic following is off by default. It only queues links on the original hostname, excludes query strings, removes fragments, avoids revisiting pages and applies the configured page limit. Cross-host redirects during automatic navigation are stopped. `robots.txt` is not interpreted: enable automatic following only on sites you are authorised to crawl.

Appearance changes the native interface and the bundled demonstration. Third-party websites retain their own styling and language.

## 🧪 Testing

```bash
node --test tests/spider.test.cjs
swiftc -module-cache-path /tmp/iwebcrawler-swift-cache \
  iWebCrawler/Preferences.swift iWebCrawler/CrawlerModel.swift \
  tests/NativeChecks.swift -o /tmp/iwebcrawler-native-checks
/tmp/iwebcrawler-native-checks
xcodebuild -project iWebCrawler.xcodeproj -scheme iWebCrawler-macOS \
  -destination 'platform=macOS' -derivedDataPath /tmp/iwebcrawler-mac \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild -project iWebCrawler.xcodeproj -scheme iWebCrawler \
  -sdk iphonesimulator -derivedDataPath /tmp/iwebcrawler-ios \
  CODE_SIGNING_ALLOWED=NO build
```

The JavaScript suite covers protocol filtering, deduplication, reference classification, accessible link labels, progress, pause/resume, restart, empty pages and speed changes. Native checks cover URL validation, language selection, appearance mapping and preference restoration and bounds.

## 🔒 Privacy

No account, telemetry or application server is used. Settings are stored on the device; discoveries stay in memory until exported. The browser uses a non-persistent website data store. Websites you open still receive ordinary web requests and may apply their own privacy policies. JSON exports contain the URLs you explored and the titles collected from them.

## 📄 License

Distributed under the MIT License. See [LICENSE on GitHub](https://github.com/VidiPT89/iWebCrawler/blob/main/LICENSE) for details. The license is repository documentation and is not included in the application resources.

## 👨‍💻 Author

**David Arsénio Martins**

- 🌐 Website: [ividi.dev](https://ividi.dev/)
- 🐙 GitHub: [@VidiPT89](https://github.com/VidiPT89/)

## 🤝 Contributing

Contributions, issues and feature requests are welcome. Feel free to check the [issues page](https://github.com/VidiPT89/iWebCrawler/issues).

---

<p align="center">Developed by <a href="https://ividi.dev/">David Arsénio Martins</a></p>
<p align="center">⭐ If you like this project, give it a star!</p>
