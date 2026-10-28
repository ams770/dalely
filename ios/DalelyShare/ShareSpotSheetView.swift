import CoreLocation
import SwiftUI

struct ShareSpotSheetView: View {
    var rawSharedText: String?
    var suggestedLabel: String?
    var onSave: (Spot) -> Void
    var onCancel: () -> Void

    @State private var name: String = ""
    @State private var category: SpotCategory = .other
    @State private var coordinate: CLLocationCoordinate2D? = nil
    @State private var addressText: String = ""
    @State private var isResolving: Bool = true
    @State private var resolveFailed: Bool = false
    @State private var isSaved: Bool = false
    @State private var isVisible: Bool = false
    @State private var dragOffset: CGFloat = 0

    @Environment(\.colorScheme) private var colorScheme
    private var isDark: Bool { colorScheme == .dark }

    private var categories: [SpotCategory] {
        [.other] + SpotCategory.selectable.filter { $0 != .other }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Completely clear backdrop with tap to dismiss
            Color.clear
                .contentShape(Rectangle())
                .ignoresSafeArea()
                .onTapGesture {
                    dismissSheet()
                }

            if isVisible {
                // Native Bottom Sheet Container
                VStack(spacing: 0) {
                    // Top Drag Indicator Grabber
                    Capsule()
                        .fill(isDark ? Color.white.opacity(0.25) : Color.black.opacity(0.2))
                        .frame(width: 40, height: 5)
                        .padding(.top, 10)
                        .padding(.bottom, 10)

                    // Sheet Header with App Icon
                    HStack(spacing: 12) {
                        if let uiImage = UIImage(named: "AppIcon", in: Bundle.main, with: nil) ?? UIImage(named: "AppIcon") ?? UIImage(named: "AppLogo") {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                                .shadow(color: Color.black.opacity(0.15), radius: 4, y: 2)
                        } else {
                            Image(systemName: "mappin.and.ellipse")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color(hex: 0x3C79F3))
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color(hex: 0x3C79F3).opacity(0.14)))
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(isArabic ? "دليلى — إضافة مكان" : "Dalely — Add Spot")
                                .font(.system(size: 19, weight: .bold, design: .rounded))
                                .foregroundStyle(isDark ? Color.white : Color(hex: 0x12263F))

                            Text(isArabic ? "حفظ المكان مباشرة في دليلى" : "Save spot directly to Dalely")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(isDark ? Color.white.opacity(0.65) : Color(hex: 0x64748B))
                        }

                        Spacer()

                        Button {
                            dismissSheet()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(isDark ? Color.white.opacity(0.7) : Color(hex: 0x64748B))
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(isDark ? Color.white.opacity(0.12) : Color.black.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    Divider()
                        .overlay(isDark ? Color.white.opacity(0.1) : Color.black.opacity(0.06))

                    // Spot Name Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isArabic ? "اسم المكان" : "Spot name")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(isDark ? Color.white.opacity(0.9) : Color(hex: 0x12263F))

                        HStack(spacing: 10) {
                            Image(systemName: "pencil")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(Color(hex: 0x3C79F3))

                            TextField(
                                isArabic ? "مثال: بقالة، صيدلية، مطعم..." : "e.g. Pharmacy, Restaurant, Home...",
                                text: $name
                            )
                            .font(.system(size: 16, design: .rounded))
                            .foregroundStyle(isDark ? Color.white : Color(hex: 0x12263F))

                            if !name.isEmpty {
                                Button {
                                    name = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(isDark ? Color.white.opacity(0.45) : Color.black.opacity(0.3))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 48)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(isDark ? Color(hex: 0x182433) : Color(hex: 0xF3F9FF))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(isDark ? Color.white.opacity(0.12) : Color(hex: 0x3C79F3).opacity(0.22), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

                    // Category Section Header
                    HStack {
                        Text(isArabic ? "التصنيف" : "Category")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(isDark ? Color.white.opacity(0.9) : Color(hex: 0x12263F))
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .padding(.bottom, 4)

                    // Category Selector - Vertical List Scroll Area
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 8) {
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
                                        HStack(spacing: 12) {
                                            ZStack {
                                                Circle()
                                                    .fill((isSelected ? Color.white : catColor).opacity(isSelected ? 0.25 : 0.14))
                                                    .frame(width: 34, height: 34)
                                                Image(systemName: cat.iconName)
                                                    .font(.system(size: 15, weight: .bold))
                                                    .foregroundStyle(isSelected ? Color.white : catColor)
                                            }

                                            Text(cat.localizedName(isArabic: isArabic))
                                                .font(.system(size: 15, weight: isSelected ? .bold : .semibold, design: .rounded))
                                                .foregroundStyle(isSelected ? Color.white : (isDark ? Color.white : Color(hex: 0x12263F)))
                                                .lineLimit(1)

                                            Spacer()

                                            if isSelected {
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 13, weight: .bold))
                                                    .foregroundStyle(Color.white)
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(isSelected ? catColor : (isDark ? Color.white.opacity(0.06) : Color(hex: 0xF1F5F9)))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .strokeBorder(isSelected ? Color.clear : (isDark ? Color.white.opacity(0.08) : Color(hex: 0xE2E8F0)), lineWidth: 0.8)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .id(cat.rawValue)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 4)
                        }
                        .defaultScrollAnchor(.top)
                        .scrollDismissesKeyboard(.interactively)
                        .onAppear {
                            if category != .other {
                                proxy.scrollTo(category.rawValue, anchor: .center)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Location Status Card
                    HStack(spacing: 10) {
                        if isResolving {
                            ProgressView()
                                .scaleEffect(0.85)
                            Text(isArabic ? "جارٍ تحديد الإحداثيات من الرابط..." : "Resolving coordinates from link...")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(Color(hex: 0x3C79F3))
                        } else if let coord = coordinate {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(hex: 0x0E9F75))

                            VStack(alignment: .leading, spacing: 2) {
                                if !addressText.isEmpty {
                                    Text(addressText)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundStyle(isDark ? Color.white : Color(hex: 0x12263F))
                                        .lineLimit(1)
                                }
                                Text(String(format: "%.5f, %.5f", coord.latitude, coord.longitude))
                                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                                    .foregroundStyle(isDark ? Color.white.opacity(0.65) : Color(hex: 0x64748B))
                            }
                        } else if resolveFailed {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 16))
                                .foregroundStyle(Color.orange)
                            Text(isArabic ? "تعذر استخراج الإحداثيات من الرابط" : "Could not find coordinates in link")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(Color.orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(isDark ? Color(hex: 0x182433).opacity(0.8) : Color(hex: 0xF8FAFC))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(isDark ? Color.white.opacity(0.08) : Color.black.opacity(0.06), lineWidth: 0.5)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                    // Save Action Button
                    Button {
                        guard let coord = coordinate else { return }
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
                        .frame(height: 52)
                        .background(
                            Capsule()
                                .fill(isSaved ? Color(hex: 0x0E9F75) : (coordinate == nil ? Color.gray.opacity(0.45) : Color(hex: 0x3C79F3)))
                        )
                        .shadow(color: isSaved ? Color(hex: 0x0E9F75).opacity(0.3) : Color(hex: 0x3C79F3).opacity(0.3), radius: 8, y: 3)
                    }
                    .buttonStyle(.plain)
                    .disabled(coordinate == nil || isSaved)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                        .fill(isDark ? Color(hex: 0x12263F) : Color.white)
                        .shadow(color: Color.black.opacity(isDark ? 0.6 : 0.25), radius: 25, y: -4)
                        .ignoresSafeArea(edges: .bottom)
                )
                .offset(y: max(0, dragOffset))
                .transition(.move(edge: .bottom))
                .gesture(
                    DragGesture()
                        .onChanged { val in
                            if val.translation.height > 0 {
                                dragOffset = val.translation.height
                            }
                        }
                        .onEnded { val in
                            if val.translation.height > 90 || val.velocity.height > 350 {
                                dismissSheet()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    dragOffset = 0
                                }
                            }
                        }
                )
            }
        }
        .background(Color.clear)
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                isVisible = true
            }
            resolveCoordinates()
        }
    }

    private func dismissSheet() {
        withAnimation(.easeIn(duration: 0.22)) {
            isVisible = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) {
            onCancel()
        }
    }

    private var isArabic: Bool {
        Locale.current.language.languageCode?.identifier == "ar"
    }

    private func resolveCoordinates() {
        if let direct = GeoUriParser.parse(rawSharedText) {
            let coord = CLLocationCoordinate2D(latitude: direct.latitude, longitude: direct.longitude)
            coordinate = coord
            if let label = direct.label ?? suggestedLabel {
                name = label
            }
            isResolving = false
            reverseGeocode(coord)
            return
        }

        Task {
            if let asyncParsed = await GeoUriParser.parseAsync(rawSharedText) {
                await MainActor.run {
                    let coord = CLLocationCoordinate2D(latitude: asyncParsed.latitude, longitude: asyncParsed.longitude)
                    self.coordinate = coord
                    if let label = asyncParsed.label ?? self.suggestedLabel {
                        self.name = label
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
                var parts: [String] = []
                if let street = p.thoroughfare { parts.append(street) }
                if let city = p.locality { parts.append(city) }
                DispatchQueue.main.async {
                    self.addressText = parts.joined(separator: ", ")
                    if self.name.isEmpty, let placeName = p.name {
                        self.name = placeName
                    }
                }
            }
        }
    }
}

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
