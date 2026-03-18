import Foundation
import RoomPlan

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
    @Published var instructionText: String = "Powoli obejdź pomieszczenie i pokaż ściany oraz otwory."
    @Published private(set) var capturedRoom: CapturedRoom?

    let captureView: RoomCaptureView

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
        capturedRoom = nil
        state = .scanning
        instructionText = "Powoli obejdź pomieszczenie i pokaż ściany oraz otwory."
        var configuration = RoomCaptureSession.Configuration()
        configuration.isCoachingEnabled = true
        captureView.captureSession.run(configuration: configuration)
    }

    func stop() {
        guard case .scanning = state else { return }
        state = .processing
        captureView.captureSession.stop()
    }

    func resetAndRestart() {
        captureView.captureSession.stop()
        start()
    }
}

extension RoomCaptureController: RoomCaptureSessionDelegate {
    nonisolated func captureSession(_ session: RoomCaptureSession, didProvide instruction: RoomCaptureSession.Instruction) {
        let message = instruction.localizedDescription
        Task { @MainActor in
            self.instructionText = message
        }
    }

    nonisolated func captureSession(_ session: RoomCaptureSession, didStartWith configuration: RoomCaptureSession.Configuration) {
        Task { @MainActor in
            self.state = .scanning
        }
    }

    nonisolated func captureSession(_ session: RoomCaptureSession, didEndWith data: CapturedRoomData, error: (any Error)?) {
        Task { @MainActor in
            if let error {
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
                self.state = .failed(error.localizedDescription)
            }
        }
    }
}

private extension RoomCaptureSession.Instruction {
    var localizedDescription: String {
        switch self {
        case .moveCloseToWall:
            return "Podejdź bliżej ściany, aby poprawić jakość skanu."
        case .moveAwayFromWall:
            return "Odejdź trochę od ściany, aby objąć większy fragment pomieszczenia."
        case .slowDown:
            return "Zwolnij ruch telefonu, aby ustabilizować pomiar."
        case .turnOnLight:
            return "Włącz więcej światła, aby poprawić wykrywanie geometrii."
        case .normal:
            return "Skanowanie przebiega poprawnie."
        case .lowTexture:
            return "Celuj też w krawędzie i kontrastowe elementy pomieszczenia."
        @unknown default:
            return "Skanowanie w toku."
        }
    }
}
