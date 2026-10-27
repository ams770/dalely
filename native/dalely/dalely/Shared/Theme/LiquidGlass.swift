import SwiftUI

// MARK: - Interactive Liquid Glass Button Style (Uniform Spring Click Effect)
struct LiquidGlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.90 : 1.0)
            .opacity(configuration.isPressed ? 0.78 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.65), value: configuration.isPressed)
    }
}

// MARK: - Native Liquid Glass Regular Button Modifier
struct NativeLiquidGlassButtonModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    func body(content: Content) -> some View {
        content
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(isDark ? Color.white : Color(hex: 0x12263F))
            .frame(height: 44)
            .background {
                ZStack {
                    Capsule()
                        .fill(.ultraThinMaterial)
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isDark ? 0.20 : 0.35),
                                    Color.white.opacity(isDark ? 0.04 : 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .overlay {
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(isDark ? 0.40 : 0.65), location: 0.0),
                                .init(color: Color.white.opacity(isDark ? 0.12 : 0.20), location: 0.5),
                                .init(color: Color.black.opacity(isDark ? 0.20 : 0.06), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            }
            .shadow(color: Color.black.opacity(isDark ? 0.25 : 0.06), radius: 5, x: 0, y: 2.5)
    }
}

// MARK: - Native Pure Liquid Glass Icon Button Modifier
struct NativeLiquidGlassIconButtonModifier: ViewModifier {
    var size: CGFloat = 44
    var tint: Color? = nil
    @Environment(\.colorScheme) private var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    func body(content: Content) -> some View {
        content
            .font(.system(size: max(13, size * 0.40), weight: .semibold))
            .foregroundStyle(tint ?? (isDark ? Color.white : Color(hex: 0x12263F)))
            .frame(width: size, height: size)
            .background {
                ZStack {
                    // Pure Apple Liquid Glass Material
                    Circle()
                        .fill(.ultraThinMaterial)

                    // Subtle specular glass illumination
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isDark ? 0.22 : 0.35),
                                    Color.white.opacity(isDark ? 0.04 : 0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            .overlay {
                // Razor-sharp refractive glass rim
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(isDark ? 0.45 : 0.70), location: 0.0),
                                .init(color: Color.white.opacity(isDark ? 0.12 : 0.20), location: 0.5),
                                .init(color: Color.black.opacity(isDark ? 0.20 : 0.06), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            }
            .shadow(color: Color.black.opacity(isDark ? 0.30 : 0.08), radius: 5, x: 0, y: 2.5)
    }
}

// MARK: - Liquid Glass Card Modifier
struct LiquidGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppDimens.radiusLarge
    var tint: Color? = nil
    var hasHighlight: Bool = true
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)

                    if let tint {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(tint.opacity(isDark ? 0.16 : 0.08))
                    } else {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(isDark ? Color(hex: 0x162232).opacity(0.85) : Color.white.opacity(0.90))
                    }

                    if hasHighlight {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isDark ? 0.10 : 0.35),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.06),
                        lineWidth: 0.5
                    )
            }
            .shadow(color: Color.black.opacity(isDark ? 0.30 : 0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Liquid Glass Prominent Modifier (For Hero & Action Buttons)
struct LiquidGlassProminentModifier: ViewModifier {
    var cornerRadius: CGFloat = AppDimens.radiusLarge
    var tintColor: Color
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tintColor)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5)
                    }
            }
            .shadow(color: Color.black.opacity(isDark ? 0.35 : 0.12), radius: 6, x: 0, y: 2.5)
    }
}

// MARK: - Liquid Glass Pill Modifier
struct LiquidGlassPillModifier: ViewModifier {
    var tint: Color? = nil
    var isProminent: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    func body(content: Content) -> some View {
        content
            .background {
                if isProminent {
                    Capsule()
                        .fill(tint ?? Color(hex: 0x3C79F3))
                        .overlay {
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
                        }
                } else {
                    ZStack {
                        Capsule().fill(.ultraThinMaterial)
                        if let tint {
                            Capsule().fill(tint.opacity(isDark ? 0.18 : 0.10))
                        } else {
                            Capsule().fill(isDark ? Color.white.opacity(0.06) : Color.white.opacity(0.80))
                        }
                    }
                }
            }
            .overlay {
                if !isProminent {
                    Capsule()
                        .strokeBorder(
                            isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.06),
                            lineWidth: 0.5
                        )
                }
            }
            .shadow(color: Color.black.opacity(isDark ? 0.25 : (isProminent ? 0.08 : 0.03)), radius: 4, x: 0, y: 1.5)
    }
}

// MARK: - Premium Clean Card Modifier (Non-Glass Solid Surface)
struct AppCardModifier: ViewModifier {
    var cornerRadius: CGFloat = AppDimens.radiusLarge
    var borderColor: Color? = nil
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
            .background(isDark ? Color(hex: 0x12263F) : Color.white)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        borderColor ?? (isDark ? Color.white.opacity(0.08) : Color(hex: 0x12263F).opacity(0.08)),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isDark ? Color.black.opacity(0.25) : Color(hex: 0x12263F).opacity(0.04),
                radius: 8,
                x: 0,
                y: 2
            )
    }
}

// MARK: - Liquid Glass Segmented Control
struct LiquidGlassSegmentedControl<T: Hashable>: View {
    @Binding var selection: T
    let items: [T]
    let titleFor: (T) -> String
    var iconFor: ((T) -> String?)? = nil
    var tintColor: Color? = nil

    @Namespace private var segmentAnimation
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                let isSelected = selection == item
                Button {
                    Haptics.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                        selection = item
                    }
                } label: {
                    HStack(spacing: 6) {
                        if let icon = iconFor?(item) {
                            Image(systemName: icon)
                                .font(.system(size: 13, weight: .semibold))
                        }
                        Text(titleFor(item))
                            .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(isSelected ? Color.white : (isDark ? Color.white.opacity(0.7) : Color(hex: 0x12263F).opacity(0.7)))
                    .background {
                        if isSelected {
                            Capsule()
                                .fill(tintColor ?? Color(hex: 0x3C79F3))
                                .matchedGeometryEffect(id: "segmentPill", in: segmentAnimation)
                                .overlay {
                                    Capsule()
                                        .strokeBorder(
                                            LinearGradient(
                                                stops: [
                                                    .init(color: Color.white.opacity(0.75), location: 0.0),
                                                    .init(color: Color.white.opacity(0.20), location: 0.5),
                                                    .init(color: Color.clear, location: 1.0)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1
                                        )
                                }
                                .shadow(color: Color.black.opacity(isDark ? 0.25 : 0.08), radius: 4, y: 1.5)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(.ultraThinMaterial)
                .overlay(
                    Capsule()
                        .strokeBorder(isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.06), lineWidth: 1)
                )
        }
    }
}

// MARK: - View Extensions
extension View {
    func appCardStyle(cornerRadius: CGFloat = AppDimens.radiusLarge, borderColor: Color? = nil) -> some View {
        modifier(AppCardModifier(cornerRadius: cornerRadius, borderColor: borderColor))
    }

    func liquidGlassCard(cornerRadius: CGFloat = AppDimens.radiusLarge, tint: Color? = nil, hasHighlight: Bool = true) -> some View {
        modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, tint: tint, hasHighlight: hasHighlight))
    }

    func liquidGlassProminent(cornerRadius: CGFloat = AppDimens.radiusLarge, tint: Color) -> some View {
        modifier(LiquidGlassProminentModifier(cornerRadius: cornerRadius, tintColor: tint))
    }

    func liquidGlassPill(tint: Color? = nil, isProminent: Bool = false) -> some View {
        modifier(LiquidGlassPillModifier(tint: tint, isProminent: isProminent))
    }

    func liquidGlassButton() -> some View {
        modifier(NativeLiquidGlassButtonModifier())
    }

    func liquidGlassIconButton(size: CGFloat = 44, tint: Color? = nil) -> some View {
        modifier(NativeLiquidGlassIconButtonModifier(size: size, tint: tint))
    }
}

