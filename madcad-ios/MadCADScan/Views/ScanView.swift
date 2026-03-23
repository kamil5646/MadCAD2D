import SwiftUI

struct ScanView: View {
    @EnvironmentObject private var store: MadCADScanStore
    @State private var previewSize: CGSize = .zero

    var body: some View {
        let steps = store.captureSteps()
        let currentIndex = min(store.captureStepIndex, max(steps.count - 1, 0))
        let currentStep = steps[currentIndex]

        ZStack {
            RoomCaptureViewRepresentable(
                captureView: store.captureController.captureView,
                onTapCapture: { point, size in
                    store.registerCaptureTap(at: point, in: size)
                }
            )
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { previewSize = proxy.size }
                            .onChange(of: proxy.size) { _, newValue in
                                previewSize = newValue
                            }
                    }
                )
                .overlay {
                    capturePointOverlay
                }
                .overlay(alignment: .top) {
                    overlayHeader(step: currentStep, steps: steps, currentIndex: currentIndex)
                }
                .overlay(alignment: .bottom) {
                    overlayFooter(steps: steps, currentIndex: currentIndex)
                }
                .overlay {
                    if isProcessing {
                        processingOverlay
                    }
                }
        }
        .background(Color.black)
        .onAppear {
            if case .idle = store.captureController.state {
                store.captureController.start()
            }
        }
        .onChange(of: store.captureController.state) { _, newValue in
            if case .ready = newValue {
                store.prepareReviewIfPossible()
            }
        }
        .alert("Błąd pomiaru", isPresented: Binding(get: {
            store.exportErrorMessage != nil
        }, set: { newValue in
            if !newValue { store.exportErrorMessage = nil }
        })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.exportErrorMessage ?? "Nieznany błąd")
        }
    }

    private var isProcessing: Bool {
        if case .processing = store.captureController.state {
            return true
        }
        return false
    }

    private func overlayHeader(step: CaptureStepDefinition, steps: [CaptureStepDefinition], currentIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                BrandBadge(size: 34)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pomiar uniwersalny")
                        .font(.headline)
                    Text("Krok 1 z 3: capture wizard")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                Text("\(currentIndex + 1) / \(steps.count)")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.cyan.opacity(0.14))
                    .clipShape(Capsule())
            }

            ProgressView(value: Double(currentIndex + 1), total: Double(max(steps.count, 1)))
                .tint(.cyan)

            VStack(alignment: .leading, spacing: 4) {
                Text(step.title)
                    .font(.headline)
                Text(step.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(step.prompt)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let point = store.capturePoint(for: step.id) {
                Text("Punkt uchwycony. X: \(Int((point.worldX * 1000).rounded())) mm, Y: \(Int((point.worldY * 1000).rounded())) mm, Z: \(Int((point.worldZ * 1000).rounded())) mm")
                    .font(.footnote)
                    .foregroundStyle(.cyan)
            } else {
                Text("Dotknij w podglądzie kamery, aby zapisać punkt dla tego etapu.")
                    .font(.footnote)
                    .foregroundStyle(.cyan)
            }

            Text(store.captureController.instructionText)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial)
    }

    private func overlayFooter(steps: [CaptureStepDefinition], currentIndex: Int) -> some View {
        VStack(spacing: 12) {
            captureChecklist(steps: steps, currentIndex: currentIndex)

            if case let .failed(message) = store.captureController.state {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            HStack(spacing: 12) {
                Button(currentIndex == 0 ? "Anuluj" : "Wstecz etap") {
                    if currentIndex == 0 {
                        store.cancelScan()
                    } else {
                        store.goToPreviousCaptureStep()
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isProcessing)

                Button("Powtórz") {
                    store.rescan()
                }
                .buttonStyle(.bordered)
                .disabled(isProcessing)

                Button("Zaznacz środek") {
                    let center = CGPoint(x: previewSize.width / 2, y: previewSize.height / 2)
                    store.registerCaptureTap(at: center, in: previewSize)
                }
                .buttonStyle(.bordered)
                .disabled(isProcessing || previewSize == .zero)

                if currentIndex < steps.count - 1 {
                    Button {
                        store.goToNextCaptureStep(total: steps.count)
                    } label: {
                        Text("Uchwycone, dalej")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .disabled(isProcessing || !store.isCaptureStepCompleted(steps[currentIndex].id))
                } else {
                    Button {
                        store.stopScan()
                    } label: {
                        if isProcessing {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Przejdź do potwierdzenia")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.cyan)
                    .disabled(isProcessing || !store.isCaptureStepCompleted(steps[currentIndex].id))
                }
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
    }

    private func captureChecklist(steps: [CaptureStepDefinition], currentIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                HStack(spacing: 8) {
                    Image(systemName: store.isCaptureStepCompleted(step.id) ? "checkmark.circle.fill" : (index == currentIndex ? "record.circle" : "circle"))
                        .foregroundStyle(store.isCaptureStepCompleted(step.id) || index == currentIndex ? .cyan : .secondary)
                    Text(step.title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                }
            }
        }
    }

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.cyan)

                Text("Przetwarzam pomiar...")
                    .font(.title3.weight(.semibold))

                Text("Kończę przechwytywanie i przygotowuję uniwersalny zestaw wymiarów do interpretacji w MadCAD.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 28)
            .frame(maxWidth: 360)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
            .padding(24)
        }
        .transition(.opacity)
    }

    private var capturePointOverlay: some View {
        GeometryReader { geometry in
            ZStack {
                crosshair(in: geometry.size)

                ForEach(store.capturePoints) { point in
                    let cgPoint = point.normalizedPoint.cgPoint(in: geometry.size)
                    VStack(spacing: 4) {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.85), lineWidth: 2)
                            )
                            .shadow(color: .black.opacity(0.35), radius: 6, y: 3)

                        Text(point.title)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.black.opacity(0.55), in: Capsule())
                    }
                    .position(x: cgPoint.x, y: cgPoint.y)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func crosshair(in size: CGSize) -> some View {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.85), lineWidth: 1.5)
                .frame(width: 34, height: 34)
                .position(center)

            Rectangle()
                .fill(Color.cyan)
                .frame(width: 18, height: 2)
                .position(center)

            Rectangle()
                .fill(Color.cyan)
                .frame(width: 2, height: 18)
                .position(center)
        }
        .shadow(color: .black.opacity(0.3), radius: 6, y: 2)
    }

}
