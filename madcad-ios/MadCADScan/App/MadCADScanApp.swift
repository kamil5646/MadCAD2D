import SwiftUI

@main
struct MadCADScanApp: App {
    @StateObject private var store = MadCADScanStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}
