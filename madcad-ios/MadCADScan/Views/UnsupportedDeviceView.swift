import SwiftUI

struct UnsupportedDeviceView: View {
    var body: some View {
        VStack(spacing: 18) {
            BrandBadge(size: 76)
            Image(systemName: "iphone.slash")
                .font(.system(size: 42))
                .foregroundStyle(.orange)
            Text("To urządzenie nie obsługuje skanowania LiDAR")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("MadCAD Scan v1 działa tylko na iPhone Pro z LiDAR i frameworkiem RoomPlan. Na tym urządzeniu możesz co najwyżej przeglądać ekran startowy, ale skan nie ruszy.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Text("Wykryto: \(DeviceSupport.modelIdentifier)")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }
}
