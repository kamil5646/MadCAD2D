import SwiftUI

struct StartView: View {
    @EnvironmentObject private var store: MadCADScanStore

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero
                    modeGrid
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
                    Text("Pomiar uniwersalny")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
            }
            Text("To nie jest skaner planu pokoju. Appka zbiera uniwersalne punkty i wymiary, a dopiero później pozwala potraktować je jako bramę, balkon albo ogrodzenie.")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 8) {
                Label("Jeden capture flow dla wszystkich zastosowań", systemImage: "point.3.connected.trianglepath.dotted")
                Label("Soft snap do szerokości, wysokości i bazy", systemImage: "scope")
                Label("Import w MadCAD: Pliki -> Import pomiaru iPhone", systemImage: "square.and.arrow.down")
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(
            LinearGradient(colors: [Color(red: 0.07, green: 0.11, blue: 0.18), Color(red: 0.06, green: 0.17, blue: 0.26)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.white.opacity(0.08)))
    }

    private var modeGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nowy pomiar")
                .font(.headline)
            Button {
                store.startScan()
            } label: {
                UniversalCaptureCard()
            }
            .buttonStyle(.plain)
        }
    }

    private var recentExports: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ostatnie eksporty")
                .font(.headline)
            if store.recentExports.isEmpty {
                Text("Tutaj pojawią się ostatnio wyeksportowane zestawy wymiarów produktów.")
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 12)
            } else {
                ForEach(store.recentExports) { record in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(record.name)
                                .font(.headline)
                            Spacer(minLength: 8)
                            if let mode = record.productMode {
                                Text(mode.title)
                                    .font(.caption.weight(.semibold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.cyan.opacity(0.14))
                                    .clipShape(Capsule())
                            }
                        }
                        Text(record.exportedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let primaryMeasurement = record.primaryMeasurement {
                            Text(primaryMeasurement)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Referencja: \(record.wallCount) ścian • \(record.openingCount) otworów")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
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

private struct UniversalCaptureCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "viewfinder.circle")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(.cyan)
                .frame(width: 42, height: 42)
                .background(Color.cyan.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 6) {
                Text("Pomiar uniwersalny")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Złap początek, koniec, wysokość, bazę i punkt montażowy")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Dopiero w potwierdzeniu wybierzesz, czy traktować wynik jako bramę, balkon czy ogrodzenie.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.06)))
    }
}
