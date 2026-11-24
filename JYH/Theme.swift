import SwiftUI

enum JYColor {
    static let primary = Color(hex: 0x0165F5)
    static let action = Color(hex: 0x086CF5)
    static let primaryDeep = Color(hex: 0x1D45C9)
    static let primarySoft = Color(hex: 0xE7F0FF)
    static let canvas = Color(hex: 0xF6F8FB)
    static let surface = Color.white
    static let ink = Color(hex: 0x18253C)
    static let secondaryText = Color(hex: 0x617188)
    static let tertiaryText = Color(hex: 0x98A3B4)
    static let divider = Color(hex: 0xEDF0F5)
    static let success = Color(hex: 0x15A36D)
    static let warning = Color(hex: 0xF39A34)
    static let danger = Color(hex: 0xE94B55)

    static let heroGradient = LinearGradient(
        colors: [Color(hex: 0x153ED4), primary, Color(hex: 0x467FF0)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let softGradient = LinearGradient(
        colors: [Color(hex: 0xEDF3FF), Color(hex: 0xF8FAFF)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

struct JYCardModifier: ViewModifier {
    var padding: CGFloat
    var radius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(JYColor.surface)
                    .shadow(color: Color.black.opacity(0.035), radius: 18, x: 0, y: 8)
            )
    }
}

extension View {
    func jyCard(padding: CGFloat = 18, radius: CGFloat = 20) -> some View {
        modifier(JYCardModifier(padding: padding, radius: radius))
    }

    func jyScreenBackground() -> some View {
        background(JYColor.canvas.ignoresSafeArea())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var enabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(enabled ? JYColor.primary : JYColor.tertiaryText.opacity(0.45))
            )
            .opacity(configuration.isPressed ? 0.86 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
    }
}

struct PressScaleStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
