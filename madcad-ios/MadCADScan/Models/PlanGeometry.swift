import CoreGraphics
import Foundation

struct PlanPoint: Hashable, Codable {
    var x: Double
    var y: Double

    static let zero = PlanPoint(x: 0, y: 0)

    func applying(dx: Double, dy: Double) -> PlanPoint {
        PlanPoint(x: x + dx, y: y + dy)
    }
}

struct PlanSegment: Identifiable, Hashable, Codable {
    let id: UUID
    let start: PlanPoint
    let end: PlanPoint
    let layerName: String

    var length: Double {
        hypot(end.x - start.x, end.y - start.y)
    }

    var midpoint: PlanPoint {
        PlanPoint(x: (start.x + end.x) / 2, y: (start.y + end.y) / 2)
    }
}

struct PlanRect: Identifiable, Hashable, Codable {
    let id: UUID
    let origin: PlanPoint
    let width: Double
    let height: Double
    let layerName: String

    var maxX: Double { origin.x + width }
    var maxY: Double { origin.y + height }
    var center: PlanPoint { PlanPoint(x: origin.x + width / 2, y: origin.y + height / 2) }
}

struct PlanBounds: Hashable, Codable {
    let minX: Double
    let minY: Double
    let maxX: Double
    let maxY: Double

    var width: Double { max(1, maxX - minX) }
    var height: Double { max(1, maxY - minY) }
    var center: PlanPoint { PlanPoint(x: minX + width / 2, y: minY + height / 2) }

    static func from(segments: [PlanSegment], rects: [PlanRect]) -> PlanBounds? {
        let xs = segments.flatMap { [$0.start.x, $0.end.x] } + rects.flatMap { [$0.origin.x, $0.maxX] }
        let ys = segments.flatMap { [$0.start.y, $0.end.y] } + rects.flatMap { [$0.origin.y, $0.maxY] }
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else {
            return nil
        }
        return PlanBounds(minX: minX, minY: minY, maxX: maxX, maxY: maxY)
    }
}

struct ExportPreview: Hashable {
    let walls: [PlanSegment]
    let openings: [PlanRect]
    let dimensions: [PlanSegment]
    let bounds: PlanBounds
}

struct ExportBundle: Hashable {
    let payload: MadCADProjectPayload
    let data: Data
    let preview: ExportPreview
    let summary: ExportSummary
}

struct ExportSummary: Hashable {
    let wallCount: Int
    let openingCount: Int
    let dimensionCount: Int
}

struct RecentExportRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let exportedAt: Date
    let wallCount: Int
    let openingCount: Int
    let productMode: ProductMode?
    let primaryMeasurement: String?
}

struct NormalizedScreenPoint: Hashable {
    let x: Double
    let y: Double

    func cgPoint(in size: CGSize) -> CGPoint {
        CGPoint(x: x * size.width, y: y * size.height)
    }
}

struct CapturedMeasurementPoint: Identifiable, Hashable {
    let id: UUID
    let stepID: String
    let title: String
    let normalizedPoint: NormalizedScreenPoint
    let worldX: Double
    let worldY: Double
    let worldZ: Double

    var worldPoint: (x: Double, y: Double, z: Double) {
        (worldX, worldY, worldZ)
    }
}

struct CaptureStepDefinition: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let prompt: String
}
