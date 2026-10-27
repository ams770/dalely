import SwiftUI

// MARK: - Liquid Glass Circle Icon Button (Native Glass, Uniform 44pt Size)
struct CircleIconButton: View {
    let systemName: String
    var size: CGFloat = 44
    var tint: Color? = nil
    var action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            Image(systemName: systemName)
                .liquidGlassIconButton(size: size, tint: tint)
        }
        .buttonStyle(LiquidGlassButtonStyle())
        .frame(minWidth: size, minHeight: size)
    }
}

// MARK: - Liquid Glass Primary Bottom Button (Primary Color Fill, Uniform Height)
struct PrimaryBottomButton: View {
    let label: String
    var systemImage: String? = "plus"
    var action: () -> Void
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 16, weight: .bold))
                }
                Text(label)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background {
                Capsule()
                    .fill(env.palette.primary)
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.5)
                    }
            }
            .shadow(color: Color.black.opacity(0.12), radius: 5, y: 2)
        }
        .buttonStyle(LiquidGlassButtonStyle())
        .padding(.horizontal, AppDimens.space16)
        .padding(.bottom, AppDimens.space12)
    }
}

// MARK: - Liquid Glass Pill Button (Native Glass, Expands to Fill Width)
struct PillButton: View {
    let label: String
    var systemImage: String? = nil
    var tintColor: Color? = nil
    var isProminent: Bool = false
    var action: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 14, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.80)
            }
            .foregroundStyle(
                isProminent ? Color.white : (tintColor ?? (isDark ? Color.white : Color(hex: 0x12263F)))
            )
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .modifier(LiquidGlassPillModifier(tint: tintColor, isProminent: isProminent))
        }
        .buttonStyle(LiquidGlassButtonStyle())
    }
}

// MARK: - Category Badge (Clean, Apple-grade, No colored halo)
struct CategoryBadge: View {
    let category: SpotCategory
    var size: CGFloat = AppDimens.categoryBadge
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        let color = env.palette.categoryColor(category)

        ZStack {
            RoundedRectangle(cornerRadius: AppDimens.radiusSmall, style: .continuous)
                .fill(color)

            RoundedRectangle(cornerRadius: AppDimens.radiusSmall, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.20), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    )
                )

            Image(systemName: category.systemImage)
                .font(.system(size: size * 0.44, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: AppDimens.radiusSmall, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.5)
        )
    }
}

// MARK: - Info Pill (Clean horizontal layout, no text breaking)
struct InfoPill: View {
    let text: String
    var tintColor: Color? = nil
    @Environment(AppEnvironment.self) private var env
    @Environment(\.colorScheme) private var colorScheme

    private var isDark: Bool { colorScheme == .dark }

    var body: some View {
        let isTinted = tintColor != nil
        let textColor = tintColor ?? env.palette.textSecondary
        let bgColor = isTinted
            ? (tintColor!.opacity(isDark ? 0.20 : 0.10))
            : (isDark ? Color.white.opacity(0.08) : Color(hex: 0xF1F5F9))
        let strokeColor = isTinted
            ? (tintColor!.opacity(isDark ? 0.35 : 0.20))
            : (isDark ? Color.white.opacity(0.10) : Color(hex: 0xE2E8F0))

        Text(text)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(textColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(Capsule().fill(bgColor))
            .overlay(Capsule().strokeBorder(strokeColor, lineWidth: 0.5))
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    let title: String
    let message: String
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        VStack(spacing: AppDimens.space12) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 80, height: 80)
                Circle()
                    .fill(env.palette.primary.opacity(0.10))
                    .frame(width: 80, height: 80)
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                    .frame(width: 80, height: 80)

                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(env.palette.primary)
            }
            .shadow(color: env.palette.primary.opacity(0.18), radius: 12, y: 4)

            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(env.palette.textPrimary)

            Text(message)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(env.palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(AppDimens.space24)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Location Permission Banner
struct LocationPermissionBanner: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        if env.location.access != .granted && env.location.access != .unknown {
            let serviceOff = env.location.access == .serviceDisabled

            HStack(alignment: .center, spacing: AppDimens.space12) {
                Image(systemName: "location.slash.fill")
                    .foregroundStyle(.red)
                    .font(.system(size: 22))

                VStack(alignment: .leading, spacing: 2) {
                    Text(serviceOff ? env.l10n.t("serviceDisabledTitle") : env.l10n.t("permissionDeniedTitle"))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(env.palette.textPrimary)
                    Text(serviceOff ? env.l10n.t("serviceDisabledMessage") : env.l10n.t("permissionDeniedMessage"))
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(env.palette.textSecondary)
                }

                Spacer(minLength: 8)

                Button(serviceOff ? env.l10n.t("turnOn") : (env.location.access == .deniedForever ? env.l10n.t("openSettings") : env.l10n.t("allow"))) {
                    if serviceOff || env.location.access == .deniedForever {
                        env.location.openSettings()
                    } else {
                        env.location.requestPermission()
                    }
                }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundStyle(env.palette.primary)
                .liquidGlassPill(tint: env.palette.primary, isProminent: false)
                .buttonStyle(LiquidGlassButtonStyle())
            }
            .padding(AppDimens.space12)
            .appCardStyle(cornerRadius: AppDimens.radiusMedium, borderColor: Color.red.opacity(0.35))
            .padding(.bottom, AppDimens.space16)
        }
    }
}

// MARK: - Liquid Glass Category Chips
struct CategoryChips: View {
    let selected: SpotCategory
    var includeCar: Bool = false
    var available: [SpotCategory]? = nil
    var onSelect: (SpotCategory) -> Void
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips) { category in
                    let isSelected = selected == category
                    Button {
                        Haptics.selection()
                        onSelect(category)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: category.systemImage)
                                .font(.system(size: 13, weight: .semibold))
                            Text(category.label(env.l10n))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .foregroundStyle(isSelected ? Color.white : env.palette.textPrimary)
                        .liquidGlassPill(
                            tint: isSelected ? env.palette.categoryColor(category) : nil,
                            isProminent: isSelected
                        )
                    }
                    .buttonStyle(LiquidGlassButtonStyle())
                }
            }
            .padding(.horizontal, AppDimens.space16)
        }
    }

    private var chips: [SpotCategory] {
        available ?? (includeCar ? SpotCategory.allCases : SpotCategory.selectable)
    }
}

// MARK: - Liquid Glass Floating Snackbar Host (Single-Sided & Dismissable)
struct SnackbarHost: View {
    @Environment(AppEnvironment.self) private var env
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        if let snack = env.snack {
            HStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text(snack.text)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    Spacer(minLength: 8)

                    if let undo = snack.undoSpot {
                        Button(env.l10n.t("undo")) {
                            env.restore(undo)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                env.snack = nil
                            }
                        }
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: 0xFF8A65))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(hex: 0xFF8A65).opacity(0.20))
                        .clipShape(Capsule())
                    }

                    // Explicit Dismiss Button
                    Button {
                        Haptics.tap()
                        withAnimation(.easeInOut(duration: 0.2)) {
                            env.snack = nil
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color.white.opacity(0.85))
                            .frame(width: 26, height: 26)
                            .background(Color.white.opacity(0.18))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 13)
                .frame(maxWidth: env.isTwoPane ? 340 : .infinity)
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hex: 0x12263F).opacity(0.92))
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.18), Color.clear],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.75)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 18, x: 0, y: 8)
                .offset(y: dragOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height > 0 {
                                dragOffset = value.translation.height
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 30 {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    env.snack = nil
                                    dragOffset = 0
                                }
                            } else {
                                withAnimation(.spring()) {
                                    dragOffset = 0
                                }
                            }
                        }
                )

                // On wide two-pane, Spacer pushes to leading (Master pane on 1 side only, never crossing hinge)
                if env.isTwoPane {
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    if env.snack?.id == snack.id {
                        withAnimation { env.snack = nil }
                    }
                }
            }
        }
    }
}
