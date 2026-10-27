import SwiftUI
struct HomeView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var showingExportSheet = false
    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width >= 700 {
                twoPaneLayout
            } else {
                singlePaneLayout
            }
        }
    }
    // MARK: - Single Pane Layout
    private var singlePaneLayout: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
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
                .padding(.bottom, 24)
            }
            if env.savedSpots.isEmpty {
                PrimaryBottomButton(label: env.l10n.t("saveThisSpot"), systemImage: "plus") {
                    env.openSaveSpot()
                }
            }
        }
        .background(env.palette.background.ignoresSafeArea())
        .navigationTitle(env.l10n.t("appTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    env.openSettings()
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .buttonStyle(.plain)
            }
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 8) {
                    Button {
                        Haptics.tap()
                        env.openSearch()
                    } label: {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(env.palette.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(env.palette.surfaceSecondary))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(env.l10n.t("search")))

                    Button {
                        env.openSaveSpot()
                    } label: {
                        Label(env.l10n.t("addSpot"), systemImage: "plus")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                }
            }
        }
        .sheet(isPresented: $showingExportSheet) {
            ExportSpotsSheetView()
        }
    }
    // MARK: - Two-Pane Layout (iPad & Wide Foldables)
    private var twoPaneLayout: some View {
        GeometryReader { geometry in
            let isDualScreen = geometry.size.width < 900
            let masterWidth = isDualScreen ? (geometry.size.width * 0.5) : min(500, max(420, geometry.size.width * 0.46))
            HStack(spacing: 0) {
                // Left: Home Pane
                if !env.isMapExpanded {
                    VStack(spacing: 0) {
                        // Dedicated Master Header for Left Pane (iPhone Duo screen 1)
                        HomeHeaderView()
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
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
                            .padding(.bottom, 24)
                        }
                    }
                    .frame(width: masterWidth)
                    .background(env.effectiveColorScheme == .dark ? env.palette.background : Color.white)
                    .transition(.move(edge: .leading).combined(with: .opacity))
                    // Divider Separator aligned with device hinge
                    Rectangle()
                        .fill(env.palette.border.opacity(0.8))
                        .frame(width: 1)
                }
                // Right: Detail Pane (Map / Search / Settings / History)
                ZStack {
                    switch env.detailPane {
                    case .map:
                        NavigationStack {
                            SpotsMapView(isEmbedded: true)
                        }
                    case .search:
                        NavigationStack {
                            SearchSpotsView(isEmbedded: true)
                        }
                    case .settings:
                        NavigationStack {
                            SettingsView(isEmbedded: true)
                        }
                    case .parkingHistory:
                        NavigationStack {
                            ParkingHistoryView(isEmbedded: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: env.isMapExpanded)
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingExportSheet) {
            ExportSpotsSheetView()
        }
    }
    // MARK: - Section Header
    private var savedSpotsHeader: some View {
        HStack {
            Text(env.l10n.t("savedSpots"))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(env.palette.textPrimary)
            Spacer()
            // Export Button (Plain)
            Button {
                showingExportSheet = true
            } label: {
                Image(systemName: "square.and.arrow.up")
                    .liquidGlassIconButton(size: 42)
            }
            .buttonStyle(LiquidGlassButtonStyle())
            // Sort Menu Button (Plain)
            Menu {
                Button {
                    env.sortOrder = .dateDesc
                } label: {
                    Label(env.l10n.t("sortByDateDesc"), systemImage: env.sortOrder == .dateDesc ? "checkmark" : "")
                }
                Button {
                    env.sortOrder = .nearest
                } label: {
                    Label(env.l10n.t("sortByNearest"), systemImage: env.sortOrder == .nearest ? "checkmark" : "")
                }
                Button {
                    env.sortOrder = .category
                } label: {
                    Label(env.l10n.t("sortByCategory"), systemImage: env.sortOrder == .category ? "checkmark" : "")
                }
                Button {
                    env.sortOrder = .name
                } label: {
                    Label(env.l10n.t("sortByName"), systemImage: env.sortOrder == .name ? "checkmark" : "")
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
                    .liquidGlassIconButton(size: 42)
            }
            .buttonStyle(LiquidGlassButtonStyle())
            // Search Button (Plain)
            Button {
                env.openSearch()
            } label: {
                Image(systemName: "magnifyingglass")
                    .liquidGlassIconButton(size: 42)
            }
            .buttonStyle(LiquidGlassButtonStyle())
        }
        .padding(.horizontal, AppDimens.space16)
        .padding(.vertical, 8)
        .background(env.palette.background)
    }
    // MARK: - Saved Spots List
    private var savedSpotsList: some View {
        VStack(spacing: AppDimens.space12) {
            ForEach(env.savedSpots) { spot in
                SpotCardView(
                    spot: spot,
                    isFavorite: env.settings.favoriteSpotId == spot.id,
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
                    },
                    onToggleFavorite: {
                        env.toggleFavorite(spot)
                    }
                )
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
}

