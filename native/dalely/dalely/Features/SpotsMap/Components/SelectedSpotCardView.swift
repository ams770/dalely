import SwiftUI

struct SelectedSpotCardView: View {
    let spot: Spot
    var onClose: () -> Void
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header Row
            HStack(spacing: 12) {
                CategoryBadge(category: spot.category)

                VStack(alignment: .leading, spacing: 4) {
                    Text(spot.isCar ? env.l10n.t("myCar") : spot.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(env.palette.textPrimary)
                        .lineLimit(1)

                    if let user = env.location.coordinate {
                        let meters = DistanceFormatter.calculateDistance(from: user, to: spot.coordinate)
                        InfoPill(text: DistanceFormatter.format(meters, l10n: env.l10n), tintColor: env.palette.primary)
                    }
                }

                Spacer()

                CircleIconButton(systemName: "xmark", size: 32) {
                    onClose()
                }
            }

            // Action Buttons Row
            HStack(spacing: 10) {
                // Directions button
                Button {
                    MapsLauncher.openDirections(latitude: spot.latitude, longitude: spot.longitude, label: spot.name)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text(env.l10n.t("openInMaps"))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .liquidGlassProminent(cornerRadius: AppDimens.radiusMedium, tint: env.palette.primary)
                }
                .buttonStyle(LiquidGlassButtonStyle())

                // Share button
                CircleIconButton(systemName: "square.and.arrow.up", size: 42) {
                    ShareService.shareSpot(spot, l10n: env.l10n)
                }

                if !spot.isCar {
                    // Edit button
                    CircleIconButton(systemName: "pencil", size: 42) {
                        env.openSaveSpot(lat: spot.latitude, lng: spot.longitude, name: spot.name, editing: spot)
                    }

                    // Delete button
                    CircleIconButton(systemName: "trash", size: 42, tint: .red) {
                        env.deleteSpot(spot)
                        onClose()
                    }
                }
            }
        }
        .padding(16)
        .appCardStyle(cornerRadius: AppDimens.radiusLarge)
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
}
