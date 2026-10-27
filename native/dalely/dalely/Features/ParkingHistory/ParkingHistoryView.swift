import SwiftUI

struct ParkingHistoryView: View {
    var isEmbedded: Bool = false
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearConfirmation = false
    @State private var selectedToDelete: Spot? = nil
    @State private var visibleHistoryLimit: Int = 20
    private let pageSize: Int = 20

    @State private var filterEnabled: Bool = false
    @State private var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate: Date = Date()

    private var filteredHistory: [Spot] {
        if !filterEnabled {
            return env.parkingHistory
        }
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: startDate)
        let end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate
        return env.parkingHistory.filter { spot in
            spot.savedAt >= start && spot.savedAt <= end
        }
    }

    private var paginatedHistory: [Spot] {
        Array(filteredHistory.prefix(visibleHistoryLimit))
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
                VStack(spacing: 0) {
                    dateFilterBar

                    if filteredHistory.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            EmptyStateView(
                                title: env.l10n.t("noMatchingHistoryTitle"),
                                message: env.l10n.t("noMatchingHistoryDesc")
                            )
                            Button {
                                Haptics.tap()
                                filterEnabled = false
                                visibleHistoryLimit = pageSize
                            } label: {
                                Text(env.l10n.t("clearFilter"))
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(env.palette.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(env.palette.primary.opacity(0.12))
                                    )
                            }
                            .buttonStyle(.plain)
                            Spacer()
                        }
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: AppDimens.space12) {
                                ForEach(paginatedHistory) { item in
                                    historyCard(item: item)
                                        .onAppear {
                                            if item.id == paginatedHistory.last?.id && visibleHistoryLimit < filteredHistory.count {
                                                visibleHistoryLimit += pageSize
                                            }
                                        }
                                }

                                if visibleHistoryLimit < filteredHistory.count {
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

    // MARK: - Date Filter Bar
    private var dateFilterBar: some View {
        VStack(spacing: 8) {
            // Preset Chips Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    filterChip(title: env.l10n.t("allDates"), isSelected: !filterEnabled) {
                        filterEnabled = false
                        visibleHistoryLimit = pageSize
                    }

                    filterChip(title: env.l10n.t("todayFilter"), isSelected: filterEnabled && isSameDay(startDate, Date()) && isSameDay(endDate, Date())) {
                        startDate = Date()
                        endDate = Date()
                        filterEnabled = true
                        visibleHistoryLimit = pageSize
                    }

                    filterChip(title: env.l10n.t("last7Days"), isSelected: filterEnabled && isPastDays(startDate, 7) && isSameDay(endDate, Date())) {
                        startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                        endDate = Date()
                        filterEnabled = true
                        visibleHistoryLimit = pageSize
                    }

                    filterChip(title: env.l10n.t("last30Days"), isSelected: filterEnabled && isPastDays(startDate, 30) && isSameDay(endDate, Date())) {
                        startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                        endDate = Date()
                        filterEnabled = true
                        visibleHistoryLimit = pageSize
                    }
                }
                .padding(.horizontal, AppDimens.space16)
            }

            // Custom Range: From & To DatePickers
            HStack(spacing: 8) {
                // From Date
                HStack(spacing: 4) {
                    Text(env.l10n.t("filterFromDate"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(env.palette.textSecondary)

                    DatePicker(
                        "",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .onChange(of: startDate) { _, newStart in
                        filterEnabled = true
                        visibleHistoryLimit = pageSize
                        if endDate < newStart {
                            endDate = newStart
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(env.palette.surfaceSecondary.opacity(0.85))
                )

                // To Date
                HStack(spacing: 4) {
                    Text(env.l10n.t("filterToDate"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(env.palette.textSecondary)

                    DatePicker(
                        "",
                        selection: $endDate,
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .onChange(of: endDate) { _, newEnd in
                        filterEnabled = true
                        visibleHistoryLimit = pageSize
                        if startDate > newEnd {
                            startDate = newEnd
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(env.palette.surfaceSecondary.opacity(0.85))
                )

                if filterEnabled {
                    Button {
                        Haptics.tap()
                        filterEnabled = false
                        visibleHistoryLimit = pageSize
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundStyle(env.palette.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(env.l10n.t("clearFilter")))
                }
            }
            .padding(.horizontal, AppDimens.space16)
        }
        .padding(.vertical, 8)
        .background(env.palette.background)
    }

    private func filterChip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundStyle(isSelected ? Color.white : env.palette.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? env.palette.primary : env.palette.surfaceSecondary)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : env.palette.border.opacity(0.5), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }

    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }

    private func isPastDays(_ date: Date, _ days: Int) -> Bool {
        guard let target = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return false }
        return Calendar.current.isDate(date, inSameDayAs: target)
    }
}
