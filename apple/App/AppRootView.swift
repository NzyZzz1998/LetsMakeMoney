import SalaryCore
import SwiftUI

struct AppRootView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        ZStack {
            WarmPalette.canvas.ignoresSafeArea()
            GeometryReader { geometry in
                Group {
                    if usesLandscapeSidebar(size: geometry.size) {
                        landscapeNavigation
                    } else {
                        compactNavigation
                    }
                }
            }
        }
        .tint(WarmPalette.orange)
        .sheet(isPresented: modalBinding(.settings)) { SettingsView() }
        .fullScreenCover(isPresented: modalBinding(.onboarding)) { OnboardingView() }
    }

    private var landscapeNavigation: some View {
        NavigationSplitView {
            List {
                destinationButton(.today, title: "nav.today", systemImage: "yensign.circle")
                destinationButton(.calendar, title: "nav.calendar", systemImage: "calendar")
                Button { model.present(.settings) } label: {
                    Label("nav.settings", systemImage: "gearshape")
                }
                .accessibilityIdentifier("nav.settings")
            }
            .navigationTitle("app.title")
        } detail: {
            ZStack {
                WarmPalette.canvas.ignoresSafeArea()
                if model.navigation.destination == .today {
                    HStack(alignment: .top, spacing: 20) {
                        TodayView()
                        SalaryCalendarView(compact: true)
                    }
                    .padding(WarmMetrics.pagePadding)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                } else {
                    SalaryCalendarView(compact: false)
                }
            }
        }
    }

    private var compactNavigation: some View {
        ZStack {
            WarmPalette.canvas.ignoresSafeArea()
            compactDestination
                .overlay(alignment: .topTrailing) { compactSettingsButton }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom) { compactTabBar }
    }

    @ViewBuilder
    private var compactDestination: some View {
        switch model.navigation.destination {
        case .today:
            TodayView()
        case .calendar:
            SalaryCalendarView(compact: false)
        }
    }

    private var compactTabBar: some View {
        HStack(spacing: 6) {
            compactTabButton(.today, title: "nav.today", systemImage: "yensign.circle")
            compactTabButton(.calendar, title: "nav.calendar", systemImage: "calendar")
        }
        .padding(5)
        .background(WarmPalette.paper, in: Capsule())
        .overlay { Capsule().stroke(WarmPalette.border, lineWidth: 1) }
        .padding(.horizontal, WarmMetrics.pagePadding)
        .padding(.vertical, 8)
        .background(WarmPalette.canvas)
    }

    private var compactSettingsButton: some View {
        Button { model.present(.settings) } label: {
            Image(systemName: "gearshape")
                .frame(width: 36, height: 36)
                .background(.thinMaterial, in: Circle())
        }
        .contentShape(Circle())
        .padding(.top, WarmMetrics.pagePadding)
        .padding(.trailing, WarmMetrics.pagePadding)
        .accessibilityLabel("nav.settings")
        .accessibilityIdentifier("nav.settings")
    }

    private func usesLandscapeSidebar(size: CGSize) -> Bool {
        horizontalSizeClass == .regular && size.width > size.height
    }

    private func compactTabButton(
        _ destination: AppDestination,
        title: LocalizedStringKey,
        systemImage: String
    ) -> some View {
        let selected = model.navigation.destination == destination
        return Button { model.select(destination) } label: {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(selected ? .semibold : .regular))
                .frame(maxWidth: .infinity, minHeight: 38)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(selected ? WarmPalette.ink : WarmPalette.muted)
        .background(selected ? WarmPalette.coin.opacity(0.28) : Color.clear, in: Capsule())
        .accessibilityIdentifier("nav.tab.\(destination.rawValue)")
    }

    private func destinationButton(
        _ destination: AppDestination,
        title: LocalizedStringKey,
        systemImage: String
    ) -> some View {
        Button { model.select(destination) } label: {
            Label(title, systemImage: systemImage)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("nav.tab.\(destination.rawValue)")
        .listRowBackground(
            model.navigation.destination == destination
                ? WarmPalette.coin.opacity(0.18)
                : Color.clear
        )
    }

    private func modalBinding(_ modal: AppModal) -> Binding<Bool> {
        Binding(
            get: { model.navigation.modal == modal },
            set: { if !$0 { model.dismissModal() } }
        )
    }
}

#Preview("iPhone portrait") {
    AppRootView().environmentObject(PreviewSupport.model()).frame(width: 390, height: 844)
}
#Preview("iPad portrait") {
    AppRootView().environmentObject(PreviewSupport.model()).frame(width: 768, height: 1_024)
}
#Preview("iPad landscape") {
    AppRootView().environmentObject(PreviewSupport.model()).frame(width: 1_024, height: 768)
}
#Preview("Dark") {
    AppRootView().environmentObject(PreviewSupport.model()).preferredColorScheme(.dark)
}
#Preview("Dynamic type") {
    AppRootView().environmentObject(PreviewSupport.model()).environment(\.dynamicTypeSize, .accessibility2)
}
#Preview("Settings") {
    SettingsView().environmentObject(PreviewSupport.model()).frame(width: 390, height: 844)
}
#Preview("Onboarding") {
    OnboardingView().environmentObject(PreviewSupport.unconfiguredModel()).frame(width: 768, height: 1_024)
}
