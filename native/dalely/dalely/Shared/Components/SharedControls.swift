import SwiftUI

// MARK: - Liquid Glass Circle Icon Button (Native Glass, Uniform 44pt Size)
struct CircleIconButton: View {
    let systemName: String
    var size: CGFloat = 30
    var tint: Color? = nil
    var action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.tap()
            action()
        }) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .medium))
                .frame(width: size-5, height: size)
        }
        .buttonStyle(.glass)
        .tint(tint)
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
    let selected: SpotCategory?
    var includeCar: Bool = false
    var available: [SpotCategory]? = nil
    var onSelect: (SpotCategory?) -> Void
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(chips) { category in
                        let isSelected = selected == category
                        Button {
                            Haptics.selection()
                            if isSelected {
                                onSelect(nil)
                            } else {
                                onSelect(category)
                            }
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
                        .id(category.rawValue)
                    }
                }
                .padding(.horizontal, AppDimens.space16)
            }
            .defaultScrollAnchor(.leading)
            .environment(\.layoutDirection, env.layoutDirection)
            .onAppear {
                if let selected {
                    proxy.scrollTo(selected.rawValue, anchor: .center)
                }
            }
        }
    }

    private var chips: [SpotCategory] {
        available ?? (includeCar ? SpotCategory.allCases : SpotCategory.selectable.filter { $0 != .other })
    }
}

// MARK: - Minimalist Floating Toast / Snackbar Host
struct SnackbarHost: View {
    @Environment(AppEnvironment.self) private var env
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        if let snack = env.snack {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x0E9F75))

                Text(snack.text)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundStyle(env.palette.textPrimary)
                    .lineLimit(1)

                if let undo = snack.undoSpot {
                    Button(env.l10n.t("undo")) {
                        Haptics.tap()
                        env.restore(undo)
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            env.snack = nil
                        }
                    }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(env.palette.primary)
                    .padding(.leading, 4)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.regularMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(env.palette.textPrimary.opacity(0.08), lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.12), radius: 16, y: 6)
            )
            .offset(y: dragOffset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                    .onEnded { value in
                        if value.translation.height > 20 {
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
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
            .transition(.asymmetric(
                insertion: .move(edge: .bottom).combined(with: .opacity).animation(.spring(response: 0.4, dampingFraction: 0.75)),
                removal: .scale(scale: 0.85).combined(with: .opacity).animation(.easeOut(duration: 0.2))
            ))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    if env.snack?.id == snack.id {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            env.snack = nil
                        }
                    }
                }
            }
        }
    }
}

