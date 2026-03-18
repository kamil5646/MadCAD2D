import Foundation

struct MadCADLayer: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let visible: Bool
    let locked: Bool
}

struct MadCADEntity: Codable, Identifiable, Hashable {
    let id: String
    let type: String
    let stroke: String
    let lineWidth: Double
    let lineStyle: String
    let layerId: String

    let x1: Double?
    let y1: Double?
    let x2: Double?
    let y2: Double?

    let x: Double?
    let y: Double?
    let w: Double?
    let h: Double?
    let fill: Bool?
    let fillColor: String?
    let fillAlpha: Double?

    let dimX: Double?
    let dimY: Double?
    let offset: Double?
    let mode: String?
    let rotation: Double?
    let textSize: Double?
    let unit: String?
    let decimals: Int?

    static func line(id: String = UUID().uuidString, start: PlanPoint, end: PlanPoint, layerId: String, stroke: String = "#d9e7ff") -> MadCADEntity {
        MadCADEntity(
            id: id,
            type: "line",
            stroke: stroke,
            lineWidth: 2,
            lineStyle: "solid",
            layerId: layerId,
            x1: start.x,
            y1: start.y,
            x2: end.x,
            y2: end.y,
            x: nil,
            y: nil,
            w: nil,
            h: nil,
            fill: nil,
            fillColor: nil,
            fillAlpha: nil,
            dimX: nil,
            dimY: nil,
            offset: nil,
            mode: nil,
            rotation: nil,
            textSize: nil,
            unit: nil,
            decimals: nil
        )
    }

    static func rect(id: String = UUID().uuidString, origin: PlanPoint, width: Double, height: Double, layerId: String) -> MadCADEntity {
        MadCADEntity(
            id: id,
            type: "rect",
            stroke: "#7fd1ff",
            lineWidth: 2,
            lineStyle: "solid",
            layerId: layerId,
            x1: nil,
            y1: nil,
            x2: nil,
            y2: nil,
            x: origin.x,
            y: origin.y,
            w: width,
            h: height,
            fill: false,
            fillColor: "#7fd1ff",
            fillAlpha: 16,
            dimX: nil,
            dimY: nil,
            offset: nil,
            mode: nil,
            rotation: nil,
            textSize: nil,
            unit: nil,
            decimals: nil
        )
    }

    static func dimension(id: String = UUID().uuidString, start: PlanPoint, end: PlanPoint, dimPoint: PlanPoint, layerId: String) -> MadCADEntity {
        MadCADEntity(
            id: id,
            type: "dimension",
            stroke: "#ffd166",
            lineWidth: 2,
            lineStyle: "solid",
            layerId: layerId,
            x1: start.x,
            y1: start.y,
            x2: end.x,
            y2: end.y,
            x: nil,
            y: nil,
            w: nil,
            h: nil,
            fill: nil,
            fillColor: nil,
            fillAlpha: nil,
            dimX: dimPoint.x,
            dimY: dimPoint.y,
            offset: nil,
            mode: "aligned",
            rotation: 0,
            textSize: 14,
            unit: "mm",
            decimals: 0
        )
    }
}

struct MadCADScanBounds: Codable, Hashable {
    let minX: Double
    let minY: Double
    let maxX: Double
    let maxY: Double
}

struct MadCADScanMeta: Codable, Hashable {
    let source: String
    let deviceModel: String
    let capturedAt: String
    let roomName: String
    let boundsMm: MadCADScanBounds
}

struct MadCADProjectPayload: Codable, Hashable {
    let version: Int
    let exportedAt: String
    let entities: [MadCADEntity]
    let layers: [MadCADLayer]
    let activeLayerId: String
    let scanMeta: MadCADScanMeta?
}
