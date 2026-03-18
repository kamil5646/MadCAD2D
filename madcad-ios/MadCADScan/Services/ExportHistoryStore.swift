import Foundation

@MainActor
final class ExportHistoryStore {
    private let defaults = UserDefaults.standard
    private let key = "madcad.scan.recentExports"

    func load() -> [RecentExportRecord] {
        guard let data = defaults.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([RecentExportRecord].self, from: data)) ?? []
    }

    func save(_ records: [RecentExportRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: key)
    }
}
