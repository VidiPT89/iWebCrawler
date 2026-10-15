import SwiftUI

/// The iWebCrawler logo: an amber spider inside a circuit-like web.
struct LogoMark: View {
    var size: CGFloat = 42
    var glow = false
    var body: some View {
        Image("Logo").resizable().interpolation(.high).frame(width: size, height: size)
            .shadow(color: glow ? Brand.orange.opacity(0.45) : .clear, radius: size * 0.16)
            .accessibilityHidden(true)
    }
}

struct OrbitArtwork: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduced
    @EnvironmentObject private var prefs: Preferences
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: systemReduced || prefs.reducedMotion)) { timeline in
            let time = systemReduced || prefs.reducedMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2), radius = min(size.width, size.height) * 0.34
                for ring in 1...3 {
                    let r = radius * Double(ring) / 3
                    context.stroke(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)), with: .color(Brand.amber.opacity(0.15)), style: StrokeStyle(lineWidth: 1, dash: ring == 2 ? [3, 7] : []))
                }
                for i in 0..<12 {
                    let a = Double(i) * .pi / 6 + time * 0.055, r = radius * (i.isMultiple(of: 3) ? 1.18 : 0.85)
                    let point = CGPoint(x: center.x + cos(a) * r, y: center.y + sin(a) * r)
                    var line = Path(); line.move(to: center); line.addLine(to: point)
                    context.stroke(line, with: .color(Brand.amber.opacity(0.24)), lineWidth: 1)
                    let dot = i.isMultiple(of: 3) ? 4.0 : 2.5
                    context.fill(Path(ellipseIn: CGRect(x: point.x - dot, y: point.y - dot, width: dot * 2, height: dot * 2)), with: .color(i.isMultiple(of: 3) ? Brand.orange : Brand.gold.opacity(0.7)))
                }
            }
        }.overlay { LogoMark(size: 150, glow: true) }.accessibilityHidden(true)
    }
}

struct CreditsView: View {
    @EnvironmentObject private var prefs: Preferences
    var body: some View {
        VStack(spacing: 9) {
            Text(prefs.text("Desenvolvido por David Arsénio Martins", "Developed by David Arsénio Martins")).font(.caption.weight(.medium)).multilineTextAlignment(.center)
            HStack(spacing: 20) {
                Link("ividi.dev", destination: URL(string: "https://ividi.dev/")!)
                Text("·").foregroundStyle(.tertiary)
                Link("GitHub / VidiPT89", destination: URL(string: "https://github.com/VidiPT89/")!)
            }.font(.caption).tint(Brand.amber)
        }
    }
}

struct SplashView: View {
    @EnvironmentObject private var prefs: Preferences
    @Environment(\.colorScheme) private var scheme
    let dismiss: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            Text(prefs.text("iVidi.dev / EXPLORAÇÕES", "iVidi.dev / EXPLORATIONS")).font(.system(size: 10, weight: .medium, design: .monospaced)).tracking(4).foregroundStyle(Brand.accent(scheme))
            OrbitArtwork().frame(maxWidth: 340).frame(height: 270)
            Text("iWebCrawler").font(.system(size: 42, weight: .semibold, design: .rounded)).tracking(-2)
            Text(prefs.text("Uma ligação. Infinitas descobertas.", "One link. Endless discoveries.")).font(.subheadline).foregroundStyle(.secondary).padding(.top, 12)
            Spacer()
            CreditsView().padding(.bottom, 28)
            Button(prefs.text("Começar", "Get started"), action: dismiss).font(.caption).buttonStyle(.plain).foregroundStyle(.secondary).padding(.bottom, 24)
        }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Brand.background(scheme))
    }
}

struct ActionButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduce
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(.black).padding(.horizontal, 22).padding(.vertical, 13)
            .background(Brand.gradient, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.16)))
            .scaleEffect(configuration.isPressed && !reduce ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.86 : 1)
            .animation(reduce ? nil : .easeOut(duration: 0.18), value: configuration.isPressed)
    }
}
