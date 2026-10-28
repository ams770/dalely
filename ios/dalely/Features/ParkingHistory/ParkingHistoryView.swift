import SwiftUI

struct ParkingHistoryView: View {
    var isEmbedded: Bool = false
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearConfirmation = false
    @State private var showingFilterSheet = false
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

    private var activeFilterSummary: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(startDate) && calendar.isDateInToday(endDate) {
            return env.l10n.t("todayFilter")
        }
        if let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()),
           calendar.isDate(startDate, inSameDayAs: sevenDaysAgo),
           calendar.isDateInToday(endDate) {
            return env.l10n.t("last7Days")
        }
        if let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()),
           calendar.isDate(startDate, inSameDayAs: thirtyDaysAgo),
           calendar.isDateInToday(endDate) {
            return env.l10n.t("last30Days")
        }
        let startText = startDate.formatted(date: .abbreviated, time: .omitted)
        let endText = endDate.formatted(date: .abbreviated, time: .omitted)
        if calendar.isDate(startDate, inSameDayAs: endDate) {
            return startText
        }
        return "\(startText) – \(endText)"
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
                    if filterEnabled {
                        activeFilterBanner
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if filteredHistory.isEmpty {
                        VStack(spacing: 16) {
                            Spacer()
                            EmptyStateView(
                                title: env.l10n.t("noMatchingHistoryTitle"),
                                message: env.l10n.t("noMatchingHistoryDesc")
                            )
                            Button {
                                Haptics.tap()
                                withAnimation(.snappy(duration: 0.25)) {
                                    filterEnabled = false
                                    visibleHistoryLimit = pageSize
                                }
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
                            .padding(.top, 8)
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
                    Button {
                        Haptics.tap()
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: filterEnabled ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease")
                            .foregroundStyle(filterEnabled ? env.palette.primary : env.palette.textPrimary)
                    }
                    .accessibilityLabel(env.l10n.t("filterByDate"))
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .accessibilityLabel(env.l10n.t("clearAll"))
                }
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            ParkingHistoryFilterSheetView(
                filterEnabled: $filterEnabled,
                startDate: $startDate,
                endDate: $endDate,
                onFilterChanged: {
                    visibleHistoryLimit = pageSize
                }
            )
            .environment(\.layoutDirection, env.layoutDirection)
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

    // MARK: - Active Filter Summary Banner
    private var activeFilterBanner: some View {
        HStack(spacing: 10) {
            Button {
                Haptics.tap()
                showingFilterSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(env.palette.primary)

                    Text(activeFilterSummary)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(env.palette.textPrimary)
                        .lineLimit(1)

                    InfoPill(
                        text: "\(filteredHistory.count)",
                        tintColor: env.palette.primary
                    )
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                Haptics.tap()
                withAnimation(.snappy(duration: 0.25)) {
                    filterEnabled = false
                    visibleHistoryLimit = pageSize
                }
            } label: {
                HStack(spacing: 4) {
                    Text(env.l10n.t("clearFilter"))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundStyle(env.palette.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(env.palette.primary.opacity(0.10))
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(env.l10n.t("clearFilter")))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .appCardStyle(cornerRadius: AppDimens.radiusMedium)
        .padding(.horizontal, AppDimens.space16)
        .padding(.top, 6)
        .padding(.bottom, 4)
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

// MARK: - Native Date Filter Bottom Sheet
private struct ParkingHistoryFilterSheetView: View {
    @Binding var filterEnabled: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    var onFilterChanged: () -> Void

    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    private var isTodaySelected: Bool {
        filterEnabled && isSameDay(startDate, Date()) && isSameDay(endDate, Date())
    }

    private var isLast7DaysSelected: Bool {
        filterEnabled && isPastDays(startDate, 7) && isSameDay(endDate, Date())
    }

    private var isLast30DaysSelected: Bool {
        filterEnabled && isPastDays(startDate, 30) && isSameDay(endDate, Date())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Drag Handle
            HStack {
                Spacer()
                Capsule()
                    .fill(env.palette.border)
                    .frame(width: 36, height: 4)
                Spacer()
            }
            .padding(.top, 10)

            // Sheet Header
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(env.palette.primary.opacity(0.12))
                    Image(systemName: "calendar")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(env.palette.primary)
                }
                .frame(width: 36, height: 36)

                Text(env.l10n.t("filterByDate"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(env.palette.textPrimary)

                Spacer()

                CircleIconButton(systemName: "xmark", size: 30) {
                    dismiss()
                }
                .accessibilityLabel(env.l10n.t("close"))
            }
            .padding(.horizontal, 20)

            // Quick Presets Section
            VStack(alignment: .leading, spacing: 10) {
                Text(env.l10n.t("quickRange"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(env.palette.textSecondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 4)

                HStack(spacing: 8) {
                    presetPill(
                        title: env.l10n.t("allDates"),
                        isSelected: !filterEnabled
                    ) {
                        filterEnabled = false
                        onFilterChanged()
                    }

                    presetPill(
                        title: env.l10n.t("todayFilter"),
                        isSelected: isTodaySelected
                    ) {
                        startDate = Date()
                        endDate = Date()
                        filterEnabled = true
                        onFilterChanged()
                    }

                    presetPill(
                        title: env.l10n.t("last7Days"),
                        isSelected: isLast7DaysSelected
                    ) {
                        startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                        endDate = Date()
                        filterEnabled = true
                        onFilterChanged()
                    }

                    presetPill(
                        title: env.l10n.t("last30Days"),
                        isSelected: isLast30DaysSelected
                    ) {
                        startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                        endDate = Date()
                        filterEnabled = true
                        onFilterChanged()
                    }
                }
            }
            .padding(.horizontal, 20)

            // Custom Date Range Section
            VStack(alignment: .leading, spacing: 10) {
                Text(env.l10n.t("customDateRange"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(env.palette.textSecondary)
                    .textCase(.uppercase)
                    .padding(.horizontal, 4)

                VStack(spacing: 0) {
                    // From Date Row
                    HStack(spacing: 10) {
                        Image(systemName: "calendar")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(env.palette.primary)
                            .frame(width: 22)

                        Text(env.l10n.t("filterFromDate"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(env.palette.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        DatePicker(
                            "",
                            selection: Binding(
                                get: { startDate },
                                set: { newStart in
                                    startDate = newStart
                                    filterEnabled = true
                                    if endDate < newStart {
                                        endDate = newStart
                                    }
                                    onFilterChanged()
                                }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(env.palette.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    Divider()
                        .padding(.leading, 46)

                    // To Date Row
                    HStack(spacing: 10) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(env.palette.primary)
                            .frame(width: 22)

                        Text(env.l10n.t("filterToDate"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(env.palette.textPrimary)
                            .lineLimit(1)

                        Spacer()

                        DatePicker(
                            "",
                            selection: Binding(
                                get: { endDate },
                                set: { newEnd in
                                    endDate = newEnd
                                    filterEnabled = true
                                    if startDate > newEnd {
                                        startDate = newEnd
                                    }
                                    onFilterChanged()
                                }
                            ),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .tint(env.palette.primary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .appCardStyle(cornerRadius: AppDimens.radiusMedium)
            }
            .padding(.horizontal, 20)

            // Bottom Actions Row
            HStack(spacing: 12) {
                if filterEnabled {
                    Button {
                        Haptics.tap()
                        filterEnabled = false
                        onFilterChanged()
                        dismiss()
                    } label: {
                        Text(env.l10n.t("clearFilter"))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(env.palette.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(
                                Capsule()
                                    .fill(env.palette.surfaceSecondary)
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(env.palette.border, lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(LiquidGlassButtonStyle())
                }

                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Text(env.l10n.t("applyFilter"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Capsule()
                                .fill(env.palette.primary)
                        )
                }
                .buttonStyle(LiquidGlassButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 2)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .environment(\.layoutDirection, env.layoutDirection)
        .presentationDetents([.height(390)])
        .presentationDragIndicator(.hidden)
    }

    private func presetPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(isSelected ? Color.white : env.palette.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(isSelected ? env.palette.primary : env.palette.surface)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isSelected ? Color.clear : env.palette.border, lineWidth: 0.5)
                )
        }
        .buttonStyle(LiquidGlassButtonStyle())
    }

    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }

    private func isPastDays(_ date: Date, _ days: Int) -> Bool {
        guard let target = Calendar.current.date(byAdding: .day, value: -days, to: Date()) else { return false }
        return Calendar.current.isDate(date, inSameDayAs: target)
    }
}
