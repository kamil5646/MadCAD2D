import SwiftUI

struct ScanView: View {
    @EnvironmentObject private var store: MadCADScanStore

    var body: some View {
        VStack(spacing: 0) {
            RoomCaptureViewRepresentable(captureView: store.captureController.captureView)
                .overlay(alignment: .top) {
                    overlayHeader
                }
                .overlay(alignment: .bottom) {
                    overlayFooter
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
        .alert("Błąd skanowania", isPresented: Binding(get: {
            store.exportErrorMessage != nil
        }, set: { newValue in
            if !newValue { store.exportErrorMessage = nil }
        })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.exportErrorMessage ?? "Nieznany błąd")
        }
    }

    private var overlayHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                BrandBadge(size: 34)
                Text("Skanowanie pomieszczenia")
                    .font(.headline)
            }
            Text(store.captureController.instructionText)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial)
    }

    private var overlayFooter: some View {
        VStack(spacing: 12) {
            if case let .failed(message) = store.captureController.state {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }
            HStack(spacing: 12) {
                Button("Anuluj") {
                    store.cancelScan()
                }
                .buttonStyle(.bordered)

                Button("Powtórz") {
                    store.rescan()
                }
                .buttonStyle(.bordered)

                Button {
                    store.stopScan()
                } label: {
                    if case .processing = store.captureController.state {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Zakończ skan")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.cyan)
                .disabled({
                    if case .processing = store.captureController.state { return true }
                    return false
                }())
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
    }
}
