import SwiftUI

struct ExportView: View {
    @EnvironmentObject private var store: MadCADScanStore
    @State private var isExporterPresented = false

    var body: some View {
        let document = store.exportBundle.map { MadCADScanDocument(data: $0.data) }
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Eksport wymiarów")
                    .font(.largeTitle.bold())
                Text("Zapisz plik do Files albo wyślij go przez Share Sheet. Na desktopie MadCAD użyj `Pliki -> Import pomiaru iPhone`, a aplikacja zapyta, czy tylko zasilić formularz `Stal`, czy od razu wygenerować geometrię.")
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

                VStack(alignment: .leading, spacing: 8) {
                    Text("Co trafia do pliku")
                        .font(.headline)
                    Label("Tryb produktu i potwierdzone wymiary", systemImage: "ruler")
                    Label("Parametry montażowe potrzebne w karcie Stal", systemImage: "slider.horizontal.3")
                    Label("Opcjonalna techniczna referencja ze skanu", systemImage: "square.dashed")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
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

                Button("Wróć do potwierdzenia") {
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
