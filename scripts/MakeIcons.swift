// Builds every icon from design/iWebCrawler-logo.jpeg.
// Usage: swift scripts/MakeIcons.swift   (from the repository root)
import AppKit
import ImageIO
import UniformTypeIdentifiers

let root = FileManager.default.currentDirectoryPath
guard let source = NSImage(contentsOfFile: root + "/design/iWebCrawler-logo.jpeg")?.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fatalError("design/iWebCrawler-logo.jpeg not found; run from the repository root")
}
let side = CGFloat(source.width)

/// The source cropped to a centred square covering `fraction` of its width: the circle plus some of its glow.
func crop(_ fraction: CGFloat) -> CGImage {
    let size = side * fraction, origin = (side - size) / 2
    return source.cropping(to: CGRect(x: origin, y: origin, width: size, height: size))!
}
func render(_ size: Int, opaque: Bool, _ draw: (CGContext, CGFloat) -> Void) -> CGImage {
    let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: opaque ? CGImageAlphaInfo.noneSkipLast.rawValue : CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.interpolationQuality = .high
    draw(context, CGFloat(size))
    return context.makeImage()!
}
func write(_ image: CGImage, _ path: String) {
    try? FileManager.default.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
    let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    precondition(CGImageDestinationFinalize(destination), "Could not write \(path)")
}
func json(_ object: Any, _ path: String) {
    try! JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: path))
}

// iOS: a full, opaque square; the system rounds the corners.
let iosArt = crop(0.8)
let appIcon = root + "/iWebCrawler/Resources/Assets.xcassets/AppIcon.appiconset"
write(render(1024, opaque: true) { context, s in context.draw(iosArt, in: CGRect(x: 0, y: 0, width: s, height: s)) }, appIcon + "/AppIcon.png")

// macOS: the rounded-square body of Apple's icon grid (824 of 1024) with a soft shadow.
func macIcon(_ size: Int) -> CGImage {
    render(size, opaque: false) { context, s in
        let inset = s * 100 / 1024, body = CGRect(x: inset, y: inset * 1.1, width: s - inset * 2, height: s - inset * 2)
        let shape = CGPath(roundedRect: body, cornerWidth: body.width * 0.225, cornerHeight: body.width * 0.225, transform: nil)
        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -s * 0.01), blur: s * 0.02, color: NSColor.black.withAlphaComponent(0.35).cgColor)
        context.addPath(shape); context.setFillColor(NSColor(red: 0.02, green: 0.02, blue: 0.04, alpha: 1).cgColor); context.fillPath()
        context.restoreGState()
        context.addPath(shape); context.clip()
        context.draw(iosArt, in: body)
    }
}
var images: [[String: Any]] = [["idiom": "universal", "platform": "ios", "size": "1024x1024", "filename": "AppIcon.png"]]
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "mac-\(size)@\(scale)x.png"
        write(macIcon(size * scale), appIcon + "/" + name)
        images.append(["idiom": "mac", "size": "\(size)x\(size)", "scale": "\(scale)x", "filename": name])
    }
}
json(["images": images, "info": ["author": "xcode", "version": 1]], appIcon + "/Contents.json")

// The round badge used inside the app, the widget and the browser extension.
let badgeArt = crop(0.74)
func badge(_ size: Int) -> CGImage {
    render(size, opaque: false) { context, s in
        context.addEllipse(in: CGRect(x: 0, y: 0, width: s, height: s)); context.clip()
        context.draw(badgeArt, in: CGRect(x: 0, y: 0, width: s, height: s))
    }
}
let logoSet = root + "/iWebCrawler/Resources/Brand.xcassets/Logo.imageset"
write(badge(512), logoSet + "/Logo.png")
json(["images": [["idiom": "universal", "filename": "Logo.png"]], "info": ["author": "xcode", "version": 1]], logoSet + "/Contents.json")
json(["info": ["author": "xcode", "version": 1]], root + "/iWebCrawler/Resources/Brand.xcassets/Contents.json")
for size in [16, 32, 48, 128] { write(badge(size), root + "/extension/icons/icon-\(size).png") }
print("Icons written: iOS, macOS, in-app logo and browser extension.")
