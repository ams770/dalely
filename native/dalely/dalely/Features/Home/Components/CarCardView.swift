import SwiftUI

struct CarCardView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let car = env.car {
                activeCarView(car: car)
            } else {
                emptyCarView
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .appCardStyle(
            cornerRadius: AppDimens.radiusLarge,
            borderColor: env.car != nil ? env.palette.car.opacity(0.35) : nil
        )
    }

    // MARK: - Empty Car View
    private var emptyCarView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Text(env.l10n.t("myCar"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(env.palette.textPrimary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer(minLength: 4)

                Button {
                    env.openParkingHistory()
                } label: {
                    Image(systemName: "clock")
                        .symbolRenderingMode(.monochrome)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(env.palette.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(env.palette.surfaceSecondary))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(env.l10n.t("parkingHistory")))
            }

            VStack(spacing: 6) {
                Image("CarIllustration")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 48)

                Text(env.l10n.t("noCarMessage"))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(env.palette.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            
        
            PillButton(label: env.l10n.t("parkHere"), systemImage: "parkingsign.circle.fill", tintColor: env.palette.primary) {
                env.parkHere()
            }
        }
    }

    // MARK: - Active Car View
    private func activeCarView(car: Spot) -> some View {
        VStack(spacing: 12) {
            // Header Row
            HStack(spacing: 6) {
                Text(env.l10n.t("myCar"))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(env.palette.textPrimary)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)

                Spacer(minLength: 4)

                Button {
                    env.openParkingHistory()
                } label: {
                    Image(systemName: "clock")
                        .symbolRenderingMode(.monochrome)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(env.palette.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(env.palette.surfaceSecondary))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(env.l10n.t("parkingHistory")))

                Button {
                    ShareService.shareSpot(car, l10n: env.l10n)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .symbolRenderingMode(.monochrome)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(env.palette.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(env.palette.surfaceSecondary))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(env.l10n.t("share")))
            }

            // Center: Car Illustration & Info Subtitle
            VStack(spacing: 6) {
                Image("CarIllustration")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 48)

                HStack(spacing: 6) {
                    if let user = env.location.coordinate {
                        let meters = DistanceFormatter.calculateDistance(from: user, to: car.coordinate)
                        Text(DistanceFormatter.format(meters, l10n: env.l10n))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundStyle(env.palette.primary)

                        Text("•")
                            .font(.system(size: 11))
                            .foregroundStyle(env.palette.textTertiary)
                    }

                    TimelineView(.periodic(from: .now, by: 1.0)) { context in
                        Text(TimeAgoFormatter.format(car.savedAt, l10n: env.l10n, now: context.date))
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(env.palette.textSecondary)
                    }
                }
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 2)

            // Bottom Action Buttons
            VStack(spacing: 8) {
                PillButton(
                    label: env.l10n.t("onMap"),
                    systemImage: "location.fill",
                    tintColor: env.palette.primary,
                    isProminent: true
                ) {
                    env.openMap(spotId: car.id, onlyShow: true)
                }

                PillButton(
                    label: env.l10n.t("foundMyCar"),
                    systemImage: "checkmark.circle.fill",
                    tintColor: Color(hex: 0x5CD69D),
                    isProminent: true
                ) {
                    env.foundCar()
                }
            }
        }
    }
}
