import SwiftUI
struct HomeView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showingExportSheet = false
    @State private var visibleSpotsLimit: Int = 20
    private let pageSize: Int = 20

    private var paginatedSavedSpots: [Spot] {
        Array(env.savedSpots.prefix(visibleSpotsLimit))
    }

    var body: some View {
        @Bindable var env = env
        GeometryReader { geometry in
            if geometry.size.width >= 700 {
                twoPaneLayout
            } else {
                singlePaneLayout
            }
        }
        .onChange(of: env.sortOrder) { _, _ in
            visibleSpotsLimit = pageSize
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSpotsSheetView()
                .environment(\.layoutDirection, env.layoutDirection)
        }
        .sheet(isPresented: $env.isSearchPresented) {
            SearchSpotsSheetView()
                .environment(\.layoutDirection, env.layoutDirection)
        }
    }
    // MARK: - Single Pane Layout
    private var singlePaneLayout: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                // Top Cards
                VStack(spacing: AppDimens.space16) {
                    LocationPermissionBanner()
                    HStack(alignment: .top, spacing: AppDimens.space12) {
                        CarCardView()
                        HomeMapCardView()
                    }
                }
                .padding(.horizontal, AppDimens.space16)
                .padding(.top, AppDimens.space8)
                .padding(.bottom, AppDimens.space16)

                // Saved Spots Section
                Section {
                    if env.savedSpots.isEmpty {
                        emptySpotsSection
                    } else {
                        savedSpotsList
                    }
                } header: {
                    if !env.savedSpots.isEmpty {
                        savedSpotsHeader
                    }
                }
            }
            .padding(.bottom, 32)
        }
        .background(env.palette.background.ignoresSafeArea())
        .navigationTitle(env.l10n.t("appTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Haptics.tap()
                    env.openSettings()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel(Text(env.l10n.t("settingsTooltip")))
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    env.openSaveSpot()
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel(Text(env.l10n.t("addSpot")))
            }
        }
    }

    // MARK: - Two-Pane Layout (iPad & Wide Foldables)
    private var twoPaneLayout: some View {
        GeometryReader { geometry in
            let isDualScreen = geometry.size.width < 900
            let masterWidth = isDualScreen ? (geometry.size.width * 0.5) : min(500, max(420, geometry.size.width * 0.46))
            HStack(spacing: 0) {
                // Left: Home Pane (Always showing the home page)
                ZStack(alignment: .topLeading) {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 0) {

                            // Top Cards
                            VStack(spacing: AppDimens.space16) {
                                LocationPermissionBanner()
                                HStack(alignment: .top, spacing: AppDimens.space12) {
                                    CarCardView()
                                    HomeMapCardView()
                                }
                            }
                            .padding(.horizontal, AppDimens.space16)
                            .padding(.top, AppDimens.space8)
                            .padding(.bottom, AppDimens.space16)

                            // Saved Spots Section
                            Section {
                                if env.savedSpots.isEmpty {
                                    emptySpotsSection
                                } else {
                                    savedSpotsList
                                }
                            } header: {
                                if !env.savedSpots.isEmpty {
                                    savedSpotsHeader
                                }
                            }
                        }
                        .padding(.leading, 54)
                        .padding(.bottom, 24)
                    }

                    // Floating Vertical Action Rail (Settings & Add Spot)
                    wideActionRail
                        .padding(.leading, AppDimens.space16)
                        .padding(.top, AppDimens.space12)
                }
                .frame(width: masterWidth)
                .background(env.effectiveColorScheme == .dark ? env.palette.background : Color.white)

                // Divider Separator aligned with device hinge
                Rectangle()
                    .fill(env.palette.border.opacity(0.8))
                    .frame(width: 1)

                // Right: Detail Pane (Map / Settings / History)
                NavigationStack {
                    ZStack {
                        switch env.detailPane {
                        case .map:
                            SpotsMapView(isEmbedded: true)
                        case .settings:
                            SettingsView(isEmbedded: true)
                        case .parkingHistory:
                            ParkingHistoryView(isEmbedded: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
    // MARK: - Section Header
    private var savedSpotsHeader: some View {
        HStack(spacing: 8) {
            Text(env.l10n.t("savedSpots"))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(env.palette.textPrimary)

            Spacer()

            // Export button
            Button {
                showingExportSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 25, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.glass)
            .accessibilityLabel(Text("Export"))

            // Sort menu button
            Menu {
                Button {
                    env.sortOrder = .dateDesc
                } label: {
                    Label(
                        env.l10n.t("sortByDateDesc"),
                        systemImage: env.sortOrder == .dateDesc ? "checkmark" : "calendar"
                    )
                }

                Button {
                    env.sortOrder = .nearest
                } label: {
                    Label(
                        env.l10n.t("sortByNearest"),
                        systemImage: env.sortOrder == .nearest ? "checkmark" : "location"
                    )
                }

                Button {
                    env.sortOrder = .category
                } label: {
                    Label(
                        env.l10n.t("sortByCategory"),
                        systemImage: env.sortOrder == .category ? "checkmark" : "square.grid.2x2"
                    )
                }

                Button {
                    env.sortOrder = .name
                } label: {
                    Label(
                        env.l10n.t("sortByName"),
                        systemImage: env.sortOrder == .name ? "checkmark" : "textformat.abc"
                    )
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 25, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.glass)
            .accessibilityLabel(Text("Sort"))

            // Search button
            Button {
                env.openSearch()
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 25, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.glass)
            .accessibilityLabel(Text("Search"))
        }
        .padding(.horizontal, AppDimens.space16)
        .padding(.vertical, 8)
        .background(env.palette.background)
    }
    // MARK: - Saved Spots List
    private var savedSpotsList: some View {
        VStack(spacing: AppDimens.space12) {
            ForEach(paginatedSavedSpots) { spot in
                SpotCardView(
                    spot: spot,
                    onShowOnMap: {
                        env.openMap(spotId: spot.id)
                    },
                    onOpenInMaps: {
                        MapsLauncher.openDirections(latitude: spot.latitude, longitude: spot.longitude, label: spot.name)
                    },
                    onShare: {
                        ShareService.shareSpot(spot, l10n: env.l10n)
                    },
                    onEdit: {
                        env.openSaveSpot(lat: spot.latitude, lng: spot.longitude, name: spot.name, editing: spot)
                    },
                    onDelete: {
                        env.deleteSpot(spot)
                    }
                )
                .onAppear {
                    if spot.id == paginatedSavedSpots.last?.id && visibleSpotsLimit < env.savedSpots.count {
                        visibleSpotsLimit += pageSize
                    }
                }
            }

            if visibleSpotsLimit < env.savedSpots.count {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .onAppear {
                        visibleSpotsLimit += pageSize
                    }
            }
        }
        .padding(.horizontal, AppDimens.space16)
        .padding(.top, 4)
    }
    // MARK: - Empty Spots Section
    private var emptySpotsSection: some View {
        VStack(spacing: AppDimens.space16) {
            EmptyStateView(
                title: env.l10n.t("emptySpotsTitle"),
                message: env.l10n.t("emptySpotsMessage")
            )
        }
        .padding(.vertical, 24)
    }

    // MARK: - Wide Screen / Duo Action Rail
    private var wideActionRail: some View {
        VStack(spacing: 10) {
            
            
            CircleIconButton(systemName: "slider.horizontal.3"){
                Haptics.tap()
                env.openSettings()
            }.accessibilityLabel(Text(env.l10n.t("settingsTooltip")))
            
            
            
            CircleIconButton(systemName: "plus"){
                Haptics.tap()
                env.openSaveSpot()
            }.accessibilityLabel(Text(env.l10n.t("addSpot")))
            
        }
    }
}

