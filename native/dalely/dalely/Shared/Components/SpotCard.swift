import SwiftUI

struct CardPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.88 : 1.0)
            .animation(.spring(response: 0.22, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

struct SpotCardView: View {
    let spot: Spot
    var isFavorite: Bool = false
    var onShowOnMap: () -> Void
    var onOpenInMaps: () -> Void
    var onShare: () -> Void
    var onEdit: (() -> Void)? = nil
    var onDelete: () -> Void
    var onToggleFavorite: (() -> Void)? = nil
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        Button(action: {
            Haptics.selection()
            onShowOnMap()
        }) {
            HStack(spacing: AppDimens.space12) {
                CategoryBadge(category: spot.category)

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(spot.name)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(env.palette.textPrimary)
                            .lineLimit(1)

                        if isFavorite {
                            Text(env.l10n.t("favoriteBadge"))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundStyle(env.palette.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(env.palette.primaryContainer)
                                .clipShape(Capsule())
                        }
                    }

                    Text(spot.category.label(env.l10n))
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(env.palette.textSecondary)
                }

                Spacer(minLength: 0)

                if let user = env.location.coordinate {
                    let meters = DistanceFormatter.calculateDistance(from: user, to: spot.coordinate)
                    HStack(spacing: 4) {
                        Image(systemName: "location.north.line.fill")
                            .font(.system(size: 9, weight: .bold))
                            .rotationEffect(.degrees(45))
                        Text(DistanceFormatter.format(meters, l10n: env.l10n))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(env.palette.primary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(
                        Capsule()
                            .fill(env.palette.primary.opacity(0.12))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(env.palette.primary.opacity(0.25), lineWidth: 0.5)
                    )
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(CardPressButtonStyle())
        .appCardStyle(cornerRadius: AppDimens.radiusLarge)
        .contextMenu {
            Button(env.l10n.t("openInMaps"), systemImage: "arrow.triangle.turn.up.right.diamond") { onOpenInMaps() }
            Button(env.l10n.t("share"), systemImage: "square.and.arrow.up") { onShare() }
            if let onEdit {
                Button(env.l10n.t("editSpot"), systemImage: "pencil") { onEdit() }
            }
            Button(env.l10n.t("delete"), systemImage: "trash", role: .destructive) { onDelete() }
        }
    }
}
