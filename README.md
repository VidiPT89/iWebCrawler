# 🕷️ iWebCrawler

> Follow the thread. A native visual web explorer for iPhone, iPad and Mac, with a browser extension for Safari, Chrome, Brave, Edge, Opera and Firefox, a Home Screen widget and an animated spider that brings the connections between pages to life.

[![Report Bug](https://img.shields.io/badge/Report-Bug-red)](https://github.com/VidiPT89/iWebCrawler/issues)
[![Request Feature](https://img.shields.io/badge/Request-Feature-blue)](https://github.com/VidiPT89/iWebCrawler/issues)
[![Platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20iPadOS%20%7C%20macOS-d97706)](#-quick-start)
[![Browsers](https://img.shields.io/badge/extension-Safari%20%7C%20Chrome%20%7C%20Brave%20%7C%20Edge%20%7C%20Firefox-ea580c)](#-browser-extension)

<p align="center">
  <img src="iWebCrawler/Resources/Brand.xcassets/Logo.imageset/Logo.png" width="160" alt="iWebCrawler logo: a glowing amber spider inside a circuit-like web">
</p>

## ✨ Features

- ✅ A browser extension with the same spider for Safari (Mac, iPhone and iPad), Chrome, Brave, Edge, Opera and Firefox: explore the page you are reading, filter its references and export them as JSON or CSV
- ✅ A Home Screen and Lock Screen widget on iPhone and iPad with your latest explorations; tap one to reopen it
- ✅ Eight articulated legs, glowing joints and a silk trail: the spider moves across real web pages and highlights the links it discovers
- ✅ Native SwiftUI workspace with an embedded WebKit browser, an adaptive discoveries panel and a live connection map
- ✅ A connection map that shows the real graph: every explored page is a hub, followed links are drawn as paths, and you can tap a point for details, zoom and pan
- ✅ Exploration history saved on the device: reopen any past collection and continue exploring where you left off
- ✅ Link checking: see which links are available, redirect, refuse automated checks or are broken, and filter the broken ones
- ✅ A warm visual identity inspired by [ividi.dev](https://ividi.dev/): burnt orange, amber, charcoal and a paper-like light theme
- ✅ Brief animated introduction with developer credits, automatic dismissal and a skip button
- ✅ Portuguese (Portugal) and English, switchable instantly from Settings and remembered between launches
- ✅ System, Light and Dark appearance modes, also saved in Settings
- ✅ Explore, pause, resume and restart, with four animation speeds and a real progress indicator
- ✅ Deduplicated link collection that recognises DOI, PMID, PMC, ISBN, ISSN, Bibcode, arXiv, S2CID, OCLC and Handle identifiers, including image and icon links named by their accessible label
- ✅ Identifiers come alive as the spider reaches them: they jump off the page in bright colours and mixed typefaces, some in solid blocks or turned on their side, with a beam from the spider (off with Reduce Motion)
- ✅ Search, reference filters, link details and individual link sharing
- ✅ Export the current collection as dated JSON and CSV files using the system share menu
- ✅ Optional same-site link following that respects `robots.txt`, with a configurable limit of 1–20 pages and a two-second delay between pages
- ✅ A light haptic tap on iPhone whenever the spider finds a reference
- ✅ An offline, bilingual demonstration with eight real references to science and natural history
- ✅ Ephemeral browsing storage, history kept on the device only, no account, no analytics and no application backend
- ✅ VoiceOver labels, system Reduce Motion support and an additional in-app reduced-motion option
- ✅ A shared codebase for iOS, iPadOS and macOS, with a matching custom app icon

## 🛠️ Tech Stack

| Category | Technology |
|----------|------------|
| Language | Swift 6 language mode |
| Native interface | SwiftUI |
| Browser | WebKit / WKWebView |
| Spider rendering | JavaScript and Canvas 2D |
| Browser extension | WebExtensions Manifest V3 (Chromium, Firefox) and Safari Web Extension |
| Widget | WidgetKit with an App Group shared with the app |
| Connection map | SwiftUI Canvas and TimelineView |
| Preferences | UserDefaults |
| History | Codable JSON file in Application Support |
| Link checking and robots.txt | URLSession |
| Export | Codable / JSONEncoder, CSV and ShareLink |
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

The Xcode project is included. After adding or moving source files, regenerate it with `xcodegen generate`. The project uses the development team set in `project.yml`; replace `DEVELOPMENT_TEAM` with your own to sign the app, the widget and the Safari extension.

To add the widget, touch and hold the Home Screen, choose **Edit › Add Widget** and search for **iWebCrawler**.

### 🧩 Browser extension

The `extension` folder is a single Manifest V3 extension. Download `iWebCrawler-extension-1.2.0.zip` from the [latest release](https://github.com/VidiPT89/iWebCrawler/releases/latest), or build it with `./scripts/build-extension.sh`.

| Browser | How to install |
|---------|----------------|
| Chrome, Brave, Edge, Opera | Open `chrome://extensions` (or `brave://`, `edge://`, `opera://`), turn on **Developer mode**, choose **Load unpacked** and select the `extension` folder (or the unzipped release) |
| Firefox | Open `about:debugging#/runtime/this-firefox`, choose **Load Temporary Add-on** and select `extension/manifest.json` |
| Safari on Mac | Run the Mac app once, then open **Safari › Settings › Extensions** and turn on **iWebCrawler** (the app's **Settings › Turn on in Safari** opens it for you). For a build signed only for development, first enable **Develop › Allow Unsigned Extensions** |
| Safari on iPhone and iPad | Install the app, then go to **Settings › Apps › Safari › Extensions › iWebCrawler** |

Click the spider in the toolbar (or press **Alt+Shift+E**), then **Explore**. The extension asks for no permanent access to your websites: it only runs on the tab where you open it. Pages that browsers protect, such as internal settings pages and extension stores, cannot be explored.

The app icon, the in-app logo, the widget logo and the extension icons are all generated from `design/iWebCrawler-logo.jpeg` with `swift scripts/MakeIcons.swift`.

## 📖 Usage

1. The introduction fades into the workspace automatically. Choose **Explore** to try the offline collection.
2. Enter a website address and press the arrow or Return to open a real page.
3. Choose **Explore** (or press **⌘E** on Mac or with a keyboard), then watch the spider follow and highlight its links. Pause and resume at any time.
4. Switch to **Map** to see the connections, or **Discoveries** to search and filter the collected links. On the map, tap a point to open that link, and use **−**, **+** or a pinch to zoom.
5. Choose **Check links** to test every collected link; choose **Broken** to see only the problems.
6. Select a discovery to inspect its full address and status, share it or explore that address.
7. Choose **Export collection**, then **JSON** or **CSV** to keep your results.
8. Open **History** (the clock, or **⌘Y** on Mac) to reopen a past exploration and continue it.
9. Open **Settings** for language, appearance, speed, reduced motion and same-site exploration. On Mac, use **⌘,**.

Every exploration of a real website is saved to the history on this device (up to the 30 most recent); the offline demonstration is not. Opening a new address or the demonstration starts a new collection. Backgrounding the app pauses exploration.

### JSON format

The export is a UTF-8 JSON array. Each entry includes its title, full URL, reference type, the page where it was discovered and, once checked, its HTTP status (`-1` when the server did not answer, `-2` for plain HTTP links, which are not checked). The CSV export has the same columns:

```json
[
  {
    "id": "B2CA81D8-6D62-4E53-B058-443A2328E910",
    "page": "https://example.org/references",
    "title": "Fossil mesothele spiders",
    "status": 302,
    "type": "DOI",
    "url": "https://doi.org/10.1038/379498b0"
  }
]
```

### Scope and limits

This is an interactive, foreground explorer, not a large-scale indexing service. It scans up to 1,500 rendered links in the main document. It does not extract PDF contents or iframe contents, and does not rescan links added dynamically after the page loads. Reference classification recognises patterns; it does not verify bibliographic metadata.

Automatic following is off by default. It only queues links on the original hostname, excludes query strings, removes fragments, avoids revisiting pages and applies the configured page limit. Cross-host redirects during automatic navigation are stopped. It reads the site's `robots.txt` (RFC 9309 groups, `Allow`/`Disallow`, `*` and `$`) and skips disallowed pages; if `robots.txt` cannot be reached because of a server error, it follows no further pages. Enable automatic following only on sites you are authorised to crawl.

Link checking sends a `HEAD` request to each link (falling back to a one-byte `GET` when `HEAD` is refused), four at a time, without following redirects. Answers such as 401, 403, 405 and 429 usually mean the website refuses automated checks, so they are shown as restricted rather than broken.

Appearance changes the native interface and the bundled demonstration. Third-party websites retain their own styling and language.

## 🧪 Testing

```bash
node --test tests/spider.test.cjs
swiftc -swift-version 6 -module-cache-path /tmp/iwebcrawler-swift-cache \
  iWebCrawler/Preferences.swift iWebCrawler/CrawlerModel.swift iWebCrawler/Discovery.swift \
  iWebCrawler/LinkTools.swift iWebCrawler/HistoryStore.swift iWebCrawler/MapLayout.swift \
  tests/NativeChecks.swift -o /tmp/iwebcrawler-native-checks
/tmp/iwebcrawler-native-checks
xcodebuild -project iWebCrawler.xcodeproj -scheme iWebCrawler-macOS \
  -destination 'platform=macOS' -derivedDataPath /tmp/iwebcrawler-mac \
  CODE_SIGNING_ALLOWED=NO build
xcodebuild -project iWebCrawler.xcodeproj -scheme iWebCrawler \
  -sdk iphonesimulator -derivedDataPath /tmp/iwebcrawler-ios \
  CODE_SIGNING_ALLOWED=NO build
```

The JavaScript suite covers protocol filtering, deduplication, reference classification, accessible link labels, progress, pause/resume, restart, empty pages and speed changes, plus the browser extension: the shared spider, the page bridge, the manifest and both translations. Native checks cover URL validation, language selection, appearance mapping, preference restoration and bounds, `robots.txt` rules, CSV escaping, link status classification, history persistence and limits, and the map layout.

## 🔒 Privacy

No account, telemetry or application server is used. Settings and the exploration history are stored on the device only, and the history can be deleted from the History screen. The browser uses a non-persistent website data store. Websites you open still receive ordinary web requests and may apply their own privacy policies; link checking contacts each checked address, and automatic following requests the site's `robots.txt`. Exports contain the URLs you explored and the titles collected from them. The browser extension keeps its collection in the open tab only, stores just its own settings, and sends nothing anywhere. The widget reads the history from an App Group shared with the app, on the device.

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
