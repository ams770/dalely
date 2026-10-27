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
    @State private var newSpotCategory: SpotCategory? = nil
    @State private var editingSpot: Spot? = nil
    @State private var isSearchExpanded: Bool = false
    @State private var searchRawText: String = ""
    @State private var searchService = PlaceSearchService()
    @State private var mapCenterCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 24.7136, longitude: 46.6753)
    @State private var mapCameraDistance: CLLocationDistance = 1000
    @State private var mapCameraRegion: MKCoordinateRegion? = nil
    @State private var isProgrammaticCameraMoving: Bool = false
    @State private var mapPatchLimit: Int = 30
    private let mapPatchSize: Int = 30

    var body: some View {
        GeometryReader { geometry in
            MapReader { proxy in
                ZStack {
                    mapContent(proxy: proxy, geometry: geometry)

                    if isAddingSpot {
                        centerPinOverlay(geometry: geometry)
                    }

                    floatingControls(proxy: proxy, geometry: geometry)
                }
                .sheet(isPresented: $isAddingSpot, onDismiss: {
                    exitAddSpotMode()
                }) {
                    SaveSpotBottomPanelView(
                        name: $newSpotName,
                        category: $newSpotCategory,
                        coordinate: mapCenterCoordinate,
                        isEditing: editingSpot != nil,
                        onSave: {
                            saveSpotAction(proxy: proxy, geometry: geometry)
                        },
                        onClose: {
                            exitAddSpotMode()
                        }
                    )
                    .environment(\.layoutDirection, env.layoutDirection)
                }
                .sheet(item: selectedSpotBinding) { spot in
                    SelectedSpotCardView(
                        spot: spot,
                        onClose: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                selectedSpotId = nil
                                env.mapOnlyShowSpotId = nil
                                env.mapFocusSpotId = nil
                            }
                        },
                        onEdit: {
                            selectedSpotId = nil
                            editingSpot = spot
                            newSpotName = spot.name
                            newSpotCategory = spot.category
                            mapCenterCoordinate = spot.coordinate
                            let pinPoint = addSpotPinPoint(geometry: geometry)
                            centerCameraOnPin(coordinate: spot.coordinate, pinPoint: pinPoint, geometry: geometry, proxy: proxy)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                isAddingSpot = true
                            }
                        }
                    )
                    .environment(\.layoutDirection, env.layoutDirection)
                }
                .overlay(alignment: .top) {
                    if isSearchExpanded {
                        searchOverlay(geometry: geometry, proxy: proxy)
                    }
                }
                .onAppear {
                    setupInitialState(geometry: geometry, proxy: proxy)
                }
                .onChange(of: env.saveDraft) { _, newDraft in
                    if let newDraft {
                        enterAddSpotMode(draft: newDraft, geometry: geometry, proxy: proxy)
                    }
                }
                .onChange(of: env.mapFocusSpotId) { _, spotId in
                    if let spotId, let spot = env.spots.first(where: { $0.id == spotId }) {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            selectedSpotId = spot.id
                            let screenCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            centerCameraOnPin(coordinate: spot.coordinate, pinPoint: screenCenter, geometry: geometry, proxy: proxy, targetDistance: 800)
                        }
                    }
                }
                .onChange(of: selectedSpotId) { _, newId in
                    if let newId, let spot = env.spots.first(where: { $0.id == newId }) {
                        withAnimation(.easeInOut(duration: 0.35)) {
                            let screenCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            centerCameraOnPin(coordinate: spot.coordinate, pinPoint: screenCenter, geometry: geometry, proxy: proxy, targetDistance: 800)
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .ignoresSafeArea(.keyboard, edges: .all)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(!isEmbedded)
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
            } else {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        Haptics.tap()
                        handleBackAction()
                    } label: {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(env.palette.textPrimary)
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel(env.l10n.t("backTooltip"))
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
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(env.palette.textPrimary)
                            .frame(width: 36, height: 36)
                    }
                    .accessibilityLabel(env.l10n.t("search"))
                }
            }
        }
        .background(InteractiveBackGestureHandler(isEnabled: !hasOpenSheet))
        .onDisappear {
            if !isEmbedded {
                env.mapOnlyShowSpotId = nil
                env.mapFocusSpotId = nil
            }
        }
    }

    // MARK: - Map Content Subview
    @ViewBuilder
    private func mapContent(proxy: MapProxy, geometry: GeometryProxy) -> some View {
        let pinPoint = addSpotPinPoint(geometry: geometry)
        Map(position: $cameraPosition, selection: $selectedSpotId) {
            UserAnnotation()

            ForEach(visibleMapSpots, id: \.id) { (spot: Spot) in
                Annotation("", coordinate: spot.coordinate, anchor: .bottom) {
                    spotAnnotation(for: spot)
                        .tag(spot.id)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSpotTapped(spot, geometry: geometry, proxy: proxy)
                        }
                }
            }
        }
        .mapStyle(env.effectiveColorScheme == .dark ? .standard(elevation: .realistic) : .standard)
        .mapControls {
            MapCompass()
            MapScaleView()
        }
        .onMapCameraChange(frequency: .continuous) { (context: MapCameraUpdateContext) in
            mapCameraDistance = context.camera.distance
            mapCameraRegion = context.region
            if isAddingSpot {
                if !isProgrammaticCameraMoving, let exact = proxy.convert(pinPoint, from: .local) {
                    mapCenterCoordinate = exact
                }
            } else {
                mapCenterCoordinate = context.camera.centerCoordinate
            }
            searchService.updateRegion(context.region)
        }
        .onMapCameraChange(frequency: .onEnd) { (context: MapCameraUpdateContext) in
            mapCameraDistance = context.camera.distance
            mapCameraRegion = context.region
            isProgrammaticCameraMoving = false
            if isAddingSpot, let exact = proxy.convert(pinPoint, from: .local) {
                mapCenterCoordinate = exact
            } else if !isAddingSpot {
                mapCenterCoordinate = context.camera.centerCoordinate
            }
            if mapPatchLimit < env.allSpots.count {
                withAnimation(.easeInOut(duration: 0.25)) {
                    mapPatchLimit = min(env.allSpots.count, mapPatchLimit + mapPatchSize)
                }
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 1)
                .onChanged { _ in
                    isProgrammaticCameraMoving = false
                }
        )
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.45)
                .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
                .onEnded { value in
                    switch value {
                    case .second(true, let drag):
                        if let location = drag?.location {
                            handleMapLongPress(at: location, proxy: proxy, geometry: geometry)
                        }
                    default:
                        break
                    }
                }
        )
    }

    // MARK: - Center Pin Overlay
    @ViewBuilder
    private func centerPinOverlay(geometry: GeometryProxy) -> some View {
        let pinPoint = addSpotPinPoint(geometry: geometry)
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.24))
                .frame(width: 8, height: 4)
                .position(x: pinPoint.x, y: pinPoint.y + 1)

            centerPinView
                .position(x: pinPoint.x, y: pinPoint.y - 25)
        }
        .allowsHitTesting(false)
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }

    // MARK: - Floating Controls (Recenter & Add Spot FAB)
    @ViewBuilder
    private func floatingControls(proxy: MapProxy, geometry: GeometryProxy) -> some View {
        let pinPoint = addSpotPinPoint(geometry: geometry)
        VStack {
            Spacer()
            HStack {
                Spacer()
                VStack(spacing: 14) {
              
                    if !isAddingSpot {
                        Button {
                            Haptics.tap()
                            enterAddSpotMode(geometry: geometry, proxy: proxy)
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 52, height: 52)
                                .liquidGlassProminent(cornerRadius: 26, tint: env.palette.primary)
                        }
                        .buttonStyle(LiquidGlassButtonStyle())
                    }
                    
                    
                    CircleIconButton(systemName: "location.fill", size: 32, tint: env.palette.primary) {
                        if let coord = env.location.coordinate {
                            let targetPoint = isAddingSpot ? pinPoint : CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            centerCameraOnPin(coordinate: coord, pinPoint: targetPoint, geometry: geometry, proxy: proxy, targetDistance: 800)
                        } else {
                            env.location.requestPermission()
                        }
                    }

                }
                .padding(.trailing, 16)
                .padding(.bottom, isAddingSpot || selectedSpot != nil ? 285 : (30 + geometry.safeAreaInsets.bottom))
            }
        }
    }

    // MARK: - Search Overlay
    @ViewBuilder
    private func searchOverlay(geometry: GeometryProxy, proxy: MapProxy) -> some View {
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
                placeSearchResultsCard(geometry: geometry, proxy: proxy)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, geometry.safeAreaInsets.top + 8)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Place Search Results Dropdown
    private func placeSearchResultsCard(geometry: GeometryProxy, proxy: MapProxy) -> some View {
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
                                        if isAddingSpot {
                                            let pinPoint = addSpotPinPoint(geometry: geometry)
                                            centerCameraOnPin(coordinate: coord, pinPoint: pinPoint, geometry: geometry, proxy: proxy, targetDistance: 800)
                                            mapCenterCoordinate = coord
                                            if newSpotName.isEmpty {
                                                newSpotName = result.title
                                            }
                                        } else {
                                            cameraPosition = .region(MKCoordinateRegion(
                                                center: coord,
                                                latitudinalMeters: 500,
                                                longitudinalMeters: 500
                                            ))
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

    // MARK: - Patched Spots
    private var patchedSpots: [Spot] {
        let onlyId = (initialOnlyShow ? initialSpotId : nil) ?? env.mapOnlyShowSpotId
        if let onlyId {
            if let target = env.spots.first(where: { $0.id == onlyId }) {
                return [target]
            }
            return []
        }

        let all = env.allSpots
        guard all.count > mapPatchLimit else { return all }

        let center = mapCenterCoordinate
        let sorted = all.sorted { s1, s2 in
            if s1.isCar || s1.id == selectedSpotId { return true }
            if s2.isCar || s2.id == selectedSpotId { return false }
            let d1 = DistanceFormatter.calculateDistance(from: center, to: s1.coordinate)
            let d2 = DistanceFormatter.calculateDistance(from: center, to: s2.coordinate)
            return d1 < d2
        }

        return Array(sorted.prefix(mapPatchLimit))
    }

    private var visibleMapSpots: [Spot] {
        patchedSpots.filter { spot in
            if isAddingSpot, let editingSpot, editingSpot.id == spot.id {
                return false
            }
            return true
        }
    }

    private func onSpotTapped(_ spot: Spot, geometry: GeometryProxy, proxy: MapProxy) {
        Haptics.tap()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.72)) {
            selectedSpotId = spot.id
            let screenCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            centerCameraOnPin(coordinate: spot.coordinate, pinPoint: screenCenter, geometry: geometry, proxy: proxy, targetDistance: 800)
        }
    }

    private var selectedSpot: Spot? {
        guard let id = selectedSpotId else { return nil }
        return env.spots.first { $0.id == id }
    }

    private var selectedSpotBinding: Binding<Spot?> {
        Binding(
            get: {
                guard !isAddingSpot, let id = selectedSpotId else { return nil }
                return env.spots.first { $0.id == id }
            },
            set: { newSpot in
                if newSpot == nil {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        selectedSpotId = nil
                        env.mapOnlyShowSpotId = nil
                        env.mapFocusSpotId = nil
                    }
                }
            }
        )
    }

    // MARK: - Spot Marker Annotation
    @ViewBuilder
    private func spotAnnotation(for spot: Spot) -> some View {
        let isSelected = selectedSpotId == spot.id

        VStack(spacing: -2) {
            ZStack {
                Circle()
                    .fill(spot.isCar ? env.palette.car : env.palette.categoryColor(spot.category))
                    .frame(width: isSelected ? 48 : 38, height: isSelected ? 48 : 38)
                    .shadow(
                        color: isSelected ? (spot.isCar ? env.palette.car : env.palette.categoryColor(spot.category)).opacity(0.45) : .black.opacity(0.2),
                        radius: isSelected ? 10 : 6,
                        y: 3
                    )

                if spot.isCar {
                    Image("CarIllustration")
                        .resizable()
                        .scaledToFit()
                        .frame(width: isSelected ? 28 : 22, height: isSelected ? 28 : 22)
                } else {
                    Image(systemName: spot.category.systemImage)
                        .font(.system(size: isSelected ? 20 : 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: isSelected ? 3 : 2)
            )

            Image(systemName: "triangle.fill")
                .font(.system(size: isSelected ? 11 : 8))
                .foregroundStyle(spot.isCar ? env.palette.car : env.palette.categoryColor(spot.category))
                .rotationEffect(.degrees(180))
        }
        .scaleEffect(isSelected ? 1.15 : 1.0, anchor: .bottom)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSelected)
        .overlay(alignment: .top) {
            Text(spot.isCar ? env.l10n.t("myCar") : spot.name)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(env.palette.textPrimary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(env.effectiveColorScheme == .dark ? Color(hex: 0x162232).opacity(0.85) : Color.white.opacity(0.85))
                        .shadow(color: .black.opacity(0.15), radius: 3, y: 1)
                )
                .fixedSize()
                .offset(y: (isSelected ? 56 : 44) + 4)
                .allowsHitTesting(false)
        }
    }

    // MARK: - Center Pin View
    private var centerPinView: some View {
        let pinColor = newSpotCategory != nil ? env.palette.categoryColor(newSpotCategory!) : env.palette.primary
        let pinIcon = newSpotCategory?.systemImage ?? "mappin"
        return VStack(spacing: -2) {
            ZStack {
                Circle()
                    .fill(pinColor)
                    .frame(width: 44, height: 44)
                    .shadow(color: .black.opacity(0.25), radius: 6, y: 3)

                Image(systemName: pinIcon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .overlay(
                Circle()
                    .stroke(Color.white, lineWidth: 2.5)
            )

            Image(systemName: "triangle.fill")
                .font(.system(size: 10))
                .foregroundStyle(pinColor)
                .rotationEffect(.degrees(180))
        }
        .frame(height: 50, alignment: .bottom)
    }

    // MARK: - Pin Positioning
    private func addSpotPinPoint(geometry: GeometryProxy) -> CGPoint {
        let topOffset = geometry.safeAreaInsets.top + 60
        let sheetHeight: CGFloat = 275
        let visibleHeight = max(100, geometry.size.height - topOffset - sheetHeight)
        return CGPoint(x: geometry.size.width / 2, y: topOffset + visibleHeight / 2)
    }

    // MARK: - Camera Movement
    private func centerCameraOnPin(
        coordinate: CLLocationCoordinate2D,
        pinPoint: CGPoint,
        geometry: GeometryProxy,
        proxy: MapProxy,
        targetDistance: CLLocationDistance? = nil
    ) {
        let screenCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let distance = targetDistance ?? (mapCameraDistance > 0 ? mapCameraDistance : 1000)
        isProgrammaticCameraMoving = true

        if let centerCoord = proxy.convert(screenCenter, from: .local),
           let pinCoord = proxy.convert(pinPoint, from: .local) {
            let deltaLat = pinCoord.latitude - centerCoord.latitude
            let deltaLng = pinCoord.longitude - centerCoord.longitude
            let targetCenter = CLLocationCoordinate2D(
                latitude: coordinate.latitude - deltaLat,
                longitude: coordinate.longitude - deltaLng
            )
            withAnimation(.easeInOut(duration: 0.35)) {
                cameraPosition = .camera(MapCamera(centerCoordinate: targetCenter, distance: distance))
            }
        } else {
            let span = mapCameraRegion?.span.latitudeDelta ?? 0.005
            let latPerPoint = span / max(1, geometry.size.height)
            let deltaY = (geometry.size.height / 2) - pinPoint.y
            let latOffset = deltaY * latPerPoint
            let targetCenter = CLLocationCoordinate2D(
                latitude: coordinate.latitude - latOffset,
                longitude: coordinate.longitude
            )
            withAnimation(.easeInOut(duration: 0.35)) {
                cameraPosition = .camera(MapCamera(centerCoordinate: targetCenter, distance: distance))
            }
        }
    }

    private func setupInitialState(geometry: GeometryProxy, proxy: MapProxy) {
        if let draft = env.saveDraft {
            enterAddSpotMode(draft: draft, geometry: geometry, proxy: proxy)
            return
        }
        let onlyShow = initialOnlyShow || (env.mapOnlyShowSpotId != nil)
        let focusId = initialSpotId ?? env.mapFocusSpotId
        if let focusId, let spot = env.spots.first(where: { $0.id == focusId }) {
            selectedSpotId = spot.id
            mapCenterCoordinate = spot.coordinate
            if onlyShow {
                env.mapOnlyShowSpotId = spot.id
            }
            let screenCenter = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            centerCameraOnPin(coordinate: spot.coordinate, pinPoint: screenCenter, geometry: geometry, proxy: proxy, targetDistance: 800)
        } else if let user = env.location.coordinate {
            mapCenterCoordinate = user
            cameraPosition = .region(MKCoordinateRegion(center: user, latitudinalMeters: 1200, longitudinalMeters: 1200))
        }
    }

    private func enterAddSpotMode(draft: AppEnvironment.SaveDraft? = nil, geometry: GeometryProxy, proxy: MapProxy) {
        selectedSpotId = nil
        isAddingSpot = true
        let pinPoint = addSpotPinPoint(geometry: geometry)

        if let draft {
            newSpotName = draft.name ?? ""
            if let editId = draft.editingId, let spot = env.allSpots.first(where: { $0.id == editId }) {
                editingSpot = spot
                newSpotCategory = spot.category
                mapCenterCoordinate = spot.coordinate
                centerCameraOnPin(coordinate: spot.coordinate, pinPoint: pinPoint, geometry: geometry, proxy: proxy)
            } else if let lat = draft.latitude, let lng = draft.longitude {
                let coord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
                mapCenterCoordinate = coord
                centerCameraOnPin(coordinate: coord, pinPoint: pinPoint, geometry: geometry, proxy: proxy)
            }
        } else {
            newSpotName = ""
            newSpotCategory = nil
            editingSpot = nil
            if let exact = proxy.convert(pinPoint, from: .local) {
                mapCenterCoordinate = exact
            }
        }
    }

    private func handleMapLongPress(at touchPoint: CGPoint, proxy: MapProxy, geometry: GeometryProxy) {
        guard let exactCoord = proxy.convert(touchPoint, from: .local) else { return }
        Haptics.success()
        editingSpot = nil
        newSpotName = ""
        newSpotCategory = nil
        mapCenterCoordinate = exactCoord

        let pinPoint = addSpotPinPoint(geometry: geometry)
        centerCameraOnPin(coordinate: exactCoord, pinPoint: pinPoint, geometry: geometry, proxy: proxy)

        if selectedSpotId != nil {
            selectedSpotId = nil
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isAddingSpot = true
            }
        } else {
            isAddingSpot = true
        }
    }

    private func exitAddSpotMode() {
        isAddingSpot = false
        editingSpot = nil
        env.saveDraft = nil
    }

    private func saveSpotAction(proxy: MapProxy, geometry: GeometryProxy) {
        let finalCategory = newSpotCategory ?? .other
        let trimmed = newSpotName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? finalCategory.label(env.l10n) : trimmed

        let pinPoint = addSpotPinPoint(geometry: geometry)
        let exactCoordinate: CLLocationCoordinate2D
        if let converted = proxy.convert(pinPoint, from: .local) {
            exactCoordinate = converted
        } else {
            exactCoordinate = mapCenterCoordinate
        }

        env.saveSpot(
            name: finalName,
            category: finalCategory,
            latitude: exactCoordinate.latitude,
            longitude: exactCoordinate.longitude,
            editingId: editingSpot?.id
        )

        exitAddSpotMode()
    }

    // MARK: - Back Navigation Handling
    private var hasOpenSheet: Bool {
        isAddingSpot || selectedSpotId != nil || isSearchExpanded
    }

    private func handleBackAction() {
        if isAddingSpot {
            withAnimation(.easeInOut(duration: 0.25)) {
                exitAddSpotMode()
            }
            return
        }
        if selectedSpotId != nil {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedSpotId = nil
                env.mapOnlyShowSpotId = nil
                env.mapFocusSpotId = nil
            }
            return
        }
        if isSearchExpanded {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                isSearchExpanded = false
                searchRawText = ""
            }
            return
        }
        dismiss()
    }
}

fileprivate struct InteractiveBackGestureHandler: UIViewControllerRepresentable {
    var isEnabled: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        context.coordinator.setup(for: vc, isEnabled: isEnabled)
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        context.coordinator.setup(for: uiViewController, isEnabled: isEnabled)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var nav: UINavigationController?

        func setup(for vc: UIViewController, isEnabled: Bool) {
            DispatchQueue.main.async {
                guard let nav = vc.navigationController else { return }
                self.nav = nav
                if isEnabled {
                    nav.interactivePopGestureRecognizer?.isEnabled = true
                    nav.interactivePopGestureRecognizer?.delegate = self
                } else {
                    nav.interactivePopGestureRecognizer?.isEnabled = false
                }
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard let nav else { return false }
            return nav.viewControllers.count > 1
        }
    }
}
