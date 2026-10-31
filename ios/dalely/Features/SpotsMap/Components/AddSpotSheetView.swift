import CoreLocation
import SwiftUI

/// In-app version of the share sheet. Same layout: pinned header, pinned name field,
/// one scrollable column of categories, pinned Save button, liquid glass controls.
/// The coordinate is already known (picked on the map), so there is no link resolving here.
struct AddSpotSheetView: View {
    let coordinate: CLLocationCoordinate2D
    let isEditing: Bool
    var onSave: (String, SpotCategory) -> Void
    var onCancel: () -> Void

    @Environment(AppEnvironment.self) private var env

    @State private var name: String
    @State private var category: SpotCategory
    @State private var isSaved: Bool = false

    init(
        coordinate: CLLocationCoordinate2D,
        initialName: String,
        initialCategory: SpotCategory?,
        isEditing: Bool,
        onSave: @escaping (String, SpotCategory) -> Void,
        onCancel: @escaping () -> Void
    ) {
        self.coordinate = coordinate
        self.isEditing = isEditing
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: initialName)
        _category = State(initialValue: initialCategory ?? .other)
    }

    private var categories: [SpotCategory] {
        [.other] + SpotCategory.selectable.filter { $0 != .other }
    }

    private var accent: Color { env.palette.primary }
    private let savedGreen = Color(hex: 0x0E9F75)

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 14) {
                    // Pinned top section
                    VStack(spacing: 14) {
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
                    .addSpotPinnedBottomBar {
                        saveButton
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.fill)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(env.l10n.t("cancel")) {
                        onCancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(env.l10n.t("save")) {
                        handleSave()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accent)
                    .disabled(isSaved)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task {
            await fillSuggestedNameIfNeeded()
        }
    }

    private var title: String {
        env.l10n.t(isEditing ? "editSpot" : "addSpot")
    }

    // MARK: - Spot Name
    private var spotNameSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(env.l10n.t("spotName"))
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(uiColor: .secondaryLabel))
                .padding(.horizontal, 2)

            HStack(spacing: 10) {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(accent)

                TextField(
                    env.l10n.t("spotNamePlaceholder"),
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

    // MARK: - Categories (single scrollable column)
    private var categoryHeader: some View {
        Text(env.l10n.t("category"))
            .font(.system(size: 13, weight: .semibold, design: .rounded))
            .foregroundStyle(Color(uiColor: .secondaryLabel))
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var categoryList: some View {
        AddSpotGlassContainer(spacing: 8) {
            VStack(spacing: 8) {
                ForEach(categories, id: \.self) { cat in
                    categoryRow(cat)
                }
            }
        }
    }

    private func categoryRow(_ cat: SpotCategory) -> some View {
        let isSelected = category == cat
        let catColor = env.palette.categoryColor(cat)

        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                category = cat
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.white.opacity(0.22) : catColor.opacity(0.16))
                        .frame(width: 34, height: 34)
                    Image(systemName: cat.systemImage)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(isSelected ? Color.white : catColor)
                }

                Text(cat.label(env.l10n))
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
            .addSpotGlassRow(isSelected: isSelected, tint: catColor)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Save Button (pinned at the bottom)
    private var saveButton: some View {
        Button {
            handleSave()
        } label: {
            HStack(spacing: 8) {
                if isSaved {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                    Text(env.l10n.t("savedSuccessfully"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                } else {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                    Text(env.l10n.t("saveSpotToDalely"))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .addSpotGlassProminentButton(tint: isSaved ? savedGreen : accent)
        .controlSize(.large)
        
        .buttonBorderShape(.capsule)
        .disabled(isSaved)
    }

    // MARK: - Actions
    private func handleSave() {
        guard !isSaved else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = trimmed.isEmpty ? category.label(env.l10n) : trimmed
        let finalCategory = category

        isSaved = true
        Haptics.success()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            onSave(finalName, finalCategory)
        }
    }

    // MARK: - Name suggestion
    /// Place name first (point of interest), then the address. Only runs when the name is empty.
    private func fillSuggestedNameIfNeeded() async {
        guard name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let suggestion = await Self.suggestedName(for: coordinate)
        guard let suggestion,
              name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        name = suggestion
    }

    private static func suggestedName(for coordinate: CLLocationCoordinate2D) async -> String? {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let placemarks = try? await CLGeocoder().reverseGeocodeLocation(location)
        guard let p = placemarks?.first else { return nil }

        if let aoi = p.areasOfInterest?.first, !aoi.isEmpty { return aoi }

        var parts: [String] = []
        if let street = p.thoroughfare, !street.isEmpty { parts.append(street) }
        if let sub = p.subLocality, !sub.isEmpty { parts.append(sub) }
        if let city = p.locality, !city.isEmpty { parts.append(city) }
        if !parts.isEmpty { return parts.joined(separator: ", ") }

        if let n = p.name, !n.isEmpty { return n }
        return nil
    }
}

// MARK: - Liquid Glass helpers (iOS 26+, with fallbacks). Names are prefixed to avoid clashes.

private struct AddSpotGlassContainer<Content: View>: View {
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

private struct AddSpotGlassRowBackground: ViewModifier {
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
    func addSpotGlassRow(isSelected: Bool, tint: Color) -> some View {
        modifier(AddSpotGlassRowBackground(isSelected: isSelected, tint: tint))
    }

    @ViewBuilder
    func addSpotGlassProminentButton(tint: Color) -> some View {
        if #available(iOS 26.0, *) {
            self.buttonStyle(.glassProminent).tint(tint)
        } else {
            self.buttonStyle(.borderedProminent).tint(tint)
        }
    }

    @ViewBuilder
    func addSpotPinnedBottomBar<Bar: View>(@ViewBuilder _ bar: () -> Bar) -> some View {
        if #available(iOS 26.0, *) {
            self.safeAreaBar(edge: .bottom) { bar() }
        } else {
            self.safeAreaInset(edge: .bottom) { bar().background(.bar) }
        }
    }
}
