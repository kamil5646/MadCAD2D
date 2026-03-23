import SwiftUI

struct UnsupportedDeviceView: View {
    var body: some View {
        VStack(spacing: 18) {
            BrandBadge(size: 76)
            Image(systemName: "iphone.slash")
                .font(.system(size: 42))
                .foregroundStyle(.orange)
            Text("To urządzenie nie obsługuje pomiaru LiDAR")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("MadCAD Scan działa tylko na iPhone Pro z LiDAR i frameworkiem RoomPlan. Tryby Brama, Balkon i Ogrodzenie wymagają tego samego wsparcia sprzętowego.")
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
