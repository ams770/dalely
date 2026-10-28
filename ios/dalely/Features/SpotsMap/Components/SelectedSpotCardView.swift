import SwiftUI

struct SelectedSpotCardView: View {
    let spot: Spot
    var onClose: () -> Void
    var onEdit: (() -> Void)? = nil
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        VStack(spacing: 12) {
            // Drag handle matching native sheet styling
            Capsule()
                .fill(env.palette.border)
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            // Header Row
            HStack(spacing: 12) {
                CategoryBadge(category: spot.category)

                VStack(alignment: .leading, spacing: 3) {
                    Text(spot.isCar ? env.l10n.t("myCar") : spot.name)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(env.palette.textPrimary)
                        .lineLimit(1)

                    if let user = env.location.coordinate {
                        let meters = DistanceFormatter.calculateDistance(from: user, to: spot.coordinate)
                        InfoPill(text: DistanceFormatter.format(meters, l10n: env.l10n), tintColor: env.palette.primary)
                    }
                }

                Spacer()

                HStack(spacing: 8) {
                    CircleIconButton(systemName: "square.and.arrow.up", size: 32) {
                        ShareService.shareSpot(spot, l10n: env.l10n)
                    }

                    CircleIconButton(systemName: "xmark", size: 32) {
                        onClose()
                    }
                }
            }
            .padding(.horizontal, 20)

            // Quick Info / Coordinate Row
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(env.palette.primary.opacity(0.12))
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(env.palette.primary)
                }
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(format: "%.5f, %.5f", spot.latitude, spot.longitude))
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundStyle(env.palette.textPrimary)
                    Text(spot.savedAt, style: .date)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(env.palette.textSecondary)
                }

                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .appCardStyle(cornerRadius: 14)
            .padding(.horizontal, 20)

            // Action Buttons Row
            if spot.isParking {
                HStack(spacing: 12) {
                    // Open in Maps
                    Button {
                        MapsLauncher.openDirections(latitude: spot.latitude, longitude: spot.longitude, label: spot.name)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text(env.l10n.t("openInMaps"))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .liquidGlassProminent(cornerRadius: 14, tint: env.palette.primary)
                    }
                    .buttonStyle(LiquidGlassButtonStyle())

                    // Found My Car
                    Button {
                        Haptics.success()
                        env.foundCar()
                        onClose()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                            Text(env.l10n.t("foundMyCar"))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .liquidGlassProminent(cornerRadius: 14, tint: Color(hex: 0x0E9F75))
                    }
                    .buttonStyle(LiquidGlassButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            } else if spot.isFound {
                HStack(spacing: 10) {
                    // Open in Maps
                    Button {
                        MapsLauncher.openDirections(latitude: spot.latitude, longitude: spot.longitude, label: spot.name)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text(env.l10n.t("openInMaps"))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .liquidGlassProminent(cornerRadius: 14, tint: env.palette.primary)
                    }
                    .buttonStyle(LiquidGlassButtonStyle())

                    // Delete
                    CircleIconButton(systemName: "trash", tint: .red) {
                        env.deleteSpot(spot)
                        onClose()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            } else {
                HStack(spacing: 10) {
                    // Open in Maps
                    Button {
                        MapsLauncher.openDirections(latitude: spot.latitude, longitude: spot.longitude, label: spot.name)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.turn.up.right.diamond.fill")
                                .font(.system(size: 15, weight: .bold))
                            Text(env.l10n.t("openInMaps"))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .liquidGlassProminent(cornerRadius: 14, tint: env.palette.primary)
                    }
                    .buttonStyle(LiquidGlassButtonStyle())

                    // Edit
                    CircleIconButton(systemName: "pencil") {
                        if let onEdit {
                            onEdit()
                        } else {
                            onClose()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                env.openSaveSpot(lat: spot.latitude, lng: spot.longitude, name: spot.name, editing: spot)
                            }
                        }
                    }

                    // Delete
                    CircleIconButton(systemName: "trash",  tint: .red) {
                        env.deleteSpot(spot)
                        onClose()
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .environment(\.layoutDirection, env.layoutDirection)
        .presentationDetents([.height(265)])
        .presentationDragIndicator(.hidden)
        .presentationBackgroundInteraction(.enabled(upThrough: .height(265)))
    }
}
