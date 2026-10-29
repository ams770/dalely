import CoreLocation
import SwiftUI

struct ShareSpotSheetView: View {
    @ObservedObject var viewModel: ShareSpotViewModel
    var onSave: (Spot) -> Void
    var onCancel: () -> Void

    @State private var name: String = ""
    @State private var category: SpotCategory = .other
    @State private var coordinate: CLLocationCoordinate2D? = nil
    @State private var addressText: String = ""
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

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 14) {
                        // 1. Location Status Component
                        locationStatusCard

                        // 2. Spot Name Input Component
                        spotNameSection

                        // 3. Category Selector Component
                        categorySection

                        // 4. Primary Save Action Button
                        saveButton
                            .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationTitle(isArabic ? "إضافة مكان" : "Add Spot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(uiColor: .systemGroupedBackground), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: 0x3C79F3))
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

    // MARK: - Location Status Component
    private var locationStatusCard: some View {
        HStack(spacing: 12) {
            if isResolving {
                ProgressView()
                    .scaleEffect(0.9)
                Text(isArabic ? "جارٍ تحديد الإحداثيات من الرابط..." : "Resolving coordinates from link...")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: 0x3C79F3))
            } else if let coord = coordinate {
                ZStack {
                    Circle()
                        .fill(Color(hex: 0x0E9F75).opacity(0.14))
                        .frame(width: 36, height: 36)
                    Image(systemName: "mappin.and.ellipse")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color(hex: 0x0E9F75))
                }

                VStack(alignment: .leading, spacing: 2) {
                    if !addressText.isEmpty {
                        Text(addressText)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(uiColor: .label))
                            .lineLimit(1)
                    }
                    Text(String(format: "%.5f, %.5f", coord.latitude, coord.longitude))
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }
            } else if resolveFailed {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.orange)
                Text(isArabic ? "تعذر استخراج الإحداثيات من الرابط" : "Could not find coordinates in link")
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

    // MARK: - Category Selector Component
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(isArabic ? "التصنيف" : "Category")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .padding(.horizontal, 2)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { cat in
                            let isSelected = category == cat
                            let catColor = cat.color(isDark: isDark)
                            Button {
                                let generator = UISelectionFeedbackGenerator()
                                generator.selectionChanged()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                    category = cat
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: cat.iconName)
                                        .font(.system(size: 13, weight: .semibold))

                                    Text(cat.localizedName(isArabic: isArabic))
                                        .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))

                                    if isSelected {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                    }
                                }
                                .padding(.horizontal, 13)
                                .frame(height: 38)
                                .foregroundStyle(isSelected ? Color.white : Color(uiColor: .label))
                                .background(
                                    Capsule()
                                        .fill(isSelected ? catColor : Color(uiColor: .secondarySystemGroupedBackground))
                                )
                                .overlay(
                                    Capsule()
                                        .strokeBorder(isSelected ? Color.clear : Color(uiColor: .separator).opacity(0.35), lineWidth: 0.8)
                                )
                            }
                            .buttonStyle(.plain)
                            .id(cat.rawValue)
                        }
                    }
                    .padding(.horizontal, 1)
                    .padding(.vertical, 2)
                }
                .onAppear {
                    if category != .other {
                        proxy.scrollTo(category.rawValue, anchor: .center)
                    }
                }
            }
        }
    }

    // MARK: - Save Action Button
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
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                Capsule()
                    .fill(isSaved ? Color(hex: 0x0E9F75) : (coordinate == nil ? Color.gray.opacity(0.4) : Color(hex: 0x3C79F3)))
            )
            .shadow(
                color: (coordinate == nil || isSaved) ? Color.clear : Color(hex: 0x3C79F3).opacity(0.25),
                radius: 6,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .disabled(coordinate == nil || isSaved)
    }

    // MARK: - Actions & Resolution
    private func handleSave() {
        guard let coord = coordinate, !isSaved else { return }
        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? (category.localizedName(isArabic: isArabic))
            : name.trimmingCharacters(in: .whitespacesAndNewlines)

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

    private func resolveCoordinates() {
        let raw = viewModel.rawContent
        let suggested = viewModel.suggestedLabel

        if let direct = GeoUriParser.parse(raw) {
            let coord = CLLocationCoordinate2D(latitude: direct.latitude, longitude: direct.longitude)
            coordinate = coord

            if let label = direct.label ?? suggested {
                let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
                let isDigitsOnly = !trimmed.isEmpty && trimmed.allSatisfy { $0.isNumber || $0 == "-" || $0 == " " }
                if !isDigitsOnly {
                    name = trimmed
                }
            }
            isResolving = false
            reverseGeocode(coord)
            return
        }

        Task {
            if let asyncParsed = await GeoUriParser.parseAsync(raw) {
                await MainActor.run {
                    let coord = CLLocationCoordinate2D(latitude: asyncParsed.latitude, longitude: asyncParsed.longitude)
                    self.coordinate = coord
                    if let label = asyncParsed.label ?? suggested {
                        let trimmed = label.trimmingCharacters(in: .whitespacesAndNewlines)
                        let isDigitsOnly = !trimmed.isEmpty && trimmed.allSatisfy { $0.isNumber || $0 == "-" || $0 == " " }
                        if !isDigitsOnly {
                            self.name = trimmed
                        }
                    }
                    self.isResolving = false
                    self.reverseGeocode(coord)
                }
            } else {
                await MainActor.run {
                    self.isResolving = false
                    self.resolveFailed = true
                }
            }
        }
    }

    private func reverseGeocode(_ coord: CLLocationCoordinate2D) {
        let loc = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        CLGeocoder().reverseGeocodeLocation(loc) { placemarks, _ in
            if let p = placemarks?.first {
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
                if let city = p.locality, city != placeTitle { addressParts.append(city) }

                DispatchQueue.main.async {
                    self.addressText = addressParts.isEmpty ? placeTitle : addressParts.joined(separator: ", ")

                    let currentTrimmed = self.name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let isDigitsOnly = !currentTrimmed.isEmpty && currentTrimmed.allSatisfy { $0.isNumber || $0 == "-" || $0 == " " }

                    if (currentTrimmed.isEmpty || isDigitsOnly) && !placeTitle.isEmpty {
                        self.name = placeTitle
                    }
                }
            }
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
