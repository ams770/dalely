import SwiftUI

struct CarCardView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        VStack(spacing: 12) {
            headerRow

            centerVisual

            bottomActions
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .appCardStyle(
            cornerRadius: AppDimens.radiusLarge,
            borderColor: env.car != nil ? env.palette.primary.opacity(0.65) : nil
        )
        .animation(.spring(response: 0.42, dampingFraction: 0.82), value: env.car != nil)
    }

    // MARK: - Header Row
    private var headerRow: some View {
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

            if let car = env.car {
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
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.75).combined(with: .opacity),
                    removal: .scale(scale: 0.75).combined(with: .opacity)
                ))
            }
        }
    }

    // MARK: - Center Visual & Subtitle
    private var centerVisual: some View {
        VStack(spacing: 6) {
            Image("CarIllustration")
                .resizable()
                .scaledToFit()
                .frame(height: 48)

            ZStack {
                if let car = env.car {
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
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                } else {
                    Text(env.l10n.t("noCarMessage"))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(env.palette.textSecondary)
                        .lineLimit(1)
                        .transition(.opacity.combined(with: .scale(scale: 0.96)))
                }
            }
            .frame(height: 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 2)
    }

    // MARK: - Bottom Actions
    private var bottomActions: some View {
        ZStack {
            if let car = env.car {
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
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                            env.foundCar()
                        }
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                PillButton(
                    label: env.l10n.t("parkHere"),
                    systemImage: "parkingsign.circle.fill",
                    tintColor: env.palette.primary
                ) {
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.82)) {
                        env.parkHere()
                    }
                }
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .frame(height: env.car != nil ? 92 : 42)
    }
}
