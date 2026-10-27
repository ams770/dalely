import SwiftUI

struct SearchSpotsView: View {
    var isEmbedded: Bool = false
    var initialQuery: String? = nil
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    @State private var query: String = ""
    @State private var debouncedQuery: String = ""
    @State private var selectedCategory: SpotCategory? = nil

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                AppSearchBar(
                    text: $query,
                    placeholder: env.l10n.t("searchPlaceHint"),
                    autoFocus: true,
                    debounceDuration: 0.35,
                    onDebouncedChange: { debounced in
                        debouncedQuery = debounced
                    }
                )
                .padding(.horizontal, AppDimens.space16)
                .padding(.top, AppDimens.space8)
                .padding(.bottom, AppDimens.space8)

                // Category Filter Row (Only categories of existing spots)
                if !availableCategories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(availableCategories) { cat in
                                let isSelected = selectedCategory == cat
                                Button {
                                    Haptics.selection()
                                    selectedCategory = isSelected ? nil : cat
                                } label: {
                                    HStack(spacing: 5) {
                                        Image(systemName: cat.systemImage)
                                        Text(cat.label(env.l10n))
                                    }
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .foregroundStyle(isSelected ? Color.white : env.palette.textPrimary)
                                    .liquidGlassPill(
                                        tint: isSelected ? env.palette.categoryColor(cat) : nil,
                                        isProminent: isSelected
                                    )
                                }
                                .buttonStyle(LiquidGlassButtonStyle())
                            }
                        }
                        .padding(.horizontal, AppDimens.space16)
                    }
                    .padding(.bottom, 12)
                    .scrollDismissesKeyboard(.immediately)
                }
            }
            .zIndex(1)

            // Results List
            if searchResults.isEmpty {
                VStack {
                    Spacer()
                    EmptyStateView(
                        title: env.l10n.t("noSearchResults"),
                        message: env.l10n.t("emptySpotsMessage")
                    )
                    Spacer()
                }
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: AppDimens.space12) {
                        ForEach(searchResults) { spot in
                            SpotCardView(
                                spot: spot,
                                isFavorite: env.settings.favoriteSpotId == spot.id,
                                onShowOnMap: {
                                    env.openMap(spotId: spot.id)
                                },
                                onOpenInMaps: {
                                    MapsLauncher.openDirections(latitude: spot.latitude, longitude: spot.longitude, label: spot.name)
                                },
                                onShare: {
                                    ShareService.shareSpot(spot, l10n: env.l10n)
                                },
                                onEdit: {
                                    env.openSaveSpot(lat: spot.latitude, lng: spot.longitude, name: spot.name, editing: spot)
                                },
                                onDelete: {
                                    env.deleteSpot(spot)
                                },
                                onToggleFavorite: {
                                    env.toggleFavorite(spot)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, AppDimens.space16)
                    .padding(.top, 4)
                    .padding(.bottom, 24)
                }
                .scrollDismissesKeyboard(.immediately)
                .transaction { tx in tx.animation = nil }
            }
        }
        .background(env.palette.background.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(env.l10n.t("search"))
        .onAppear {
            if let initialQuery {
                query = initialQuery
                debouncedQuery = initialQuery
            } else if !env.searchQuery.isEmpty {
                query = env.searchQuery
                debouncedQuery = env.searchQuery
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private var availableCategories: [SpotCategory] {
        let allExisting = env.allSpots.map(\.category)
        return SpotCategory.allCases.filter { allExisting.contains($0) }
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
}

