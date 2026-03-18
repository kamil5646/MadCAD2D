import Foundation
import RoomPlan
import simd

struct RoomToMadCADExporter {
    private enum LayerName {
        static let walls = "ŚCIANY"
        static let openings = "OTWORY"
        static let dimensions = "WYMIARY"
    }

    func export(room: CapturedRoom, roomName: String, deviceModel: String) throws -> ExportBundle {
        let walls = room.walls.compactMap(makeWallSegment)
        let openings = uniqueOpenings(from: room).compactMap(makeOpeningRect)

        guard let rawBounds = PlanBounds.from(segments: walls, rects: openings), !walls.isEmpty else {
            throw ExportError.noUsableWalls
        }

        let normalizedWalls = walls.map { normalize(segment: $0, bounds: rawBounds) }
        let normalizedOpenings = openings.map { normalize(rect: $0, bounds: rawBounds) }
        let normalizedBounds = PlanBounds.from(segments: normalizedWalls, rects: normalizedOpenings) ?? rawBounds
        let roomCenter = normalizedBounds.center

        let wallLayer = MadCADLayer(id: UUID().uuidString, name: LayerName.walls, visible: true, locked: false)
        let openingLayer = MadCADLayer(id: UUID().uuidString, name: LayerName.openings, visible: true, locked: false)
        let dimensionLayer = MadCADLayer(id: UUID().uuidString, name: LayerName.dimensions, visible: true, locked: false)

        let wallEntities = normalizedWalls.map {
            MadCADEntity.line(start: $0.start, end: $0.end, layerId: wallLayer.id)
        }
        let openingEntities = normalizedOpenings.map {
            MadCADEntity.rect(origin: $0.origin, width: $0.width, height: $0.height, layerId: openingLayer.id)
        }
        let dimensionEntities = normalizedWalls.map {
            let dimPoint = dimensionPoint(for: $0, roomCenter: roomCenter)
            return MadCADEntity.dimension(start: $0.start, end: $0.end, dimPoint: dimPoint, layerId: dimensionLayer.id)
        }

        let payload = MadCADProjectPayload(
            version: 2,
            exportedAt: ISO8601DateFormatter().string(from: Date()),
            entities: wallEntities + openingEntities + dimensionEntities,
            layers: [wallLayer, openingLayer, dimensionLayer],
            activeLayerId: wallLayer.id,
            scanMeta: MadCADScanMeta(
                source: "roomplan",
                deviceModel: deviceModel,
                capturedAt: ISO8601DateFormatter().string(from: Date()),
                roomName: roomName,
                boundsMm: MadCADScanBounds(minX: normalizedBounds.minX, minY: normalizedBounds.minY, maxX: normalizedBounds.maxX, maxY: normalizedBounds.maxY)
            )
        )

        let data = try JSONEncoder.prettyPrinted.encode(payload)
        return ExportBundle(
            payload: payload,
            data: data,
            preview: ExportPreview(
                walls: normalizedWalls,
                openings: normalizedOpenings,
                dimensions: normalizedWalls,
                bounds: normalizedBounds
            ),
            summary: ExportSummary(
                wallCount: normalizedWalls.count,
                openingCount: normalizedOpenings.count,
                dimensionCount: dimensionEntities.count
            )
        )
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
        return PlanSegment(id: surface.identifier, start: pair.0, end: pair.1, layerName: LayerName.walls)
    }

    private func fallbackWallSegment(from surface: CapturedRoom.Surface) -> PlanSegment? {
        let center = planPoint(from: surface.transform.columns.3)
        let axis = simd_normalize(simd_double2(Double(surface.transform.columns.0.x), Double(surface.transform.columns.0.z)))
        let length = max(Double(surface.dimensions.x), Double(surface.dimensions.z)) * 1000
        guard axis.x.isFinite, axis.y.isFinite, length > 1 else { return nil }
        let half = simd_double2(axis.x * length / 2, axis.y * length / 2)
        let start = PlanPoint(x: center.x - half.x, y: center.y - half.y)
        let end = PlanPoint(x: center.x + half.x, y: center.y + half.y)
        return PlanSegment(id: surface.identifier, start: start, end: end, layerName: LayerName.walls)
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
        return PlanRect(id: surface.identifier, origin: origin, width: width, height: height, layerName: LayerName.openings)
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
            return "Skan nie zawiera czytelnych ścian do eksportu. Spróbuj ponownie zeskanować pomieszczenie."
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
