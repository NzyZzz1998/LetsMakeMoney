import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum WarmPalette {
    static let canvas = adaptive(light: (0.98, 0.96, 0.91), dark: (0.10, 0.09, 0.08))
    static let paper = adaptive(light: (1.00, 0.99, 0.96), dark: (0.16, 0.14, 0.12))
    static let ink = adaptive(light: (0.20, 0.15, 0.11), dark: (0.95, 0.91, 0.84))
    static let muted = adaptive(light: (0.48, 0.38, 0.28), dark: (0.70, 0.62, 0.52))
    static let coin = adaptive(light: (0.96, 0.69, 0.18), dark: (0.76, 0.58, 0.25))
    static let orange = adaptive(light: (0.91, 0.45, 0.16), dark: (0.78, 0.46, 0.24))
    static let mint = adaptive(light: (0.42, 0.64, 0.43), dark: (0.43, 0.65, 0.48))
    static let border = adaptive(light: (0.38, 0.25, 0.13), dark: (0.75, 0.65, 0.52)).opacity(0.18)
    static let danger = adaptive(light: (0.67, 0.22, 0.18), dark: (0.92, 0.47, 0.39))

    private static func adaptive(
        light: (Double, Double, Double),
        dark: (Double, Double, Double)
    ) -> Color {
        #if canImport(UIKit)
        return Color(UIColor(dynamicProvider: { (traits: UITraitCollection) -> UIColor in
            let value = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: value.0, green: value.1, blue: value.2, alpha: 1)
        }))
        #else
        return Color(red: light.0, green: light.1, blue: light.2)
        #endif
    }
}

enum WarmMetrics {
    static let pagePadding: CGFloat = 20
    static let cardRadius: CGFloat = 18
    static let controlRadius: CGFloat = 12
    static let controlHeight: CGFloat = 42
}

struct WarmCard: ViewModifier {
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content
            .padding(18)
            .background(WarmPalette.paper, in: RoundedRectangle(cornerRadius: WarmMetrics.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: WarmMetrics.cardRadius)
                    .stroke(WarmPalette.border, lineWidth: contrast == .increased ? 2 : 1)
            }
    }
}

struct WarmPrimaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(WarmPalette.ink)
            .frame(minHeight: WarmMetrics.controlHeight)
            .padding(.horizontal, 18)
            .background(WarmPalette.coin.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: WarmMetrics.controlRadius))
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.98 : 1))
    }
}

struct WarmSecondaryButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.medium))
            .foregroundStyle(WarmPalette.ink)
            .frame(minHeight: WarmMetrics.controlHeight)
            .padding(.horizontal, 16)
            .background(WarmPalette.paper.opacity(configuration.isPressed ? 0.68 : 1))
            .overlay {
                RoundedRectangle(cornerRadius: WarmMetrics.controlRadius)
                    .stroke(WarmPalette.border, lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: WarmMetrics.controlRadius))
            .scaleEffect(reduceMotion ? 1 : (configuration.isPressed ? 0.98 : 1))
    }
}

extension View {
    func warmCard() -> some View { modifier(WarmCard()) }
}
