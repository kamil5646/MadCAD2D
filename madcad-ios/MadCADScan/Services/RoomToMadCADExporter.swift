import Foundation
import RoomPlan
import simd

struct ProductReviewBundle {
    let measurements: ProductMeasurementDraft
    let preview: ExportPreview
    let summary: ExportSummary
}

struct RoomToMadCADExporter {
    private enum LayerName {
        static let reference = "REFERENCJE"
    }

    private let isoFormatter = ISO8601DateFormatter()

    func buildProductReview(room: CapturedRoom, mode: ProductMode) throws -> ProductReviewBundle {
        let preview = try buildReferencePreview(room: room)
        let measurements = suggestMeasurements(for: mode, room: room, preview: preview)
        return ProductReviewBundle(
            measurements: measurements,
            preview: preview,
            summary: ExportSummary(
                wallCount: preview.walls.count,
                openingCount: preview.openings.count,
                dimensionCount: preview.dimensions.count
            )
        )
    }

    func exportProduct(
        room: CapturedRoom,
        projectName: String,
        deviceModel: String,
        measurements draft: ProductMeasurementDraft
    ) throws -> ExportBundle {
        let preview = try buildReferencePreview(room: room)
        let draft = draft.clamped()
        let referenceLayer = MadCADLayer(id: UUID().uuidString, name: LayerName.reference, visible: true, locked: false)
        let payload = MadCADProjectPayload(
            version: 3,
            exportedAt: isoFormatter.string(from: Date()),
            entities: [],
            layers: [referenceLayer],
            activeLayerId: referenceLayer.id,
            scanMeta: MadCADScanMeta(
                source: "madcad-scan-product",
                deviceModel: deviceModel,
                capturedAt: isoFormatter.string(from: Date()),
                roomName: nil,
                projectName: projectName,
                boundsMm: MadCADScanBounds(minX: preview.bounds.minX, minY: preview.bounds.minY, maxX: preview.bounds.maxX, maxY: preview.bounds.maxY),
                productMode: draft.mode,
                measurements: draft.asExport(),
                referencePlan: makeReferencePlan(from: preview)
            )
        )

        let data = try JSONEncoder.prettyPrinted.encode(payload)
        return ExportBundle(
            payload: payload,
            data: data,
            preview: preview,
            summary: ExportSummary(
                wallCount: preview.walls.count,
                openingCount: preview.openings.count,
                dimensionCount: preview.dimensions.count
            )
        )
    }

    private func buildReferencePreview(room: CapturedRoom) throws -> ExportPreview {
        let walls = room.walls.compactMap(makeWallSegment)
        let openings = uniqueOpenings(from: room).compactMap(makeOpeningRect)

        guard let rawBounds = PlanBounds.from(segments: walls, rects: openings), !walls.isEmpty else {
            throw ExportError.noUsableWalls
        }

        let normalizedWalls = walls.map { normalize(segment: $0, bounds: rawBounds) }
        let normalizedOpenings = openings.map { normalize(rect: $0, bounds: rawBounds) }
        let normalizedBounds = PlanBounds.from(segments: normalizedWalls, rects: normalizedOpenings) ?? rawBounds
        let roomCenter = normalizedBounds.center
        let dimensions = normalizedWalls.map { wall in
            let dimPoint = dimensionPoint(for: wall, roomCenter: roomCenter)
            return PlanSegment(id: wall.id, start: wall.start, end: dimPoint, layerName: "WYMIAR")
        }

        return ExportPreview(
            walls: normalizedWalls,
            openings: normalizedOpenings,
            dimensions: dimensions,
            bounds: normalizedBounds
        )
    }

    private func makeReferencePlan(from preview: ExportPreview) -> MadCADReferencePlan? {
        guard !preview.walls.isEmpty || !preview.openings.isEmpty else {
            return nil
        }
        return MadCADReferencePlan(
            walls: preview.walls,
            openings: preview.openings,
            dimensions: preview.dimensions,
            bounds: preview.bounds
        )
    }

    private func suggestMeasurements(for mode: ProductMode, room: CapturedRoom, preview: ExportPreview) -> ProductMeasurementDraft {
        let longestWall = preview.walls.map(\.length).max() ?? preview.bounds.width
        let estimatedHeight = estimateWallHeight(from: room)
        switch mode {
        case .gate:
            return ProductMeasurementDraft(
                mode: .gate,
                widthMm: max(1200, roundToTen(longestWall)),
                heightMm: max(1200, roundToTen(estimatedHeight > 0 ? estimatedHeight : 1500)),
                frameProfileMm: 40,
                barWidthMm: 20,
                panelCount: 18,
                sectionCount: 1,
                gateLeafCount: 2,
                groundClearanceMm: 40,
                basePlateHeightMm: 0,
                postWidthMm: 60,
                postLengthMm: max(1700, roundToTen((estimatedHeight > 0 ? estimatedHeight : 1500) + 200)),
                topPanel: true,
                topPanelThicknessMm: 20,
                bottomPanel: true,
                bottomPanelThicknessMm: 20,
                innerFrame: false,
                diagonal: false,
                infillPattern: "vertical"
            )
        case .balcony:
            return ProductMeasurementDraft(
                mode: .balcony,
                widthMm: max(1000, roundToTen(longestWall)),
                heightMm: max(900, roundToTen(min(1400, estimatedHeight > 0 ? estimatedHeight * 0.7 : 1100))),
                frameProfileMm: 40,
                barWidthMm: 16,
                panelCount: 10,
                sectionCount: 2,
                gateLeafCount: 1,
                groundClearanceMm: 0,
                basePlateHeightMm: 0,
                postWidthMm: 50,
                postLengthMm: 1200,
                topPanel: true,
                topPanelThicknessMm: 16,
                bottomPanel: true,
                bottomPanelThicknessMm: 16,
                innerFrame: false,
                diagonal: false,
                infillPattern: "horizontal"
            )
        case .fence:
            return ProductMeasurementDraft(
                mode: .fence,
                widthMm: max(1000, roundToTen(longestWall)),
                heightMm: max(1000, roundToTen(estimatedHeight > 0 ? estimatedHeight : 1500)),
                frameProfileMm: 40,
                barWidthMm: 18,
                panelCount: 17,
                sectionCount: 1,
                gateLeafCount: 1,
                groundClearanceMm: 60,
                basePlateHeightMm: 250,
                postWidthMm: 60,
                postLengthMm: max(1700, roundToTen((estimatedHeight > 0 ? estimatedHeight : 1500) + 200)),
                topPanel: true,
                topPanelThicknessMm: 18,
                bottomPanel: true,
                bottomPanelThicknessMm: 18,
                innerFrame: false,
                diagonal: false,
                infillPattern: "horizontal"
            )
        }
    }

    private func estimateWallHeight(from room: CapturedRoom) -> Double {
        let heights = room.walls.map { max(Double($0.dimensions.y), Double($0.dimensions.z)) * 1000.0 }
        guard !heights.isEmpty else { return 0 }
        let sorted = heights.sorted()
        return sorted[sorted.count / 2]
    }

    private func roundToTen(_ value: Double) -> Double {
        (value / 10.0).rounded() * 10.0
    }

    private func uniqueOpenings(from room: CapturedRoom) -> [CapturedRoom.Surface] {
        var seen = Set<UUID>()
        return (room.doors + room.windows + room.openings).filter { surface in
            seen.insert(surface.identifier).inserted
        }
    }

    private func makeWallSegment(from surface: CapturedRoom.Surface) -> PlanSegment? {
        let points = projectedFloorPoints(for: surface)
        guard let pair = longestPair(in: points) else { return fallbackWallSegment(from: surface) }
        return PlanSegment(id: surface.identifier, start: pair.0, end: pair.1, layerName: "ŚCIANY")
    }

    private func fallbackWallSegment(from surface: CapturedRoom.Surface) -> PlanSegment? {
        let center = planPoint(from: surface.transform.columns.3)
        let axis = simd_normalize(simd_double2(Double(surface.transform.columns.0.x), Double(surface.transform.columns.0.z)))
        let length = max(Double(surface.dimensions.x), Double(surface.dimensions.z)) * 1000
        guard axis.x.isFinite, axis.y.isFinite, length > 1 else { return nil }
        let half = simd_double2(axis.x * length / 2, axis.y * length / 2)
        let start = PlanPoint(x: center.x - half.x, y: center.y - half.y)
        let end = PlanPoint(x: center.x + half.x, y: center.y + half.y)
        return PlanSegment(id: surface.identifier, start: start, end: end, layerName: "ŚCIANY")
    }

    private func makeOpeningRect(from surface: CapturedRoom.Surface) -> PlanRect? {
        let points = projectedFloorPoints(for: surface)
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else {
            return nil
        }
        let width = max(80, maxX - minX)
        let height = max(80, maxY - minY)
        let origin = PlanPoint(x: minX, y: minY)
        return PlanRect(id: surface.identifier, origin: origin, width: width, height: height, layerName: "OTWORY")
    }

    private func projectedFloorPoints(for surface: CapturedRoom.Surface) -> [PlanPoint] {
        surface.polygonCorners.map(planPoint)
    }

    private func planPoint(_ point: simd_float3) -> PlanPoint {
        PlanPoint(x: Double(point.x) * 1000, y: Double(point.z) * 1000)
    }

    private func planPoint(from column: simd_float4) -> PlanPoint {
        PlanPoint(x: Double(column.x) * 1000, y: Double(column.z) * 1000)
    }

    private func longestPair(in points: [PlanPoint]) -> (PlanPoint, PlanPoint)? {
        guard points.count >= 2 else { return nil }
        var best: (PlanPoint, PlanPoint)?
        var bestDistance = 0.0
        for index in points.indices {
            for next in points.indices where next > index {
                let a = points[index]
                let b = points[next]
                let distance = hypot(b.x - a.x, b.y - a.y)
                if distance > bestDistance {
                    bestDistance = distance
                    best = (a, b)
                }
            }
        }
        return best
    }

    private func normalize(segment: PlanSegment, bounds: PlanBounds) -> PlanSegment {
        PlanSegment(
            id: segment.id,
            start: segment.start.applying(dx: -bounds.minX, dy: -bounds.minY),
            end: segment.end.applying(dx: -bounds.minX, dy: -bounds.minY),
            layerName: segment.layerName
        )
    }

    private func normalize(rect: PlanRect, bounds: PlanBounds) -> PlanRect {
        PlanRect(
            id: rect.id,
            origin: rect.origin.applying(dx: -bounds.minX, dy: -bounds.minY),
            width: rect.width,
            height: rect.height,
            layerName: rect.layerName
        )
    }

    private func dimensionPoint(for segment: PlanSegment, roomCenter: PlanPoint) -> PlanPoint {
        let dx = segment.end.x - segment.start.x
        let dy = segment.end.y - segment.start.y
        let length = max(1, hypot(dx, dy))
        let nx = -dy / length
        let ny = dx / length
        let midpoint = segment.midpoint
        let centerVectorX = midpoint.x - roomCenter.x
        let centerVectorY = midpoint.y - roomCenter.y
        let dot = centerVectorX * nx + centerVectorY * ny
        let normalSign = dot >= 0 ? 1.0 : -1.0
        let offset = max(180, min(320, length * 0.12))
        return PlanPoint(x: midpoint.x + nx * offset * normalSign, y: midpoint.y + ny * offset * normalSign)
    }
}

enum ExportError: LocalizedError {
    case noUsableWalls

    var errorDescription: String? {
        switch self {
        case .noUsableWalls:
            return "Pomiar nie zawiera czytelnych krawędzi do wykorzystania jako referencja. Spróbuj ponownie pokazać obszar produktu i jego kontekst montażowy."
        }
    }
}

private extension JSONEncoder {
    static var prettyPrinted: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}
