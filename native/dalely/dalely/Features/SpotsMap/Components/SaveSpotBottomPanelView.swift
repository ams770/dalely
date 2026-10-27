import CoreLocation
import SwiftUI

struct SaveSpotBottomPanelView: View {
    @Binding var name: String
    @Binding var category: SpotCategory
    let coordinate: CLLocationCoordinate2D
    let isEditing: Bool
    var onSave: () -> Void
    var onClose: () -> Void
    @Environment(AppEnvironment.self) private var env
    @State private var addressText: String = ""

    var body: some View {
        VStack(spacing: 12) {
            // Drag handle
            Capsule()
                .fill(env.palette.border)
                .frame(width: 36, height: 4)
                .padding(.top, 8)

            // Header
            HStack {
                Text(isEditing ? env.l10n.t("renameSpotTitle") : env.l10n.t("saveThisSpot"))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(env.palette.textPrimary)

                Spacer()

                CircleIconButton(systemName: "xmark", size: 32) {
                    onClose()
                }
            }
            .padding(.horizontal, 20)

            // Spot Name TextField Container with Liquid Glass
            HStack(spacing: 10) {
                Image(systemName: "pencil")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(env.palette.primary)

                TextField(env.l10n.t("nameHint"), text: $name)
                    .font(.system(size: 16, design: .rounded))

                if !name.isEmpty {
                    Button {
                        name = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(env.palette.textTertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(env.effectiveColorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: 0xF1F5F9))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(env.effectiveColorScheme == .dark ? Color.white.opacity(0.10) : Color(hex: 0xE2E8F0), lineWidth: 0.5)
                    )
            )
            .padding(.horizontal, 20)

            // Category Chips Selector
            VStack(alignment: .leading, spacing: 6) {
                CategoryChips(selected: category, includeCar: false) { cat in
                    category = cat
                }
            }

            // Location Coordinates / Reverse Geocoded Subtitle
            HStack(spacing: 6) {
                Image(systemName: "mappin.and.ellipse")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(env.palette.primary)
                Text(addressText.isEmpty ? String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude) : addressText)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(env.palette.textSecondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 20)
            .padding(.top, 2)

            // Save Button
            PrimaryBottomButton(label: isEditing ? env.l10n.t("save") : env.l10n.t("saveHere"), systemImage: "checkmark") {
                onSave()
            }
            .padding(.top, 4)
        }
        .padding(.bottom, 12)
        .appCardStyle(cornerRadius: AppDimens.radiusLarge)
        .onAppear {
            reverseGeocode()
        }
        .onChange(of: coordinate.latitude) { _, _ in
            reverseGeocode()
        }
    }

    private func reverseGeocode() {
        let loc = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        CLGeocoder().reverseGeocodeLocation(loc) { placemarks, _ in
            if let p = placemarks?.first {
                var parts: [String] = []
                if let name = p.name { parts.append(name) }
                if let street = p.thoroughfare, street != p.name { parts.append(street) }
                if let city = p.locality { parts.append(city) }
                DispatchQueue.main.async {
                    self.addressText = parts.joined(separator: ", ")
                }
            }
        }
    }
}
