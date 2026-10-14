import AppKit
import ImageIO
import UniformTypeIdentifiers

let output = CommandLine.arguments[1]
let fm = FileManager.default
try fm.createDirectory(atPath: output, withIntermediateDirectories: true)
func drawIcon(size: Int, path: String) throws {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = context
    let s = CGFloat(size), center = CGPoint(x: s / 2, y: s / 2)
    NSColor(calibratedRed: 0.045, green: 0.04, blue: 0.035, alpha: 1).setFill()
    NSBezierPath(rect: CGRect(x: 0, y: 0, width: s, height: s)).fill()
    let amber = NSColor(calibratedRed: 0.96, green: 0.63, blue: 0.12, alpha: 1)
    let orange = NSColor(calibratedRed: 0.91, green: 0.33, blue: 0.08, alpha: 1)
    for radius in [0.26, 0.37, 0.46] {
        amber.withAlphaComponent(0.15).setStroke()
        let path = NSBezierPath(ovalIn: CGRect(x: center.x - s * radius, y: center.y - s * radius, width: s * radius * 2, height: s * radius * 2))
        path.lineWidth = s * 0.002; path.stroke()
    }
    for i in 0..<8 {
        let side: CGFloat = i < 4 ? -1 : 1, leg = CGFloat(i % 4)
        let path = NSBezierPath(); path.lineWidth = s * 0.019; path.lineCapStyle = .round; path.lineJoinStyle = .round
        path.move(to: CGPoint(x: center.x + side * s * 0.08, y: center.y + (leg - 1.5) * s * 0.055))
        path.line(to: CGPoint(x: center.x + side * s * (0.22 + abs(leg - 1.5) * 0.02), y: center.y + (leg - 1.5) * s * 0.15))
        let end = CGPoint(x: center.x + side * s * 0.34, y: center.y + (leg - 1.5) * s * 0.22)
        path.line(to: end); (i.isMultiple(of: 2) ? amber : orange).setStroke(); path.stroke()
        amber.setFill(); NSBezierPath(ovalIn: CGRect(x: end.x - s * 0.013, y: end.y - s * 0.013, width: s * 0.026, height: s * 0.026)).fill()
    }
    let body = NSBezierPath(ovalIn: CGRect(x: center.x - s * 0.11, y: center.y - s * 0.22, width: s * 0.22, height: s * 0.32))
    NSGradient(starting: orange, ending: amber)!.draw(in: body, angle: 75)
    amber.setFill(); NSBezierPath(ovalIn: CGRect(x: center.x - s * 0.065, y: center.y + s * 0.115, width: s * 0.13, height: s * 0.13)).fill()
    NSColor.black.withAlphaComponent(0.7).setFill()
    for x: CGFloat in [-0.025, 0.025] { NSBezierPath(ovalIn: CGRect(x: center.x + s * x - s * 0.008, y: center.y + s * 0.19, width: s * 0.016, height: s * 0.016)).fill() }
    NSGraphicsContext.restoreGraphicsState()
    let rgb = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    rgb.draw(rep.cgImage!, in: CGRect(x: 0, y: 0, width: size, height: size))
    let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, UTType.png.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, rgb.makeImage()!, nil)
    guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
}
var images: [[String: Any]] = []
try drawIcon(size: 1024, path: output + "/AppIcon.png")
images.append(["idiom": "universal", "platform": "ios", "size": "1024x1024", "filename": "AppIcon.png"])
for size in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let filename = "mac-\(size)@\(scale)x.png"
        try drawIcon(size: size * scale, path: output + "/" + filename)
        images.append(["idiom": "mac", "size": "\(size)x\(size)", "scale": "\(scale)x", "filename": filename])
    }
}
let json: [String: Any] = ["images": images, "info": ["author": "David Arsénio Martins", "version": 1]]
try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: output + "/Contents.json"))
