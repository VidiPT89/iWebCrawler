import SwiftUI
#if os(macOS)
import SafariServices
#endif

struct SettingsView: View {
    @EnvironmentObject private var prefs: Preferences
    @Environment(\.colorScheme) private var scheme
    @ObservedObject var model: CrawlerModel
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(prefs.text("Idioma", "Language"), selection: $prefs.language) {
                        ForEach(AppLanguage.allCases) { language in Text(language.title).tag(language) }
                    }.accessibilityIdentifier("settings.language")
                    Picker(prefs.text("Aparência", "Appearance"), selection: $prefs.appearance) {
                        Text(prefs.text("Sistema", "System")).tag(AppAppearance.system)
                        Text(prefs.text("Claro", "Light")).tag(AppAppearance.light)
                        Text(prefs.text("Escuro", "Dark")).tag(AppAppearance.dark)
                    }.pickerStyle(.segmented).accessibilityIdentifier("settings.appearance")
                } header: { Text(prefs.text("À tua maneira", "Make it yours")) }
                Section {
                    Picker(prefs.text("Velocidade", "Speed"), selection: $prefs.speed) {
                        Text("0.5×").tag(0.5); Text("1×").tag(1.0); Text("2×").tag(2.0); Text("4×").tag(4.0)
                    }.pickerStyle(.segmented)
                    Toggle(prefs.text("Reduzir movimento", "Reduce motion"), isOn: $prefs.reducedMotion)
                    Text(prefs.text("A preferência de acessibilidade do dispositivo também é respeitada.", "Your device’s accessibility preference is also respected.")).font(.caption).foregroundStyle(.secondary)
                } header: { Text(prefs.text("Movimento", "Motion")) }
                Section {
                    Toggle(prefs.text("Seguir ligações do mesmo site", "Follow links on the same website"), isOn: $prefs.followLinks)
                        .onChange(of: prefs.followLinks) { _, value in if !value { model.pause() } }
                    Stepper(prefs.text("Limite de páginas", "Page limit") + ": \(prefs.pageLimit)", value: $prefs.pageLimit, in: 1...20)
                    Text(prefs.text("Exploração em primeiro plano, com 2 segundos entre páginas. O seguimento automático respeita o robots.txt de cada site. Usa-o apenas em sites onde tens autorização.", "Foreground exploration, with 2 seconds between pages. Automatic following respects each website’s robots.txt. Only use it on websites you have permission to crawl.")).font(.caption).foregroundStyle(.secondary)
                } header: { Text(prefs.text("Exploração", "Exploration")) }
                Section {
                    #if os(macOS)
                    Button(prefs.text("Ativar no Safari", "Turn on in Safari")) {
                        Task { try? await SFSafariApplication.showPreferencesForExtension(withIdentifier: "dev.ividi.iwebcrawler.safari") }
                    }
                    Text(prefs.text("A aranha explora a página aberta no Safari e recolhe as ligações, sem sair do browser.", "The spider explores the page open in Safari and collects its links, without leaving the browser.")).font(.caption).foregroundStyle(.secondary)
                    #else
                    Text(prefs.text("No Safari: Definições › Apps › Safari › Extensões › iWebCrawler. Depois toca em “aA” na barra de endereço.", "In Safari: Settings › Apps › Safari › Extensions › iWebCrawler. Then tap “aA” in the address bar.")).font(.caption).foregroundStyle(.secondary)
                    #endif
                    Link(prefs.text("Chrome, Brave, Edge, Opera e Firefox", "Chrome, Brave, Edge, Opera and Firefox"), destination: URL(string: "https://github.com/VidiPT89/iWebCrawler/releases/latest")!)
                        .foregroundStyle(Brand.accent(scheme))
                } header: { Text(prefs.text("Extensão do browser", "Browser extension")) }
                Section {
                    HStack(spacing: 14) {
                        LogoMark(size: 46)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("iWebCrawler").font(.headline)
                            Text(prefs.text("Versão \(version) · Uma ligação de cada vez.", "Version \(version) · One link at a time.")).font(.caption).foregroundStyle(.secondary)
                        }
                    }.padding(.vertical, 4)
                    CreditsView().frame(maxWidth: .infinity).padding(.vertical, 12)
                    Text(prefs.text("Sem contas, análises de utilização ou servidor próprio. Os sites que visitas recebem os pedidos normais de navegação, e a verificação de ligações contacta cada endereço verificado. O histórico fica apenas neste dispositivo.", "No accounts, analytics or backend. Websites you visit receive normal browsing requests, and link checking contacts each checked address. Your history stays on this device only.")).font(.caption).foregroundStyle(.secondary)
                    Link(prefs.text("Política de privacidade", "Privacy policy"), destination: URL(string: "https://github.com/VidiPT89/iWebCrawler/blob/main/PRIVACY.md")!)
                        .foregroundStyle(Brand.accent(scheme))
                    Button(prefs.text("Rever apresentação", "Replay introduction")) {
                        model.pause(); model.showSettings = false; model.showSplash = true
                    }
                } header: { Text(prefs.text("Sobre", "About")) }
            }
            .formStyle(.grouped)
            .navigationTitle(prefs.text("Definições", "Settings"))
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button(prefs.text("Concluído", "Done")) { model.showSettings = false } } }
        }
        .tint(Brand.accent(scheme))
        .preferredColorScheme(prefs.appearance.scheme)
        #if os(macOS)
        .frame(width: 540, height: 560)
        #endif
    }
}
