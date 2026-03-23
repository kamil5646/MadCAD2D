import Foundation

enum ProductMode: String, Codable, CaseIterable, Identifiable, Hashable {
    case gate
    case balcony
    case fence

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gate:
            return "Brama"
        case .balcony:
            return "Balkon"
        case .fence:
            return "Ogrodzenie"
        }
    }

    var subtitle: String {
        switch self {
        case .gate:
            return "Światło, wysokość, skrzydła i montaż"
        case .balcony:
            return "Długość, wysokość balustrady i podziały"
        case .fence:
            return "Przęsło, słupki i podmurówka"
        }
    }

    var symbolName: String {
        switch self {
        case .gate:
            return "door.garage.open"
        case .balcony:
            return "building.columns"
        case .fence:
            return "rectangle.split.3x1"
        }
    }

    var defaultProjectPrefix: String {
        switch self {
        case .gate:
            return "Brama"
        case .balcony:
            return "Balkon"
        case .fence:
            return "Ogrodzenie"
        }
    }
}

struct ProductMeasurementDraft: Hashable {
    var mode: ProductMode
    var widthMm: Double
    var heightMm: Double
    var frameProfileMm: Double
    var barWidthMm: Double
    var panelCount: Int
    var sectionCount: Int
    var gateLeafCount: Int
    var groundClearanceMm: Double
    var basePlateHeightMm: Double
    var postWidthMm: Double
    var postLengthMm: Double
    var topPanel: Bool
    var topPanelThicknessMm: Double
    var bottomPanel: Bool
    var bottomPanelThicknessMm: Double
    var innerFrame: Bool
    var diagonal: Bool
    var infillPattern: String

    func clamped() -> ProductMeasurementDraft {
        ProductMeasurementDraft(
            mode: mode,
            widthMm: max(200, widthMm),
            heightMm: max(200, heightMm),
            frameProfileMm: max(20, frameProfileMm),
            barWidthMm: max(5, barWidthMm),
            panelCount: max(1, panelCount),
            sectionCount: max(1, min(6, sectionCount)),
            gateLeafCount: max(1, min(2, gateLeafCount)),
            groundClearanceMm: max(0, groundClearanceMm),
            basePlateHeightMm: max(0, basePlateHeightMm),
            postWidthMm: max(20, postWidthMm),
            postLengthMm: max(200, postLengthMm),
            topPanel: topPanel,
            topPanelThicknessMm: max(2, topPanelThicknessMm),
            bottomPanel: bottomPanel,
            bottomPanelThicknessMm: max(2, bottomPanelThicknessMm),
            innerFrame: innerFrame,
            diagonal: diagonal,
            infillPattern: infillPattern
        )
    }

    func asExport() -> ProductMeasurementExport {
        let safe = clamped()
        return ProductMeasurementExport(
            widthMm: safe.widthMm,
            heightMm: safe.heightMm,
            frameProfileMm: safe.frameProfileMm,
            barWidthMm: safe.barWidthMm,
            panelCount: safe.panelCount,
            sectionCount: safe.sectionCount,
            gateLeafCount: safe.mode == .gate ? safe.gateLeafCount : nil,
            groundClearanceMm: safe.mode == .balcony ? nil : safe.groundClearanceMm,
            basePlateHeightMm: safe.mode == .balcony ? nil : safe.basePlateHeightMm,
            postWidthMm: safe.mode == .gate ? nil : safe.postWidthMm,
            postLengthMm: safe.mode == .fence ? safe.postLengthMm : nil,
            topPanel: safe.topPanel,
            topPanelThicknessMm: safe.topPanelThicknessMm,
            bottomPanel: safe.bottomPanel,
            bottomPanelThicknessMm: safe.bottomPanelThicknessMm,
            innerFrame: safe.mode == .gate ? safe.innerFrame : nil,
            diagonal: safe.mode == .gate ? safe.diagonal : nil,
            infillPattern: safe.infillPattern
        )
    }
}

struct ProductMeasurementExport: Codable, Hashable {
    let widthMm: Double
    let heightMm: Double
    let frameProfileMm: Double
    let barWidthMm: Double
    let panelCount: Int
    let sectionCount: Int
    let gateLeafCount: Int?
    let groundClearanceMm: Double?
    let basePlateHeightMm: Double?
    let postWidthMm: Double?
    let postLengthMm: Double?
    let topPanel: Bool
    let topPanelThicknessMm: Double
    let bottomPanel: Bool
    let bottomPanelThicknessMm: Double
    let innerFrame: Bool?
    let diagonal: Bool?
    let infillPattern: String
}

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

struct MadCADReferencePlan: Codable, Hashable {
    let walls: [PlanSegment]
    let openings: [PlanRect]
    let dimensions: [PlanSegment]
    let bounds: PlanBounds
}

struct MadCADScanMeta: Codable, Hashable {
    let source: String
    let deviceModel: String
    let capturedAt: String
    let roomName: String?
    let projectName: String?
    let boundsMm: MadCADScanBounds?
    let productMode: ProductMode?
    let measurements: ProductMeasurementExport?
    let referencePlan: MadCADReferencePlan?
}

struct MadCADProjectPayload: Codable, Hashable {
    let version: Int
    let exportedAt: String
    let entities: [MadCADEntity]
    let layers: [MadCADLayer]
    let activeLayerId: String
    let scanMeta: MadCADScanMeta?
}
