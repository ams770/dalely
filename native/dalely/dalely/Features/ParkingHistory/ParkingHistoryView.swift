import SwiftUI

struct ParkingHistoryView: View {
    var isEmbedded: Bool = false
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearConfirmation = false
    @State private var selectedToDelete: Spot? = nil
    @State private var visibleHistoryLimit: Int = 20
    private let pageSize: Int = 20

    private var paginatedHistory: [Spot] {
        Array(env.parkingHistory.prefix(visibleHistoryLimit))
    }

    var body: some View {
        Group {
            if env.parkingHistory.isEmpty {
                VStack {
                    Spacer()
                    EmptyStateView(
                        title: env.l10n.t("noParkingHistory"),
                        message: env.l10n.t("noParkingHistoryDesc")
                    )
                    Spacer()
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: AppDimens.space12) {
                        ForEach(paginatedHistory) { item in
                            historyCard(item: item)
                                .onAppear {
                                    if item.id == paginatedHistory.last?.id && visibleHistoryLimit < env.parkingHistory.count {
                                        visibleHistoryLimit += pageSize
                                    }
                                }
                        }

                        if visibleHistoryLimit < env.parkingHistory.count {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .onAppear {
                                    visibleHistoryLimit += pageSize
                                }
                        }
                    }
                    .padding(.horizontal, AppDimens.space16)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(env.palette.background.ignoresSafeArea())
        .navigationTitle(env.l10n.t("parkingHistory"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEmbedded {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.tap()
                        withAnimation(.easeInOut(duration: 0.25)) {
                            env.closeDetail()
                        }
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(env.palette.textPrimary)
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel(env.l10n.t("backTooltip"))
                }
            }

            if !env.parkingHistory.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .confirmationDialog(
            env.l10n.t("clearParkingHistoryTitle"),
            isPresented: $showingClearConfirmation,
            titleVisibility: .visible
        ) {
            Button(env.l10n.t("clearAll"), role: .destructive) {
                env.clearParkingHistory()
            }
            Button(env.l10n.t("cancel"), role: .cancel) {}
        } message: {
            Text(env.l10n.t("clearParkingHistoryMessage"))
        }
        .confirmationDialog(
            env.l10n.t("delete"),
            isPresented: Binding(
                get: { selectedToDelete != nil },
                set: { if !$0 { selectedToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button(env.l10n.t("delete"), role: .destructive) {
                if let target = selectedToDelete { env.deleteSpot(target) }
                selectedToDelete = nil
            }
            Button(env.l10n.t("cancel"), role: .cancel) { selectedToDelete = nil }
        }
    }

    private func historyCard(item: Spot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                Haptics.selection()
                env.openMap(spotId: item.id, onlyShow: true)
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(env.palette.surfaceSecondary)
                            .frame(width: 44, height: 44)
                        Image(systemName: "car.fill")
                            .symbolRenderingMode(.monochrome)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(env.palette.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.savedAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(env.palette.textPrimary)

                        if let ms = item.parkedDurationMs {
                            Text(DurationFormatter.formatHuman(Double(ms) / 1000, l10n: env.l10n))
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(env.palette.textSecondary)
                        }
                    }

                    Spacer()

                    if let user = env.location.coordinate {
                        let meters = DistanceFormatter.calculateDistance(from: user, to: item.coordinate)
                        InfoPill(text: DistanceFormatter.format(meters, l10n: env.l10n))
                    }

                    Image(systemName: env.isRTL ? "chevron.left" : "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(env.palette.textTertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(CardPressButtonStyle())

            Divider()

            HStack(spacing: 12) {
                PillButton(
                    label: env.l10n.t("openInMaps"),
                    systemImage: "mappin.and.ellipse",
                    tintColor: env.palette.primary
                ) {
                    MapsLauncher.openDirections(latitude: item.latitude, longitude: item.longitude, label: item.name)
                }

                Spacer()

                Button {
                    ShareService.shareSpot(item, l10n: env.l10n)
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

                Button {
                    selectedToDelete = item
                } label: {
                    Image(systemName: "trash")
                        .symbolRenderingMode(.monochrome)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.red)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(env.palette.surfaceSecondary))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(env.l10n.t("delete")))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCardStyle(cornerRadius: AppDimens.radiusLarge)
    }
}
