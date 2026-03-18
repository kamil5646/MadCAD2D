import SwiftUI

struct PlanPreviewCanvas: View {
    let preview: ExportPreview

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                let drawingRect = CGRect(origin: .zero, size: size).insetBy(dx: 18, dy: 18)
                let transform = PlanCanvasTransform(bounds: preview.bounds, targetRect: drawingRect)

                for wall in preview.walls {
                    var path = Path()
                    path.move(to: transform.point(for: wall.start))
                    path.addLine(to: transform.point(for: wall.end))
                    context.stroke(path, with: .color(Color(red: 0.78, green: 0.9, blue: 1.0)), lineWidth: 3)
                }

                for opening in preview.openings {
                    let rect = transform.rect(for: opening)
                    context.fill(Path(rect), with: .color(Color(red: 0.16, green: 0.66, blue: 0.92).opacity(0.16)))
                    context.stroke(Path(rect), with: .color(Color(red: 0.4, green: 0.85, blue: 1.0)), lineWidth: 2)
                }
            }
        }
    }
}

private struct PlanCanvasTransform {
    let bounds: PlanBounds
    let targetRect: CGRect

    func point(for point: PlanPoint) -> CGPoint {
        let scale = min(targetRect.width / bounds.width, targetRect.height / bounds.height)
        let fittedWidth = bounds.width * scale
        let fittedHeight = bounds.height * scale
        let originX = targetRect.minX + (targetRect.width - fittedWidth) / 2
        let originY = targetRect.minY + (targetRect.height - fittedHeight) / 2
        let x = originX + (point.x - bounds.minX) * scale
        let y = originY + (point.y - bounds.minY) * scale
        return CGPoint(x: x, y: y)
    }

    func rect(for rect: PlanRect) -> CGRect {
        let a = point(for: rect.origin)
        let b = point(for: PlanPoint(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height))
        return CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(b.x - a.x), height: abs(b.y - a.y))
    }
}
