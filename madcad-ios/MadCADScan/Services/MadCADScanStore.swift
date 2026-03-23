import CoreGraphics
import Foundation
import RoomPlan
import simd

@MainActor
final class MadCADScanStore: ObservableObject {
    enum Route {
        case start
        case scan
        case review
        case export
    }

    @Published var route: Route = .start
    @Published var selectedProductMode: ProductMode = .gate
    @Published var projectName: String = MadCADScanStore.defaultProjectName()
    @Published var captureStepIndex: Int = 0
    @Published var capturePoints: [CapturedMeasurementPoint] = []
    @Published var measurementDraft: ProductMeasurementDraft?
    @Published var reviewPreview: ExportPreview?
    @Published var reviewSummary: ExportSummary?
    @Published var reviewStepIndex: Int = 0
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
        captureStepIndex = 0
        capturePoints = []
        measurementDraft = nil
        reviewPreview = nil
        reviewSummary = nil
        reviewStepIndex = 0
        exportBundle = nil
        exportFileURL = nil
        exportErrorMessage = nil
        route = .scan
        captureController.start()
        captureController.instructionText = captureSteps().first?.prompt ?? "Dotknij punktu w kamerze, aby rozpocząć pomiar."
    }

    func cancelScan() {
        captureStepIndex = 0
        capturePoints = []
        route = .start
    }

    func rescan() {
        exportBundle = nil
        exportFileURL = nil
        exportErrorMessage = nil
        reviewPreview = nil
        reviewSummary = nil
        measurementDraft = nil
        reviewStepIndex = 0
        captureStepIndex = 0
        capturePoints = []
        captureController.resetAndRestart()
    }

    func stopScan() {
        captureController.stop()
        if captureController.capturedRoom != nil {
            prepareReviewIfPossible()
        } else {
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(600))
                guard self.route == .scan else { return }
                self.prepareReviewIfPossible()
            }
        }
    }

    func prepareReviewIfPossible() {
        guard route == .scan else { return }
        guard let room = captureController.capturedRoom else { return }
        do {
            let review = try exporter.buildProductReview(room: room, mode: selectedProductMode)
            var measurements = review.measurements
            applyCaptureMeasurements(to: &measurements)
            measurementDraft = measurements
            reviewPreview = review.preview
            reviewSummary = review.summary
            reviewStepIndex = 0
            exportBundle = nil
            exportFileURL = nil
            route = .review
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    func updateMeasurements(_ update: (inout ProductMeasurementDraft) -> Void) {
        guard var draft = measurementDraft else { return }
        update(&draft)
        measurementDraft = draft.clamped()
    }

    func openExport() {
        guard let room = captureController.capturedRoom, let draft = measurementDraft else { return }
        do {
            let bundle = try exporter.exportProduct(
                room: room,
                projectName: fileSafeProjectName,
                deviceModel: DeviceSupport.modelIdentifier,
                measurements: draft
            )
            exportBundle = bundle
            exportFileURL = try writeTemporaryFile(named: fileSafeProjectName, data: bundle.data)
            persistRecentExportIfNeeded(bundle: bundle, draft: draft)
            route = .export
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    func goBackToReview() {
        route = .review
    }

    func finishAndReturnHome() {
        captureStepIndex = 0
        reviewStepIndex = 0
        capturePoints = []
        route = .start
    }

    func goToNextCaptureStep(total: Int) {
        guard total > 0 else { return }
        captureStepIndex = min(captureStepIndex + 1, total - 1)
        let steps = captureSteps()
        let step = steps[min(captureStepIndex, max(steps.count - 1, 0))]
        captureController.instructionText = step.prompt
    }

    func goToPreviousCaptureStep() {
        captureStepIndex = max(0, captureStepIndex - 1)
        let steps = captureSteps()
        let step = steps[min(captureStepIndex, max(steps.count - 1, 0))]
        captureController.instructionText = step.prompt
    }

    func registerCaptureTap(at point: CGPoint, in viewSize: CGSize) {
        let steps = captureSteps()
        let step = steps[min(captureStepIndex, max(steps.count - 1, 0))]
        do {
            let worldPoint = try captureController.raycastWorldPoint(from: point, in: viewSize)
            let snappedPoint = applySoftSnap(to: worldPoint, for: step.id)
            let normalized = NormalizedScreenPoint(
                x: max(0, min(1, viewSize.width > 0 ? point.x / viewSize.width : 0)),
                y: max(0, min(1, viewSize.height > 0 ? point.y / viewSize.height : 0))
            )
            let capture = CapturedMeasurementPoint(
                id: UUID(),
                stepID: step.id,
                title: step.title,
                normalizedPoint: normalized,
                worldX: Double(snappedPoint.x),
                worldY: Double(snappedPoint.y),
                worldZ: Double(snappedPoint.z)
            )
            capturePoints.removeAll { $0.stepID == step.id }
            capturePoints.append(capture)
            captureController.instructionText = "Uchwycono punkt dla etapu: \(step.title). Jeśli trzeba, dotknij jeszcze raz, aby poprawić."
        } catch {
            exportErrorMessage = error.localizedDescription
        }
    }

    func isCaptureStepCompleted(_ stepID: String) -> Bool {
        capturePoints.contains { $0.stepID == stepID }
    }

    func capturePoint(for stepID: String) -> CapturedMeasurementPoint? {
        capturePoints.first { $0.stepID == stepID }
    }

    func goToNextReviewStep(total: Int) {
        guard total > 0 else { return }
        reviewStepIndex = min(reviewStepIndex + 1, total - 1)
    }

    func goToPreviousReviewStep() {
        reviewStepIndex = max(0, reviewStepIndex - 1)
    }

    func resetReviewWizard() {
        reviewStepIndex = 0
    }

    func applyProductMode(_ mode: ProductMode) {
        selectedProductMode = mode
        guard var draft = measurementDraft else { return }
        draft.mode = mode

        switch mode {
        case .gate:
            draft.gateLeafCount = max(1, min(2, draft.gateLeafCount == 1 ? 2 : draft.gateLeafCount))
            draft.groundClearanceMm = max(20, draft.groundClearanceMm)
            draft.basePlateHeightMm = 0
            draft.postWidthMm = max(60, draft.postWidthMm)
            draft.postLengthMm = max(draft.heightMm + 200, draft.postLengthMm)
            if draft.infillPattern == "horizontal" {
                draft.infillPattern = "vertical"
            }
        case .balcony:
            draft.gateLeafCount = 1
            draft.groundClearanceMm = 0
            draft.basePlateHeightMm = 0
            draft.postWidthMm = max(40, draft.postWidthMm)
            draft.postLengthMm = max(1000, min(draft.postLengthMm, 1600))
            draft.innerFrame = false
            draft.diagonal = false
            draft.infillPattern = draft.infillPattern == "cross" ? "horizontal" : draft.infillPattern
        case .fence:
            draft.gateLeafCount = 1
            draft.groundClearanceMm = max(20, draft.groundClearanceMm)
            draft.basePlateHeightMm = max(0, draft.basePlateHeightMm)
            draft.postWidthMm = max(50, draft.postWidthMm)
            draft.postLengthMm = max(draft.heightMm + 200, draft.postLengthMm)
            draft.innerFrame = false
            draft.diagonal = false
            if draft.infillPattern == "cross" {
                draft.infillPattern = "horizontal"
            }
        }

        measurementDraft = draft.clamped()
    }

    private func persistRecentExportIfNeeded(bundle: ExportBundle, draft: ProductMeasurementDraft) {
        let record = RecentExportRecord(
            id: UUID(),
            name: fileSafeProjectName,
            exportedAt: Date(),
            wallCount: bundle.summary.wallCount,
            openingCount: bundle.summary.openingCount,
            productMode: draft.mode,
            primaryMeasurement: "\(Int(draft.widthMm.rounded())) x \(Int(draft.heightMm.rounded())) mm"
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
        let filename = (safe.isEmpty ? selectedProductMode.defaultProjectPrefix : safe) + ".madcad.json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    private var fileSafeProjectName: String {
        let trimmed = projectName.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Self.defaultProjectName() : trimmed
    }

    static func defaultProjectName(for mode: ProductMode) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return "\(mode.defaultProjectPrefix)_\(formatter.string(from: Date()))"
    }

    static func defaultProjectName() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pl_PL")
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return "Pomiar_\(formatter.string(from: Date()))"
    }

    private func applyCaptureMeasurements(to draft: inout ProductMeasurementDraft) {
        if let start = capturePoint(for: "span-start"), let end = capturePoint(for: "span-end") {
            draft.widthMm = max(200, horizontalDistanceMm(start, end))
        }
        if let top = capturePoint(for: "height-top"), let start = capturePoint(for: "span-start"), let end = capturePoint(for: "span-end") {
            draft.heightMm = max(200, verticalDistanceMm(top, midpoint(start, end)))
        }
        if let base = capturePoint(for: "ground-base"), let start = capturePoint(for: "span-start"), let end = capturePoint(for: "span-end") {
            let baseHeight = max(0, verticalDistanceMm(midpoint(start, end), base))
            draft.groundClearanceMm = baseHeight
            draft.basePlateHeightMm = baseHeight
        }
        if let support = capturePoint(for: "support"), let start = capturePoint(for: "span-start"), let end = capturePoint(for: "span-end") {
            let postWidth = horizontalDistanceMm(midpoint(start, end), support)
            draft.postWidthMm = max(20, min(300, postWidth))
        }
        draft = draft.clamped()
    }

    private func horizontalDistanceMm(_ a: CapturedMeasurementPoint, _ b: CapturedMeasurementPoint) -> Double {
        let dx = a.worldX - b.worldX
        let dz = a.worldZ - b.worldZ
        return hypot(dx, dz) * 1000.0
    }

    private func verticalDistanceMm(_ upper: CapturedMeasurementPoint, _ lower: CapturedMeasurementPoint) -> Double {
        abs(upper.worldY - lower.worldY) * 1000.0
    }

    private func midpoint(_ a: CapturedMeasurementPoint, _ b: CapturedMeasurementPoint) -> CapturedMeasurementPoint {
        CapturedMeasurementPoint(
            id: UUID(),
            stepID: "midpoint",
            title: "Midpoint",
            normalizedPoint: NormalizedScreenPoint(
                x: (a.normalizedPoint.x + b.normalizedPoint.x) / 2,
                y: (a.normalizedPoint.y + b.normalizedPoint.y) / 2
            ),
            worldX: (a.worldX + b.worldX) / 2,
            worldY: (a.worldY + b.worldY) / 2,
            worldZ: (a.worldZ + b.worldZ) / 2
        )
    }

    func captureSteps() -> [CaptureStepDefinition] {
        [
            CaptureStepDefinition(id: "span-start", title: "Punkt początkowy", subtitle: "Złap pierwszy dolny punkt odcinka", prompt: "Dotknij pierwszego dolnego punktu mierzonego odcinka."),
            CaptureStepDefinition(id: "span-end", title: "Punkt końcowy", subtitle: "Złap drugi dolny punkt odcinka", prompt: "Dotknij drugiego dolnego punktu, aby określić szerokość lub długość."),
            CaptureStepDefinition(id: "height-top", title: "Górna krawędź", subtitle: "Złap górny punkt wysokości", prompt: "Dotknij najwyższego punktu, który ma wyznaczać wysokość produktu."),
            CaptureStepDefinition(id: "ground-base", title: "Baza / grunt", subtitle: "Złap dolną linię odniesienia", prompt: "Dotknij gruntu, podmurówki albo dolnej bazy montażowej."),
            CaptureStepDefinition(id: "support", title: "Punkt montażowy", subtitle: "Złap słupek, ścianę albo punkt podparcia", prompt: "Dotknij punktu montażowego lub referencji konstrukcyjnej.")
        ]
    }

    private func applySoftSnap(to point: simd_float3, for stepID: String) -> simd_float3 {
        var result = point

        if stepID == "span-end", let start = capturePoint(for: "span-start") {
            let dx = Double(point.x) - start.worldX
            let dz = Double(point.z) - start.worldZ
            if abs(dx) > abs(dz) * 1.8 {
                result.z = Float(start.worldZ)
            } else if abs(dz) > abs(dx) * 1.8 {
                result.x = Float(start.worldX)
            }
            result.y = Float(start.worldY)
        }

        if stepID == "height-top", let start = capturePoint(for: "span-start"), let end = capturePoint(for: "span-end") {
            let mid = midpoint(start, end)
            result.x = Float(mid.worldX)
            result.z = Float(mid.worldZ)
        }

        if stepID == "ground-base", let start = capturePoint(for: "span-start"), let end = capturePoint(for: "span-end") {
            let mid = midpoint(start, end)
            result.x = Float(mid.worldX)
            result.z = Float(mid.worldZ)
        }

        return result
    }
}
