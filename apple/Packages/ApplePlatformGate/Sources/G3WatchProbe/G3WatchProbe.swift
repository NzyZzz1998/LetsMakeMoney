import SalaryCore
import SwiftUI
import WatchConnectivity
import WidgetKit

public struct G3WatchProbeView: View {
    public init() {}

    public var body: some View {
        Text("G3 Watch SDK probe")
    }
}

public enum G3WatchConnectivityProbe {
    public static var isSupported: Bool { WCSession.isSupported() }
}
