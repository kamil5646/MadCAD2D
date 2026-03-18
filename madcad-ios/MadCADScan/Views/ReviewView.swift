import SwiftUI

struct ReviewView: View {
    @EnvironmentObject private var store: MadCADScanStore

    var body: some View {
        let bundle = store.exportBundle
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if let bundle {
                        previewCard(bundle)
                        details(bundle)
                    } else {
                        ContentUnavailableView("Brak danych skanu", systemImage: "exclamationmark.triangle")
                    }
                }
                .padding(20)
            }
            .navigationTitle("Podgląd")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Wróć") {
                        store.route = .start
                    }
                }
            }
        }
    }

    private func previewCard(_ bundle: ExportBundle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Plan 2D")
                .font(.headline)
            PlanPreviewCanvas(preview: bundle.preview)
                .frame(height: 320)
                .background(Color(red: 0.06, green: 0.08, blue: 0.11))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private func details(_ bundle: ExportBundle) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Eksport")
                .font(.headline)
            TextField("Nazwa projektu", text: $store.projectName)
                .textFieldStyle(.roundedBorder)
                .onChange(of: store.projectName) { _, _ in
                    store.prepareReviewIfPossible()
                }

            HStack {
                metric("Ściany", value: bundle.summary.wallCount)
                metric("Otwory", value: bundle.summary.openingCount)
                metric("Wymiary", value: bundle.summary.dimensionCount)
            }

            Text("Plik zostanie zapisany jako .madcad.json i otworzysz go w desktopowym MadCAD przez Pliki -> Wczytaj JSON.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button {
                store.openExport()
            } label: {
                Label("Przejdź do eksportu", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.cyan)
        }
        .padding(18)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func metric(_ label: String, value: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(value)")
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
