import SwiftUI

struct SearchSpotsSheetView: View {
    var initialQuery: String? = nil
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var debouncedQuery: String = ""
    @State private var selectedCategory: SpotCategory? = nil
    @State private var visibleResultsLimit: Int = 20
    private let pageSize: Int = 20

    private var availableCategories: [SpotCategory] {
        let existing = Set(env.allSpots.map(\.category))
        let list = SpotCategory.selectable.filter { existing.contains($0) }
        return list.isEmpty ? SpotCategory.selectable : list
    }

    private var searchResults: [Spot] {
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

    private var paginatedResults: [Spot] {
        Array(searchResults.prefix(visibleResultsLimit))
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
                placeholder: env.l10n.t("searchSpotsPlaceholder"),
                autoFocus: true,
                debounceDuration: 0.25,
                onDebouncedChange: { debounced in
                    debouncedQuery = debounced
                    visibleResultsLimit = pageSize
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
                visibleResultsLimit = pageSize
            }
            .padding(.bottom, 10)

            Divider()
                .overlay(env.palette.border.opacity(0.6))

            // Search Results List
            if searchResults.isEmpty {
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
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: AppDimens.space12) {
                        ForEach(paginatedResults) { spot in
                            SpotCardView(
                                spot: spot,
                                onShowOnMap: {
                                    dismiss()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        env.openMap(spotId: spot.id)
                                    }
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
                            .onAppear {
                                if spot.id == paginatedResults.last?.id && visibleResultsLimit < searchResults.count {
                                    visibleResultsLimit += pageSize
                                }
                            }
                        }

                        if visibleResultsLimit < searchResults.count {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .onAppear {
                                    visibleResultsLimit += pageSize
                                }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.interactively)
            }
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
            } else if !env.searchQuery.isEmpty {
                query = env.searchQuery
                debouncedQuery = env.searchQuery
            }
        }
    }
}

typealias SearchSpotsView = SearchSpotsSheetView
