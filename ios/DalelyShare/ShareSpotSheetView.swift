import CoreLocation
import SwiftUI

struct ShareSpotSheetView: View {
    @ObservedObject var viewModel: ShareSpotViewModel
    var onSave: (Spot) -> Void
    var onCancel: () -> Void

    @State private var name: String = ""
    @State private var category: SpotCategory = .other
    @State private var coordinate: CLLocationCoordinate2D? = nil
    @State private var isApproximate: Bool = false
    @State private var fallbackName: String? = nil
    @State private var isResolving: Bool = true
    @State private var resolveFailed: Bool = false
    @State private var isSaved: Bool = false

    @Environment(\.colorScheme) private var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    private var isArabic: Bool {
        if let code = LocalStore.loadSettings().localeCode {
            return code.starts(with: "ar")
        }
        return Locale.current.language.languageCode?.identifier == "ar"
    }

    private var categories: [SpotCategory] {
        [.other] + SpotCategory.selectable.filter { $0 != .other }
    }

    /// The card is only shown while resolving, on failure, or when the point is approximate.
    /// A correctly fetched point shows nothing.
    private var showStatusCard: Bool {
        isResolving || resolveFailed || (coordinate != nil && isApproximate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    // Pinned top section
                    VStack(spacing: 14) {
                        if showStatusCard {
                            locationStatusCard
                        }
                        spotNameSection
                        categoryHeader
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                    // Only the categories scroll
                    ScrollView {
                        categoryList
                            .padding(.horizontal, 16)
                            .padding(.top, 2)
                            .padding(.bottom, 12)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .pinnedBottomBar {
                        saveButton
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle(isArabic ? "إضافة مكان" : "Add Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isArabic ? "إلغاء" : "Cancel") {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(isArabic ? "حفظ" : "Save") {
                        handleSave()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: 0x3C79F3))
                    .disabled(coordinate == nil || isSaved)
                }
            }
            .environment(\.layoutDirection, isArabic ? .rightToLeft : .leftToRight)
        }
        .onAppear {
            if viewModel.isContentExtracted {
                resolveCoordinates()
            }
        }
        .onChange(of: viewModel.isContentExtracted) { _, extracted in
            if extracted {
                resolveCoordinates()
            }
        }
    }

    // MARK: - Location Status Component (resolving / failed / approximate only)
    private var locationStatusCard: some View {
        HStack(spacing: 12) {
            if isResolving {
                ProgressView()
                    .scaleEffect(0.9)
                Text(isArabic ? "جارٍ تحديد الإحداثيات من الرابط..." : "Resolving coordinates from link...")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: 0x3C79F3))
            } else if resolveFailed {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.orange)
                Text(isArabic ? "تعذر استخراج الإحداثيات من الرابط" : "Could not find coordinates in link")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.orange)
            } else if isApproximate {
                Image(systemName: "location.magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundStyle(Color.orange)
                Text(isArabic ? "الموقع تقريبي، تأكد منه قبل الحفظ" : "Approximate location, double check before saving")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.orange)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color(uiColor: .separator).opacity(0.35), lineWidth: 0.8)
        )
    }

    // MARK: - Spot Name Input Component
    private var spotNameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isArabic ? "اسم المكان" : "Spot name")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .padding(.horizontal, 2)

            HStack(spacing: 10) {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x3C79F3))

                TextField(
                    isArabic ? "مثال: بقالة، صيدلية، مطعم..." : "e.g. Pharmacy, Restaurant, Home...",
                    text: $name
                )
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(Color(uiColor: .label))
                .submitLabel(.done)

                if !name.isEmpty {
                    Button {
                        name = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color(uiColor: .separator).opacity(0.35), lineWidth: 0.8)
            )
        }
    }

    // MARK: - Category Selector Component (single scrollable column)
    private var categoryHeader: some View {
        Text(isArabic ? "التصنيف" : "Category")
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(uiColor: .secondaryLabel))
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var categoryList: some View {
        GlassContainer(spacing: 8) {
            VStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    categoryRow(cat)
                }
            }
        }
    }

    private func categoryRow(_ cat: SpotCategory) -> some View {
        let isSelected = category == cat
        let catColor = cat.color(isDark: isDark)

        return Button {
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                category = cat
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.22) : catColor.opacity(0.16))
                        .frame(width: 34, height: 34)
                    Image(systemName: cat.iconName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : catColor)
                }

                Text(cat.localizedName(isArabic: isArabic))
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium, design: .rounded))
                    .frame(maxWidth: .infinity, alignment: .leading)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .bold))
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .foregroundStyle(isSelected ? Color.white : Color(uiColor: .label))
            .contentShape(Rectangle())
            .glassRowBackground(isSelected: isSelected, tint: catColor)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save Action Button (pinned at the bottom)
    private var saveButton: some View {
        Button {
            handleSave()
        } label: {
            HStack(spacing: 8) {
                if isSaved {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                    Text(isArabic ? "تم الحفظ بنجاح!" : "Saved successfully!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                    Text(isArabic ? "حفظ المكان في دليلى" : "Save Spot to Dalely")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .glassProminentButton(tint: isSaved ? Color(hex: 0x0E9F75) : Color(hex: 0x3C79F3))
        .controlSize(.large)
        .buttonBorderShape(.capsule)
        .disabled(coordinate == nil || isSaved)
    }

    // MARK: - Actions & Resolution
    private func handleSave() {
        guard let coord = coordinate, !isSaved else { return }
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmedName.isEmpty ? category.localizedName(isArabic: isArabic) : trimmedName

        let spot = Spot(
            id: UUID().uuidString,
            name: finalName,
            category: category,
            latitude: coord.latitude,
            longitude: coord.longitude,
            savedAt: Date()
        )
        isSaved = true
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onSave(spot)
        }
    }

    private func usableName(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isDigitsOnly = !trimmed.isEmpty && trimmed.allSatisfy { $0.isNumber || $0 == "-" || $0 == " " }
        return (trimmed.isEmpty || isDigitsOnly) ? nil : trimmed
    }

    private func apply(_ parsed: ParsedGeoLocation, suggested: String?) {
        let coord = CLLocationCoordinate2D(latitude: parsed.latitude, longitude: parsed.longitude)
        coordinate = coord
        isApproximate = parsed.isApproximate

        // 1. The place name from the link is the preferred name.
        if let label = parsed.label, let usable = usableName(label) {
            name = usable
        }
        // 2. No place name: the reverse-geocoded address fills the field (see reverseGeocode).
        // 3. Geocoding returned nothing: use the address that came with the link, then the suggested label.
        fallbackName = [parsed.address, suggested]
            .compactMap { $0 }
            .compactMap { usableName($0) }
            .first
        isResolving = false
        reverseGeocode(coord)
    }

    private func resolveCoordinates() {
        let raw = viewModel.rawContent
        let suggested = viewModel.suggestedLabel

        if let direct = GeoUriParser.parse(raw) {
            apply(direct, suggested: suggested)
            return
        }

        Task {
            if let asyncParsed = await GeoUriParser.parseAsync(raw) {
                await MainActor.run {
                    self.apply(asyncParsed, suggested: suggested)
                }
            } else {
                await MainActor.run {
                    self.isResolving = false
                    self.resolveFailed = true
                }
            }
        }
    }

    /// Runs only when no place name is available yet. Fills the name field with the
    /// reverse-geocoded address. A name already in the field (from the link or typed by
    /// the user) is left alone. If geocoding returns nothing, the link's address is used.
    private func reverseGeocode(_ coord: CLLocationCoordinate2D) {
        let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        CLGeocoder().reverseGeocodeLocation(loc) { placemarks, _ in
            var resolved = ""

            if let p = placemarks?.first {
                let placeTitle: String = {
                    if let aoi = p.areasOfInterest?.first, !aoi.isEmpty { return aoi }
                    if let n = p.name, !n.isEmpty { return n }
                    if let street = p.thoroughfare, !street.isEmpty { return street }
                    if let subLoc = p.subLocality, !subLoc.isEmpty { return subLoc }
                    if let city = p.locality, !city.isEmpty { return city }
                    return ""
                }()

                var addressParts: [String] = []
                if let street = p.thoroughfare, street != placeTitle { addressParts.append(street) }
                if let subLocality = p.subLocality, subLocality != placeTitle { addressParts.append(subLocality) }
                if let city = p.locality, city != placeTitle { addressParts.append(city) }

                resolved = addressParts.isEmpty ? placeTitle : addressParts.joined(separator: ", ")
            }

            DispatchQueue.main.async {
                guard self.usableName(self.name) == nil else { return }
                if let address = self.usableName(resolved) {
                    self.name = address
                } else if let fallback = self.fallbackName {
                    self.name = fallback
                }
            }
        }
    }
}

// MARK: - Liquid Glass helpers (iOS 26+, with fallbacks for earlier versions)

/// Groups glass elements so they render and blend consistently on iOS 26.
private struct GlassContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content()
            }
        } else {
            content()
        }
    }
}

private struct GlassRowBackground: ViewModifier {
    let isSelected: Bool
    let tint: Color

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(
                isSelected ? .regular.tint(tint).interactive() : .regular.interactive(),
                in: .rect(cornerRadius: 16)
            )
        } else {
            content
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(isSelected ? tint : Color(uiColor: .secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(isSelected ? Color.clear : Color(uiColor: .separator).opacity(0.35), lineWidth: 0.8)
                )
        }
    }
}

private extension View {
    func glassRowBackground(isSelected: Bool, tint: Color) -> some View {
        modifier(GlassRowBackground(isSelected: isSelected, tint: tint))
    }

    @ViewBuilder
    func glassProminentButton(tint: Color) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent).tint(tint)
        } else {
            self.buttonStyle(.borderedProminent).tint(tint)
        }
    }

    /// Pins a bar to the bottom edge. On iOS 26 the scroll content gets the soft edge effect under it.
    @ViewBuilder
    func pinnedBottomBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        if #available(iOS 26.0, *) {
            self.safeAreaBar(edge: .bottom) { bar() }
        } else {
            self.safeAreaInset(edge: .bottom) { bar().background(.bar) }
        }
    }
}

// MARK: - Category Helpers
extension SpotCategory {
    func localizedName(isArabic: Bool) -> String {
        switch self {
        case .market: return isArabic ? "بقالة / متجر" : "Market"
        case .pharmacy: return isArabic ? "صيدلية" : "Pharmacy"
        case .restaurant: return isArabic ? "مطعم / مقهى" : "Restaurant"
        case .home: return isArabic ? "المنزل" : "Home"
        case .work: return isArabic ? "العمل" : "Work"
        case .gym: return isArabic ? "نادي رياضي" : "Gym"
        case .hospital: return isArabic ? "مستشفى" : "Hospital"
        case .school: return isArabic ? "مدرسة" : "School"
        case .mosque: return isArabic ? "مسجد" : "Mosque"
        case .fuel: return isArabic ? "محطة وقود" : "Fuel"
        case .park: return isArabic ? "حديقة" : "Park"
        case .club: return isArabic ? "نادي" : "Club"
        case .beautyCenter: return isArabic ? "مركز تجميل" : "Beauty Center"
        case .car: return isArabic ? "السيارة" : "Car"
        case .other: return isArabic ? "أخرى" : "Other"
        }
    }

    func color(isDark: Bool) -> Color {
        if isDark {
            switch self {
            case .car: return Color(hex: 0xFF8A65)
            case .market: return Color(hex: 0x38BDF8)
            case .home: return Color(hex: 0x34D399)
            case .pharmacy: return Color(hex: 0xF472B6)
            case .work: return Color(hex: 0xA78BFA)
            case .restaurant: return Color(hex: 0xFBBF24)
            case .hospital: return Color(hex: 0xF87171)
            case .school: return Color(hex: 0x22D3EE)
            case .gym: return Color(hex: 0x2DD4BF)
            case .mosque: return Color(hex: 0x10B981)
            case .fuel: return Color(hex: 0xF59E0B)
            case .park: return Color(hex: 0x4ADE80)
            case .club: return Color(hex: 0x818CF8)
            case .beautyCenter: return Color(hex: 0xFB7185)
            case .other: return Color(hex: 0x38BDF8)
            }
        } else {
            switch self {
            case .car: return Color(hex: 0xFF8A65)
            case .market: return Color(hex: 0x3C79F3)
            case .home: return Color(hex: 0x10B981)
            case .pharmacy: return Color(hex: 0xEC4899)
            case .work: return Color(hex: 0x8B5CF6)
            case .restaurant: return Color(hex: 0xF59E0B)
            case .hospital: return Color(hex: 0xEF4444)
            case .school: return Color(hex: 0x06B6D4)
            case .gym: return Color(hex: 0x14B8A6)
            case .mosque: return Color(hex: 0x059669)
            case .fuel: return Color(hex: 0xD97706)
            case .park: return Color(hex: 0x16A34A)
            case .club: return Color(hex: 0x6366F1)
            case .beautyCenter: return Color(hex: 0xE11D48)
            case .other: return Color(hex: 0x3C79F3)
            }
        }
    }
}

fileprivate extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}