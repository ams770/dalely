import SwiftUI

struct HomeMapCardView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        Button {
            Haptics.tap()
            env.openMap()
        } label: {
            VStack(spacing: 12) {
                // Header
                HStack(spacing: 6) {
                    Text(env.l10n.t("mapButton"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(env.palette.textPrimary)
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)

                    Spacer(minLength: 4)

                    Button {
                        env.openMap()
                    } label: {
                        Image(systemName: env.isRTL ? "arrow.left" : "arrow.right")
                            .symbolRenderingMode(.monochrome)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(env.palette.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(env.palette.surfaceSecondary))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(env.l10n.t("openMap")))
                }

                // Center visual: Lottie Animation from map.json
                VStack(spacing: 4) {
                    LottieAnimationView(filename: "map")
                        .frame(height: 56)

                    Text(spotsCountSubtitle)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(env.palette.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 2)

                // Explore Button
                PillButton(label: env.l10n.t("myMap"), systemImage: "safari.fill", tintColor: env.palette.primary) {
                    env.openMap()
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .appCardStyle(cornerRadius: AppDimens.radiusLarge)
        }
        .buttonStyle(LiquidGlassButtonStyle())
    }

    private var spotsCountSubtitle: String {
        if env.savedSpots.isEmpty {
            return env.l10n.t("seeAllOnMap")
        } else {
            return env.l10n.savedSpotsCount(env.savedSpots.count)
        }
    }
}
