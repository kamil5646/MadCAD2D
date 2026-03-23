import RoomPlan
import SwiftUI

struct RoomCaptureViewRepresentable: UIViewRepresentable {
    let captureView: RoomCaptureView
    var onTapCapture: ((CGPoint, CGSize) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> RoomCaptureView {
        context.coordinator.onTapCapture = onTapCapture
        context.coordinator.installIfNeeded(on: captureView)
        return captureView
    }

    func updateUIView(_ uiView: RoomCaptureView, context: Context) {
        context.coordinator.onTapCapture = onTapCapture
        context.coordinator.installIfNeeded(on: uiView)
    }

    @MainActor
    final class Coordinator: NSObject {
        var onTapCapture: ((CGPoint, CGSize) -> Void)?
        private weak var attachedView: UIView?
        private lazy var recognizer: UITapGestureRecognizer = {
            let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            gesture.cancelsTouchesInView = false
            return gesture
        }()

        func installIfNeeded(on view: UIView) {
            guard attachedView !== view else { return }
            attachedView?.removeGestureRecognizer(recognizer)
            attachedView = view
            view.addGestureRecognizer(recognizer)
        }

        @objc private func handleTap(_ recognizer: UITapGestureRecognizer) {
            guard let view = recognizer.view else { return }
            let point = recognizer.location(in: view)
            onTapCapture?(point, view.bounds.size)
        }
    }
}
