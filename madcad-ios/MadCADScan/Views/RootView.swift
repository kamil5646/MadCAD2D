import SwiftUI

struct RootView: View {
    @EnvironmentObject private var store: MadCADScanStore

    var body: some View {
        Group {
            if !store.isSupportedDevice {
                UnsupportedDeviceView()
            } else {
                switch store.route {
                case .start:
                    StartView()
                case .scan:
                    ScanView()
                case .review:
                    ReviewView()
                case .export:
                    ExportView()
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: store.route)
        .preferredColorScheme(.dark)
    }
}
