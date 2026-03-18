import SwiftUI

struct StartView: View {
    @EnvironmentObject private var store: MadCADScanStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    recentExports
                }
                .padding(20)
            }
            .background(Color.black.opacity(0.97))
            .navigationTitle("MadCAD Scan")
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                BrandBadge(size: 58)
                VStack(alignment: .leading, spacing: 4) {
                    Text("MadCAD Scan")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.cyan)
                    Text("Skan pomieszczenia LiDAR")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
            }
            Text("Zeskanuj pomieszczenie i wyeksportuj gotowy plan 2D z wymiarami do pliku .madcad.json, który otworzysz w MadCAD na desktopie.")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                Label("Wymaga iPhone Pro z LiDAR", systemImage: "dot.radiowaves.left.and.right")
                Label("Eksport: ściany, otwory, wymiary", systemImage: "square.split.2x2")
                Label("Import w MadCAD: Pliki -> Wczytaj JSON", systemImage: "square.and.arrow.down")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            Button {
                store.startScan()
            } label: {
                Label("Nowy skan", systemImage: "viewfinder")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.cyan)
        }
        .padding(24)
        .background(
            LinearGradient(colors: [Color(red: 0.07, green: 0.11, blue: 0.18), Color(red: 0.06, green: 0.17, blue: 0.26)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08)))
    }

    private var recentExports: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ostatnie eksporty")
                .font(.headline)
            if store.recentExports.isEmpty {
                Text("Tutaj pojawią się ostatnio wyeksportowane skany.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                ForEach(store.recentExports) { record in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(record.name)
                            .font(.headline)
                        Text(record.exportedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text("Ściany: \(record.wallCount) • Otwory: \(record.openingCount)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.white.opacity(0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }
}
