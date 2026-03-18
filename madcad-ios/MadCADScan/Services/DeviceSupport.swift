import Foundation
import RoomPlan
import UIKit

struct DeviceSupport {
    static var isRoomPlanSupported: Bool {
        RoomCaptureSession.isSupported
    }

    @MainActor
    static var displayName: String {
        UIDevice.current.model
    }

    static var modelIdentifier: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
    }
}
