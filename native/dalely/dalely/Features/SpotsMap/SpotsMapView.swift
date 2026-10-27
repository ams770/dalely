import MapKit

import SwiftUI



struct SpotsMapView: View {

    var isEmbedded: Bool = false

    var initialSpotId: String? = nil

    var initialOnlyShow: Bool = false

    @Environment(AppEnvironment.self) private var env

    @Environment(\.dismiss) private var dismiss



    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)

    @State private var selectedSpotId: String? = nil

    @State private var isAddingSpot: Bool = false

    @State private var newSpotName: String = ""

    @State private var newSpotCategory: SpotCategory = .market

    @State private var editingSpot: Spot? = nil

    @State private var isSearchExpanded: Bool = false

    @State private var searchRawText: String = ""

    @State private var searchService = PlaceSearchService()

    @State private var mapCenterCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753)

    @State private var bottomPanelHeight: CGFloat = 310



    var body: some View {

        ZStack {

            // 1. Fullscreen MapKit Map

            Map(position: $cameraPosition, selection: $selectedSpotId) {

                // User Location

                UserAnnotation()



                // Spot Markers

                ForEach(filteredSpots) { spot in

                    Annotation(

                        spot.isCar ? env.l10n.t("myCar") : spot.name,

                        coordinate: spot.coordinate,

                        anchor: .bottom

                    ) {

                        spotAnnotation(for: spot)

                            .tag(spot.id)

                    }

                }

            }

            .mapStyle(env.effectiveColorScheme == .dark ? .standard(elevation: .realistic) : .standard)

            .mapControls {

                MapCompass()

                MapScaleView()

            }

            .safeAreaPadding(.bottom, isAddingSpot ? bottomPanelHeight : (selectedSpotId != nil ? 180 : 0))

            .safeAreaPadding(.top, isAddingSpot ? 60 : 0)

            .onMapCameraChange(frequency: .continuous) { context in

                mapCenterCoordinate = context.camera.centerCoordinate

                searchService.updateRegion(context.region)

            }

            .ignoresSafeArea()



            // 2. Center Pin when Adding or Editing a Spot (Centered in the free visible area of the map)

            if isAddingSpot {

                VStack(spacing: 0) {

                    Color.clear.frame(height: 60)



                    Spacer()



                    centerPinView



                    Spacer()



                    // Offset spacer matching the exact height of the bottom sheet

                    Color.clear

                        .frame(height: bottomPanelHeight)

                }

                .allowsHitTesting(false)

                .transition(.scale(scale: 0.85).combined(with: .opacity))

            }



            // 4. Floating Action Buttons (Recenter & Add Spot)

            VStack {

                Spacer()

                HStack {

                    Spacer()

                    VStack(spacing: 14) {

                        // Recenter button

                        CircleIconButton(systemName: "location.fill", size: 48, tint: env.palette.primary) {

                            if let coord = env.location.coordinate {

                                withAnimation {

                                    cameraPosition = .region(MKCoordinateRegion(center: coord, latitudinalMeters: 800, longitudinalMeters: 800))

                                }

                            } else {

                                env.location.requestPermission()

                            }

                        }



                        if !isAddingSpot {

                            // Add Spot FAB

                            Button {

                                Haptics.tap()

                                enterAddSpotMode()

                            } label: {

                                Image(systemName: "plus")

                                    .font(.system(size: 22, weight: .bold))

                                    .foregroundStyle(.white)

                                    .frame(width: 52, height: 52)

                                    .liquidGlassProminent(cornerRadius: 26, tint: env.palette.primary)

                            }

                            .buttonStyle(LiquidGlassButtonStyle())

                        }

                    }

                    .padding(.trailing, 16)

                    .padding(.bottom, isAddingSpot || selectedSpot != nil ? 280 : 30)

                }

            }



            // 5. Bottom Overlay: Selected Spot Card OR Save Spot Panel

            VStack {

                Spacer()



                if isAddingSpot {

                    SaveSpotBottomPanelView(

                        name: $newSpotName,

                        category: $newSpotCategory,

                        coordinate: editingSpot?.coordinate ?? mapCenterCoordinate,

                        isEditing: editingSpot != nil,

                        onSave: {

                            saveSpotAction()

                        },

                        onClose: {

                            exitAddSpotMode()

                        }

                    )

                    .background(

                        GeometryReader { geo in

                            Color.clear.preference(key: BottomPanelHeightKey.self, value: geo.size.height)

                        }

                    )

                    .transition(.move(edge: .bottom).combined(with: .opacity))

                } else if let spot = selectedSpot {

                    SelectedSpotCardView(spot: spot) {

                        withAnimation(.easeInOut(duration: 0.25)) {

                            selectedSpotId = nil

                            env.mapOnlyShowSpotId = nil

                            env.mapFocusSpotId = nil

                        }

                    }

                    .transition(.move(edge: .bottom).combined(with: .opacity))

                }

            }

            .animation(.easeInOut(duration: 0.25), value: isAddingSpot)

            .animation(.easeInOut(duration: 0.25), value: selectedSpotId)

        }

        .overlay(alignment: .top) {
            if isSearchExpanded {
                VStack(spacing: 8) {
                    AppSearchBar(
                        text: $searchRawText,
                        placeholder: env.l10n.t("searchPlaceHint"),
                        isExpanded: $isSearchExpanded,
                        autoFocus: true,
                        debounceDuration: 0.35,
                        onDebouncedChange: { debouncedQuery in
                            searchService.query = debouncedQuery
                        },
                        onCancel: {
                            searchRawText = ""
                            searchService.query = ""
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                isSearchExpanded = false
                            }
                        }
                    )

                    if !searchService.results.isEmpty {
                        placeSearchResultsCard
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle(navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEmbedded {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            env.isMapExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: env.isMapExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    }
                    .accessibilityLabel(env.l10n.t("fullscreen"))
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                if !isSearchExpanded {
                    Button {
                        Haptics.tap()
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                            isSearchExpanded = true
                        }
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .accessibilityLabel(env.l10n.t("search"))
                }
            }
        }
        .onPreferenceChange(BottomPanelHeightKey.self) { height in

            if height > 120 {

                bottomPanelHeight = height

            }

        }

        .onAppear {

            setupInitialState()

        }

        .onChange(of: env.saveDraft) { _, newDraft in

            if let newDraft {

                enterAddSpotMode(draft: newDraft)

            }

        }

        .onChange(of: env.mapFocusSpotId) { _, spotId in

            if let spotId, let spot = env.spots.first(where: { $0.id == spotId }) {

                withAnimation(.easeInOut(duration: 0.35)) {

                    selectedSpotId = spot.id

                    cameraPosition = .region(MKCoordinateRegion(center: spot.coordinate, latitudinalMeters: 600, longitudinalMeters: 600))

                }

            }

        }

        .onDisappear {

            if !isEmbedded {

                env.mapOnlyShowSpotId = nil

                env.mapFocusSpotId = nil

            }

        }

    }

    // MARK: - Navigation Title

    private var navigationTitle: String {
        if isAddingSpot {
            return editingSpot != nil ? env.l10n.t("renameSpotTitle") : env.l10n.t("saveThisSpot")
        }
        if let selected = selectedSpot, (initialOnlyShow || env.mapOnlyShowSpotId != nil) {
            return selected.isCar ? env.l10n.t("myCar") : selected.name
        }
        return env.l10n.t("allSpotsOnMap")
    }

    // MARK: - Place Search Results Dropdown

    private var placeSearchResultsCard: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(Array(searchService.results.enumerated()), id: \.offset) { _, result in
                    Button {
                        Haptics.tap()
                        Task {
                            if let coord = await searchService.resolveCoordinate(for: result) {
                                await MainActor.run {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                        isSearchExpanded = false
                                        searchRawText = ""
                                        searchService.query = ""
                                        cameraPosition = .region(MKCoordinateRegion(
                                            center: coord,
                                            latitudinalMeters: 500,
                                            longitudinalMeters: 500
                                        ))
                                        if isAddingSpot && newSpotName.isEmpty {
                                            newSpotName = result.title
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(env.palette.primary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(result.title)
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundStyle(env.palette.textPrimary)
                                    .lineLimit(1)
                                if !result.subtitle.isEmpty {
                                    Text(result.subtitle)
                                        .font(.system(size: 12, design: .rounded))
                                        .foregroundStyle(env.palette.textSecondary)
                                        .lineLimit(1)
                                }
                            }

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 11)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Divider()
                        .padding(.leading, 48)
                }
            }
        }
        .frame(maxHeight: 220)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(env.effectiveColorScheme == .dark ? Color(hex: 0x162232) : Color.white)
                .shadow(color: Color.black.opacity(env.effectiveColorScheme == .dark ? 0.30 : 0.08), radius: 8, y: 3)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    env.effectiveColorScheme == .dark ? Color.white.opacity(0.12) : env.palette.border,
                    lineWidth: 0.75
                )
        }
    }

    // MARK: - Filtered Spots

    private var filteredSpots: [Spot] {

        let onlyId = (initialOnlyShow ? initialSpotId : nil) ?? env.mapOnlyShowSpotId

        if let onlyId {

            if let target = env.spots.first(where: { $0.id == onlyId }) {

                return [target]

            }

            return []

        }

        return env.allSpots

    }



    private var selectedSpot: Spot? {

        guard let id = selectedSpotId else { return nil }

        return env.spots.first { $0.id == id }

    }



    // MARK: - Spot Marker Annotation

    @ViewBuilder

    private func spotAnnotation(for spot: Spot) -> some View {

        VStack(spacing: 0) {

            ZStack {

                Circle()

                    .fill(spot.isCar ? env.palette.car : env.palette.categoryColor(spot.category))

                    .frame(width: 38, height: 38)

                    .shadow(color: .black.opacity(0.2), radius: 6, y: 3)



                if spot.isCar {

                    Image("CarIllustration")

                        .resizable()

                        .scaledToFit()

                        .frame(width: 22, height: 22)

                } else {

                    Image(systemName: spot.category.systemImage)

                        .font(.system(size: 16, weight: .bold))

                        .foregroundStyle(.white)

                }

            }

            .overlay(

                Circle()

                    .stroke(Color.white, lineWidth: 2)

            )



            Image(systemName: "triangle.fill")

                .font(.system(size: 8))

                .foregroundStyle(spot.isCar ? env.palette.car : env.palette.categoryColor(spot.category))

                .rotationEffect(.degrees(180))

                .offset(y: -2)

        }

    }



    // MARK: - Center Pin View

    private var centerPinView: some View {

        VStack(spacing: 0) {

            ZStack(alignment: .bottom) {

                Circle()

                    .fill(Color.black.opacity(0.18))

                    .frame(width: 14, height: 6)

                    .offset(y: 3)



                VStack(spacing: 0) {

                    ZStack {

                        Circle()

                            .fill(env.palette.categoryColor(newSpotCategory))

                            .frame(width: 44, height: 44)

                            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)



                        Image(systemName: newSpotCategory.systemImage)

                            .font(.system(size: 20, weight: .bold))

                            .foregroundStyle(.white)

                    }



                    Image(systemName: "triangle.fill")

                        .font(.system(size: 10))

                        .foregroundStyle(env.palette.categoryColor(newSpotCategory))

                        .rotationEffect(.degrees(180))

                        .offset(y: -2)

                }

            }

            .offset(y: -22)

        }

    }



    // MARK: - Actions

    private func setupInitialState() {

        if let draft = env.saveDraft {

            enterAddSpotMode(draft: draft)

            return

        }

        let onlyShow = initialOnlyShow || (env.mapOnlyShowSpotId != nil)

        let focusId = initialSpotId ?? env.mapFocusSpotId

        if let focusId, let spot = env.spots.first(where: { $0.id == focusId }) {

            selectedSpotId = spot.id

            if onlyShow {

                env.mapOnlyShowSpotId = spot.id

            }

            cameraPosition = .region(MKCoordinateRegion(center: spot.coordinate, latitudinalMeters: 600, longitudinalMeters: 600))

        } else if let user = env.location.coordinate {

            cameraPosition = .region(MKCoordinateRegion(center: user, latitudinalMeters: 1200, longitudinalMeters: 1200))

        }

    }



    private func enterAddSpotMode(draft: AppEnvironment.SaveDraft? = nil) {

        selectedSpotId = nil

        isAddingSpot = true

        if let draft {

            newSpotName = draft.name ?? ""

            if let editId = draft.editingId, let spot = env.allSpots.first(where: { $0.id == editId }) {

                editingSpot = spot

                newSpotCategory = spot.category

                cameraPosition = .region(MKCoordinateRegion(center: spot.coordinate, latitudinalMeters: 500, longitudinalMeters: 500))

            } else if let lat = draft.latitude, let lng = draft.longitude {

                cameraPosition = .region(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lng), latitudinalMeters: 500, longitudinalMeters: 500))

            }

        } else {

            newSpotName = ""

            newSpotCategory = .market

            editingSpot = nil

        }

    }



    private func exitAddSpotMode() {

        isAddingSpot = false

        editingSpot = nil

        env.saveDraft = nil

    }



    private func saveSpotAction() {

        let trimmed = newSpotName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmed.isEmpty else {

            env.snack = SnackMessage(text: env.l10n.t("nameRequired"))

            return

        }

        let target = editingSpot?.coordinate ?? mapCenterCoordinate

        env.saveSpot(

            name: trimmed,

            category: newSpotCategory,

            latitude: target.latitude,

            longitude: target.longitude,

            editingId: editingSpot?.id

        )

        exitAddSpotMode()

    }

}



private struct BottomPanelHeightKey: PreferenceKey {

    static var defaultValue: CGFloat = 310

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {

        let next = nextValue()

        if next > 120 { value = next }

    }

}
