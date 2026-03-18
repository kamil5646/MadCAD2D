import Foundation
import RoomPlan

@MainActor
final class MadCADScanStore: ObservableObject {
    enum Route {
        case start
        case scan
        case review
        case export
    }

    @Published var route: Route = .start
    @Published var projectName: String = MadCADScanStore.defaultProjectName()
    @Published var exportBundle: ExportBundle?
    @Published var exportFileURL: URL?
    @Published var recentExports: [RecentExportRecord] = []
    @Published var exportErrorMessage: String?

    let captureController = RoomCaptureController()

    private let historyStore = ExportHistoryStore()
    private let exporter = RoomToMadCADExporter()

    init() {
        recentExports = historyStore.load()
    }

    var isSupportedDevice: Bool {
        DeviceSupport.isRoomPlanSupported
    }

    func startScan() {
        projectName = Self.defaultProjectName()
        exportBundle = nil
        exportFileURL = nil
        exportErrorMessage = nil
        route = .scan
        captureController.start()
    }

    func cancelScan() {
        route = .start
    }

    func rescan() {
        exportBundle = nil
        exportFileURL = nil
        exportErrorMessage = nil
        captureController.resetAndRestart()
    }

    func stopScan() {
        captureController.stop()
    }

    func prepareReviewIfPossible() {
        guard let room = captureController.capturedRoom else { return }
        do {
            let bundle = try exporter.export(room: room, roomName: projectName, deviceModel: DeviceSupport.modelIdentifier)
            exportBundle = bundle
            exportFileURL = try writeTemporaryFile(named: projectName, data: bundle.data)
            route = .review
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    func openExport() {
        guard exportBundle != nil else { return }
        persistRecentExportIfNeeded()
        route = .export
    }

    func goBackToReview() {
        route = .review
    }

    func finishAndReturnHome() {
        route = .start
    }

    private func persistRecentExportIfNeeded() {
        guard let bundle = exportBundle else { return }
        let record = RecentExportRecord(
            id: UUID(),
            name: fileSafeProjectName,
            exportedAt: Date(),
            wallCount: bundle.summary.wallCount,
            openingCount: bundle.summary.openingCount
        )
        if recentExports.first?.name == record.name, let latest = recentExports.first,
           abs(latest.exportedAt.timeIntervalSince(record.exportedAt)) < 5 {
            return
        }
        recentExports = [record] + recentExports.filter { $0.name != record.name }
        recentExports = Array(recentExports.prefix(8))
        historyStore.save(recentExports)
    }

    private func writeTemporaryFile(named projectName: String, data: Data) throws -> URL {
        let safe = projectName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "/", with: "-")
        let filename = (safe.isEmpty ? "Pomieszczenie" : safe) + ".madcad.json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    private var fileSafeProjectName: String {
        let trimmed = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Self.defaultProjectName() : trimmed
    }

    static func defaultProjectName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return "Pomieszczenie_\(formatter.string(from: Date()))"
    }
}
