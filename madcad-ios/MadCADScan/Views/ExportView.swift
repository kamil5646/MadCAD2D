import SwiftUI

struct ExportView: View {
    @EnvironmentObject private var store: MadCADScanStore
    @State private var isExporterPresented = false

    var body: some View {
        let document = store.exportBundle.map { MadCADScanDocument(data: $0.data) }
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Plik gotowy")
                    .font(.largeTitle.bold())
                Text("Zapisz plik do Files albo wyślij go przez Share Sheet. Potem w desktopowym MadCAD użyj Pliki -> Wczytaj JSON.")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Nazwa")
                        .font(.headline)
                    Text((store.projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? MadCADScanStore.defaultProjectName() : store.projectName) + ".madcad.json")
                        .font(.system(.body, design: .monospaced))
                }
                .padding(18)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button {
                    isExporterPresented = true
                } label: {
                    Label("Zapisz do Files", systemImage: "folder.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)

                if let url = store.exportFileURL {
                    ShareLink(item: url) {
                        Label("Udostępnij", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                Button("Wróć do podglądu") {
                    store.goBackToReview()
                }
                .buttonStyle(.bordered)

                Button("Gotowe") {
                    store.finishAndReturnHome()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Spacer(minLength: 0)
            }
            .padding(20)
            .background(Color.black)
            .navigationTitle("Eksport")
        }
        .fileExporter(
            isPresented: $isExporterPresented,
            document: document,
            contentType: .madCADJSON,
            defaultFilename: (store.projectName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? MadCADScanStore.defaultProjectName() : store.projectName) + ".madcad"
        ) { _ in }
    }
}
