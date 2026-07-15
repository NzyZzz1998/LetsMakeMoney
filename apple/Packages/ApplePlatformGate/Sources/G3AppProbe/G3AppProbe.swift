import SalaryCore
import SwiftUI
import UserNotifications

public struct G3AppProbeView: View {
    public init() {}

    public var body: some View {
        Text(UNAuthorizationStatus.notDetermined == .notDetermined
            ? "G3 App SDK probe"
            : "G3 App SDK unavailable")
    }
}
