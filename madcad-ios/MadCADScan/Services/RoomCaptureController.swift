import ARKit
import Foundation
import RoomPlan
import UIKit

@MainActor
final class RoomCaptureController: NSObject, ObservableObject {
    enum CaptureState: Equatable {
        case idle
        case scanning
        case processing
        case ready
        case failed(String)
    }

    @Published private(set) var state: CaptureState = .idle
    @Published var instructionText: String = "Powoli obejdź obszar produktu i pokaż ściany, słupki lub krawędzie montażowe."
    @Published private(set) var capturedRoom: CapturedRoom?

    let captureView: RoomCaptureView
    private var stopFallbackTask: Task<Void, Never>?

    override init() {
        self.captureView = RoomCaptureView(frame: .zero)
        super.init()
        captureView.captureSession.delegate = self
    }

    func start() {
        guard RoomCaptureSession.isSupported else {
            state = .failed("To urządzenie nie obsługuje RoomPlan / LiDAR.")
            return
        }
        stopFallbackTask?.cancel()
        capturedRoom = nil
        state = .scanning
        instructionText = "Powoli obejdź obszar produktu i pokaż ściany, słupki lub krawędzie montażowe."
        var configuration = RoomCaptureSession.Configuration()
        configuration.isCoachingEnabled = true
        captureView.captureSession.run(configuration: configuration)
    }

    func stop() {
        guard case .scanning = state else { return }
        state = .processing
        instructionText = "Kończę pomiar i przygotowuję zestaw wymiarów produktu..."
        stopFallbackTask?.cancel()
        stopFallbackTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled else { return }
            guard case .processing = self.state else { return }
            if self.capturedRoom != nil {
                self.state = .ready
            } else {
                self.state = .failed("Nie udało się zakończyć pomiaru. Spróbuj jeszcze raz i pokaż wyraźnie krawędzie produktu oraz jego otoczenie montażowe.")
            }
        }
        if #available(iOS 17.0, *) {
            captureView.captureSession.stop(pauseARSession: true)
        } else {
            captureView.captureSession.stop()
        }
    }

    func resetAndRestart() {
        stopFallbackTask?.cancel()
        captureView.captureSession.stop()
        start()
    }

    func raycastWorldPoint(from viewPoint: CGPoint, in viewSize: CGSize, orientation: UIInterfaceOrientation = .portrait) throws -> simd_float3 {
        let session = captureView.captureSession.arSession
        guard let frame = session.currentFrame else {
            throw CapturePointError.noFrame
        }
        guard viewSize.width > 0, viewSize.height > 0 else {
            throw CapturePointError.invalidViewport
        }

        let normalizedViewPoint = CGPoint(x: viewPoint.x / viewSize.width, y: viewPoint.y / viewSize.height)
        let imageToView = frame.displayTransform(for: orientation, viewportSize: viewSize)
        let imagePoint = normalizedViewPoint.applying(imageToView.inverted())

        let query = frame.raycastQuery(from: imagePoint, allowing: .estimatedPlane, alignment: .any)

        let results = session.raycast(query)
        guard let result = results.first else {
            throw CapturePointError.noSurface
        }

        let translation = result.worldTransform.columns.3
        return simd_float3(translation.x, translation.y, translation.z)
    }
}

extension RoomCaptureController: RoomCaptureSessionDelegate {
    nonisolated func captureSession(_ session: RoomCaptureSession, didUpdate room: CapturedRoom) {
        Task { @MainActor in
            self.capturedRoom = room
        }
    }

    nonisolated func captureSession(_ session: RoomCaptureSession, didAdd room: CapturedRoom) {
        Task { @MainActor in
            self.capturedRoom = room
        }
    }

    nonisolated func captureSession(_ session: RoomCaptureSession, didChange room: CapturedRoom) {
        Task { @MainActor in
            self.capturedRoom = room
        }
    }

    nonisolated func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {
        let message = instruction.localizedDescription
        Task { @MainActor in
            self.instructionText = message
        }
    }

    nonisolated func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {
        Task { @MainActor in
            self.stopFallbackTask?.cancel()
            self.state = .scanning
        }
    }

    nonisolated func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: (any Error)?) {
        Task { @MainActor in
            self.stopFallbackTask?.cancel()
            if let error {
                if self.capturedRoom != nil {
                    self.state = .ready
                    return
                }
                self.state = .failed(error.localizedDescription)
                return
            }

            self.state = .processing

            do {
                let builder = RoomBuilder(options: [])
                let room = try await builder.capturedRoom(from: data)
                self.capturedRoom = room
                self.state = .ready
            } catch {
                if self.capturedRoom != nil {
                    self.state = .ready
                } else {
                    self.state = .failed(error.localizedDescription)
                }
            }
        }
    }
}

enum CapturePointError: LocalizedError {
    case noFrame
    case invalidViewport
    case queryUnavailable
    case noSurface

    var errorDescription: String? {
        switch self {
        case .noFrame:
            return "Brak aktywnej klatki AR. Spróbuj jeszcze raz za moment."
        case .invalidViewport:
            return "Nie udało się odczytać rozmiaru podglądu kamery."
        case .queryUnavailable:
            return "Nie udało się przygotować raycastu dla wskazanego punktu."
        case .noSurface:
            return "Nie wykryto powierzchni pod wskazanym punktem. Spróbuj kliknąć w wyraźniejszą krawędź."
        }
    }
}

private extension RoomCaptureSession.Instruction {
    var localizedDescription: String {
        switch self {
        case .moveCloseToWall:
            return "Podejdź bliżej krawędzi produktu albo ściany, aby poprawić stabilność pomiaru."
        case .moveAwayFromWall:
            return "Odejdź trochę, aby objąć większy fragment produktu i jego kontekst montażowy."
        case .slowDown:
            return "Zwolnij ruch telefonu, aby ustabilizować pomiar."
        case .turnOnLight:
            return "Włącz więcej światła, aby poprawić wykrywanie geometrii."
        case .normal:
            return "Pomiar przebiega poprawnie."
        case .lowTexture:
            return "Celuj też w krawędzie, słupki i kontrastowe elementy montażowe."
        @unknown default:
            return "Pomiar w toku."
        }
    }
}
