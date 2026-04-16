import SwiftUI

enum QuietlineTheme {
    static let backgroundTop = Color(red: 0.95, green: 0.93, blue: 0.89)
    static let backgroundBottom = Color(red: 0.91, green: 0.88, blue: 0.84)
    static let panel = Color(red: 0.99, green: 0.98, blue: 0.96)
    static let panelSecondary = Color(red: 0.96, green: 0.94, blue: 0.91)
    static let panelMuted = Color(red: 0.93, green: 0.90, blue: 0.86)
    static let border = Color.black.opacity(0.08)
    static let borderStrong = Color.black.opacity(0.14)
    static let textPrimary = Color(red: 0.16, green: 0.15, blue: 0.14)
    static let textSecondary = Color(red: 0.42, green: 0.39, blue: 0.34)
    static let accent = Color(red: 0.73, green: 0.35, blue: 0.24)
    static let accentSoft = Color(red: 0.86, green: 0.75, blue: 0.60)
    static let accentSecondary = Color(red: 0.39, green: 0.48, blue: 0.42)
    static let success = Color(red: 0.29, green: 0.56, blue: 0.41)
    static let danger = Color(red: 0.75, green: 0.30, blue: 0.24)
    static let waveformInactive = Color.black.opacity(0.10)
    static let waveformMask = Color.white.opacity(0.56)
    static let selectionOverlay = accent.opacity(0.14)

    static let backgroundGradient = LinearGradient(
        colors: [backgroundTop, backgroundBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct StudioPanelModifier: ViewModifier {
    var padding: CGFloat = 18
    var fill: Color = QuietlineTheme.panel

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(fill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(QuietlineTheme.border, lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, y: 3)
    }
}

extension View {
    func studioPanel(padding: CGFloat = 18, fill: Color = QuietlineTheme.panel) -> some View {
        modifier(StudioPanelModifier(padding: padding, fill: fill))
    }
}

struct PillButtonStyle: ButtonStyle {
    var fill: Color
    var foreground: Color
    var stroke: Color = QuietlineTheme.border

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundStyle(foreground)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(configuration.isPressed ? fill.opacity(0.88) : fill)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(stroke, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    var fill: Color
    var foreground: Color
    var stroke: Color = QuietlineTheme.border
    var size: CGFloat = 42

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(configuration.isPressed ? fill.opacity(0.88) : fill)
                    .overlay(
                        Circle()
                            .stroke(stroke, lineWidth: 1)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct StatusDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }
}
