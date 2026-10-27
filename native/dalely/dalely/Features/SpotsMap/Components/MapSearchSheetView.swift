import CoreLocation
import MapKit
import SwiftUI

struct MapSearchSheetView: View {
    var initialQuery: String? = nil
    var searchService: PlaceSearchService? = nil
    var onSelectSpot: (Spot) -> Void
    var onSelectCoordinate: (CLLocationCoordinate2D, String) -> Void

    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var debouncedQuery: String = ""
    @State private var selectedCategory: SpotCategory? = nil
    @State private var fallbackSearchService = PlaceSearchService()

    private var activeSearchService: PlaceSearchService {
        searchService ?? fallbackSearchService
    }

    private var availableCategories: [SpotCategory] {
        let existing = Set(env.allSpots.map(\.category))
        let list = SpotCategory.selectable.filter { existing.contains($0) }
        return list.isEmpty ? SpotCategory.selectable : list
    }

    private var matchingSpots: [Spot] {
        var list = env.allSpots
        if let selectedCategory {
            list = list.filter { $0.category == selectedCategory }
        }
        let trimmed = debouncedQuery.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return list }
        let normQuery = SearchNormalizer.normalize(trimmed)
        return list.filter { spot in
            SearchNormalizer.normalize(spot.name).contains(normQuery)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Drag handle matching native sheet styling
            Capsule()
                .fill(env.palette.border)
                .frame(width: 36, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 6)

            // Header Row
            HStack(spacing: 12) {
                Text(env.l10n.t("search"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(env.palette.textPrimary)

                Spacer()

                CircleIconButton(systemName: "xmark", size: 30) {
                    dismiss()
                }
                .accessibilityLabel(env.l10n.t("close"))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 4)

            // Auto-focus Search Input
            AppSearchBar(
                text: $query,
                placeholder: env.l10n.t("searchPlaceHint"),
                autoFocus: true,
                debounceDuration: 0.25,
                onDebouncedChange: { debounced in
                    debouncedQuery = debounced
                    activeSearchService.query = debounced
                }
            )
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 8)

            // Category Selection Chips
            CategoryChips(
                selected: selectedCategory,
                includeCar: false,
                available: availableCategories
            ) { cat in
                selectedCategory = cat
            }
            .padding(.bottom, 10)

            Divider()
                .overlay(env.palette.border.opacity(0.6))

            // Results ScrollView
            ScrollView(showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 14) {
                    // 1. Saved Spots Section
                    if !matchingSpots.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(env.l10n.t("savedSpots"))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(env.palette.textSecondary)
                                .padding(.horizontal, 4)

                            ForEach(matchingSpots) { spot in
                                SpotCardView(
                                    spot: spot,
                                    onShowOnMap: {
                                        dismiss()
                                        onSelectSpot(spot)
                                    },
                                    onOpenInMaps: {
                                        MapsLauncher.openDirections(latitude: spot.latitude, longitude: spot.longitude, label: spot.name)
                                    },
                                    onShare: {
                                        ShareService.shareSpot(spot, l10n: env.l10n)
                                    },
                                    onEdit: {
                                        dismiss()
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                            env.openSaveSpot(lat: spot.latitude, lng: spot.longitude, name: spot.name, editing: spot)
                                        }
                                    },
                                    onDelete: {
                                        env.deleteSpot(spot)
                                    }
                                )
                            }
                        }
                    }

                    // 2. Places & Addresses from Map Search
                    if !activeSearchService.results.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(env.l10n.t("placesSection"))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(env.palette.textSecondary)
                                .padding(.horizontal, 4)

                            ForEach(Array(activeSearchService.results.enumerated()), id: \.offset) { _, result in
                                Button {
                                    Haptics.tap()
                                    Task {
                                        if let coord = await activeSearchService.resolveCoordinate(for: result) {
                                            await MainActor.run {
                                                dismiss()
                                                onSelectCoordinate(coord, result.title)
                                            }
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundStyle(env.palette.primary)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(result.title)
                                                .font(.system(size: 15, weight: .bold, design: .rounded))
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
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .fill(env.palette.surfaceSecondary)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(env.palette.border.opacity(0.6), lineWidth: 0.75)
                                    )
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // 3. Empty State (when neither saved spots nor places found)
                    if matchingSpots.isEmpty && activeSearchService.results.isEmpty {
                        VStack(spacing: 12) {
                            Spacer(minLength: 30)
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 34, weight: .light))
                                .foregroundStyle(env.palette.textTertiary)
                            Text(env.l10n.t("noSearchResults"))
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundStyle(env.palette.textSecondary)
                            Spacer(minLength: 30)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .environment(\.layoutDirection, env.layoutDirection)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
        .presentationBackground(env.palette.surface)
        .presentationBackgroundInteraction(.enabled(upThrough: .large))
        .onAppear {
            if let initialQuery, !initialQuery.isEmpty {
                query = initialQuery
                debouncedQuery = initialQuery
                activeSearchService.query = initialQuery
            }
        }
    }
}
