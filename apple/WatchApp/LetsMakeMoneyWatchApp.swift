import SalaryCore
import SwiftUI

@main
struct LetsMakeMoneyWatchApp: App {
    @StateObject private var controller = WatchSessionController()

    var body: some Scene {
        WindowGroup {
            WatchHomeView(controller: controller)
                .task { controller.activate() }
                .onOpenURL(perform: applyDeepLink)
        }
    }

    private func applyDeepLink(_ url: URL) {
        guard url.host == "watch",
              let raw = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "metric" })?.value,
              let metric = WatchMetric(rawValue: raw)
        else { return }
        controller.selectMetric(metric)
    }
}
