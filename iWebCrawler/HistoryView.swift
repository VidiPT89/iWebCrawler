import SwiftUI

struct HistoryView: View {
    @ObservedObject var model: CrawlerModel
    @ObservedObject var history: HistoryStore
    @EnvironmentObject private var prefs: Preferences
    @Environment(\.colorScheme) private var scheme
    @State private var confirmClear = false
    var body: some View {
        NavigationStack {
            Group {
                if history.items.isEmpty {
                    ContentUnavailableView {
                        Label(prefs.text("Ainda sem explorações", "No explorations yet"), systemImage: "clock.arrow.circlepath")
                    } description: {
                        Text(prefs.text("Abre um site e explora-o. Cada coleção fica guardada aqui, neste dispositivo, para a reabrires e continuares mais tarde.", "Open a website and explore it. Each collection is saved here, on this device, so you can reopen and continue it later."))
                    }
                } else {
                    List {
                        ForEach(history.items) { item in
                            Button { model.restore(item) } label: { row(item) }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(prefs.text("Reabrir e continuar", "Reopen and continue")) { model.restore(item) }
                                    Button(prefs.text("Apagar", "Delete"), role: .destructive) { history.delete(item.id) }
                                }
                        }
                        .onDelete { offsets in offsets.map { history.items[$0].id }.forEach(history.delete) }
                    }
                }
            }
            .navigationTitle(prefs.text("Histórico", "History"))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button(prefs.text("Fechar", "Close")) { model.showHistory = false } }
                if !history.items.isEmpty {
                    ToolbarItem(placement: .destructiveAction) { Button(prefs.text("Apagar tudo", "Delete all"), role: .destructive) { confirmClear = true } }
                }
            }
            .confirmationDialog(prefs.text("Apagar todo o histórico?", "Delete all history?"), isPresented: $confirmClear, titleVisibility: .visible) {
                Button(prefs.text("Apagar tudo", "Delete all"), role: .destructive) { history.clear() }
                Button(prefs.text("Cancelar", "Cancel"), role: .cancel) {}
            } message: {
                Text(prefs.text("As coleções guardadas neste dispositivo deixam de existir. Os ficheiros que exportaste não são afetados.", "Collections saved on this device will be removed. Files you exported are not affected."))
            }
        }
        .tint(Brand.accent(scheme))
        #if os(macOS)
        .frame(width: 560, height: 520)
        #endif
    }
    private func row(_ item: Exploration) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "globe").font(.system(size: 18, weight: .light)).foregroundStyle(Brand.accent(scheme)).frame(width: 30)
            VStack(alignment: .leading, spacing: 4) {
                Text(item.host).font(.system(.body, design: .rounded, weight: .semibold)).lineLimit(1)
                Text(summary(item)).font(.caption).foregroundStyle(.secondary)
                Text(item.date.formatted(.dateTime.day().month(.abbreviated).year().hour().minute().locale(Locale(identifier: prefs.language.rawValue))))
                    .font(.system(size: 10, design: .monospaced)).foregroundStyle(.tertiary)
            }
            Spacer()
            Image(systemName: "arrow.uturn.forward").font(.caption).foregroundStyle(.tertiary)
        }.padding(.vertical, 6).contentShape(Rectangle())
    }
    private func summary(_ item: Exploration) -> String {
        func count(_ n: Int, _ pt: (String, String), _ en: (String, String)) -> String {
            "\(n) " + (n == 1 ? prefs.text(pt.0, en.0) : prefs.text(pt.1, en.1))
        }
        return [count(item.discoveries.count, ("ligação", "ligações"), ("link", "links")),
                count(item.referenceCount, ("referência", "referências"), ("reference", "references")),
                count(item.pages.count, ("página", "páginas"), ("page", "pages"))].joined(separator: " · ")
    }
}
