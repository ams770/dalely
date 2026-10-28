import CoreLocation
import SwiftUI

struct SaveSpotBottomPanelView: View {
    @Binding var name: String
    @Binding var category: SpotCategory?
    let coordinate: CLLocationCoordinate2D
    let isEditing: Bool
    var onSave: () -> Void
    var onClose: () -> Void

    @Environment(AppEnvironment.self) private var env
    @State private var addressText: String = ""
    @State private var fetchedPlaceName: String = ""
    @State private var hasUserManuallyEditedName: Bool = false
    @State private var isCustomNameEditing: Bool = false
    @State private var geocodeTask: Task<Void, Never>? = nil
    @State private var lastGeocodedLocation: CLLocation? = nil
    @State private var lastGeocodeTimestamp: Date = .distantPast
    @FocusState private var isNameFieldFocused: Bool

    init(
        name: Binding<String>,
        category: Binding<SpotCategory?>,
        coordinate: CLLocationCoordinate2D,
        isEditing: Bool,
        onSave: @escaping () -> Void,
        onClose: @escaping () -> Void
    ) {
        self._name = name
        self._category = category
        self.coordinate = coordinate
        self.isEditing = isEditing
        self.onSave = onSave
        self.onClose = onClose
        self._isCustomNameEditing = State(initialValue: isEditing)
        self._hasUserManuallyEditedName = State(initialValue: isEditing)
    }

    private var displayName: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            return trimmedName
        }
        if !fetchedPlaceName.isEmpty {
            return fetchedPlaceName
        }
        if let cat = category {
            return cat.label(env.l10n)
        }
        if !addressText.isEmpty {
            return addressText
        }
        return env.l10n.t("categoryOther")
    }

    var body: some View {
        VStack(spacing: 10) {
            // Drag handle matching native sheet styling
            Capsule()
                .fill(env.palette.border)
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            // Header Row
            HStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill((category != nil ? env.palette.categoryColor(category!) : env.palette.primary).opacity(0.15))
                    Image(systemName: isEditing ? "pencil.circle.fill" : (category?.systemImage ?? "mappin.circle.fill"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(category != nil ? env.palette.categoryColor(category!) : env.palette.primary)
                }
                .frame(width: 36, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(isEditing ? env.l10n.t("renameSpotTitle") : env.l10n.t("saveThisSpot"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(env.palette.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(env.palette.primary)
                        Text(addressText.isEmpty ? String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude) : addressText)
                            .font(.system(size: 11, design: .rounded))
                            .foregroundStyle(env.palette.textSecondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                CircleIconButton(systemName: "xmark", size: 30) {
                    onClose()
                }
            }
            .padding(.horizontal, 16)

            // Name Container: Caught map name (default) OR custom input (when edit tapped)
            if !isCustomNameEditing {
                // Static caught name display with edit button
                HStack(spacing: 10) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(env.palette.primary)

                    Text(displayName)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundStyle(env.palette.textPrimary)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if name.isEmpty {
                                name = displayName
                            }
                            hasUserManuallyEditedName = true
                            isCustomNameEditing = true
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                            isNameFieldFocused = true
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .bold))
                            Text(env.l10n.t("edit"))
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(env.palette.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(env.palette.primary.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(env.l10n.t("edit"))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(env.effectiveColorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: 0xF1F5F9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(env.effectiveColorScheme == .dark ? Color.white.opacity(0.12) : Color(hex: 0xE2E8F0), lineWidth: 0.5)
                        )
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if name.isEmpty {
                            name = displayName
                        }
                        hasUserManuallyEditedName = true
                        isCustomNameEditing = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                        isNameFieldFocused = true
                    }
                }
                .padding(.horizontal, 16)
            } else {
                // Editable text input field
                HStack(spacing: 10) {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(env.palette.primary)

                    TextField(env.l10n.t("nameHint"), text: $name)
                        .font(.system(size: 15, design: .rounded))
                        .focused($isNameFieldFocused)
                        .submitLabel(.done)
                        .onChange(of: name) { _, _ in
                            hasUserManuallyEditedName = true
                        }
                        .onSubmit {
                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isCustomNameEditing = false
                            }
                        }

                    if !name.isEmpty {
                        Button {
                            name = ""
                            hasUserManuallyEditedName = false
                            scheduleReverseGeocode()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(env.palette.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isCustomNameEditing = false
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(env.palette.primary)
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(env.palette.primary.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(env.effectiveColorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: 0xF1F5F9))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(env.palette.primary.opacity(0.5), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 16)
            }

            // Category Chips directly below it (default: none selected)
            CategoryChips(selected: category, includeCar: false) { cat in
                category = cat
            }

            // Save Button
            PrimaryBottomButton(label: isEditing ? env.l10n.t("save") : env.l10n.t("saveHere"), systemImage: "checkmark") {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    name = displayName
                }
                onSave()
            }
        }
        .frame(maxWidth: .infinity)
        .environment(\.layoutDirection, env.layoutDirection)
        .presentationDetents([.height(275)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(env.palette.surface)
        .presentationBackgroundInteraction(.enabled(upThrough: .height(275)))
        .onAppear {
            scheduleReverseGeocode()
        }
        .onChange(of: coordinate.latitude) { _, _ in
            scheduleReverseGeocode()
        }
        .onChange(of: coordinate.longitude) { _, _ in
            scheduleReverseGeocode()
        }
        .onDisappear {
            geocodeTask?.cancel()
        }
    }

    private func scheduleReverseGeocode() {
        guard !hasUserManuallyEditedName else { return }

        let loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        if let last = lastGeocodedLocation {
            let distance = loc.distance(from: last)
            let elapsed = Date().timeIntervalSince(lastGeocodeTimestamp)
            if distance > 30 && elapsed > 1.0 {
                geocodeTask?.cancel()
                geocodeTask = Task {
                    await performReverseGeocode()
                }
                return
            }
        }

        geocodeTask?.cancel()
        geocodeTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            await performReverseGeocode()
        }
    }

    @MainActor
    private func performReverseGeocode() async {
        guard !hasUserManuallyEditedName else { return }
        let loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        lastGeocodeTimestamp = Date()
        lastGeocodedLocation = loc

        do {
            let placemarks = try await CLGeocoder().reverseGeocodeLocation(loc)
            guard !Task.isCancelled, let p = placemarks.first else { return }

            let placeTitle: String = {
                if let aoi = p.areasOfInterest?.first, !aoi.isEmpty {
                    return aoi
                }
                if let n = p.name, !n.isEmpty {
                    return n
                }
                if let street = p.thoroughfare, !street.isEmpty {
                    return street
                }
                if let subLoc = p.subLocality, !subLoc.isEmpty {
                    return subLoc
                }
                if let city = p.locality, !city.isEmpty {
                    return city
                }
                return ""
            }()

            var addressParts: [String] = []
            if let street = p.thoroughfare, street != placeTitle { addressParts.append(street) }
            if let subLocality = p.subLocality, subLocality != placeTitle { addressParts.append(subLocality) }
            if let city = p.locality { addressParts.append(city) }

            self.fetchedPlaceName = placeTitle
            self.addressText = addressParts.joined(separator: ", ")

            if !hasUserManuallyEditedName && !isEditing {
                if !placeTitle.isEmpty {
                    self.name = placeTitle
                } else if !self.addressText.isEmpty {
                    self.name = self.addressText
                } else {
                    self.name = ""
                }
            }
        } catch {
            // Geocoding in unmapped area or network offline
        }
    }
}
