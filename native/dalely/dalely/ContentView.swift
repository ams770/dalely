import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.colorScheme) private var systemColorScheme

    var body: some View {
        @Bindable var env = env
        ZStack(alignment: .bottom) {
            if !env.settings.hasCompletedOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                NavigationStack(path: $env.path) {
                    HomeView()
                        .navigationDestination(for: AppRoute.self) { route in
                            switch route {
                            case .map(let spotId, let onlyShow):
                                SpotsMapView(
                                    isEmbedded: false,
                                    initialSpotId: spotId,
                                    initialOnlyShow: onlyShow
                                )

                            case .saveSpot:
                                SpotsMapView(
                                    isEmbedded: false
                                )

                            case .search(let query):
                                SearchSpotsView(
                                    isEmbedded: false,
                                    initialQuery: query
                                )

                            case .settings:
                                SettingsView(isEmbedded: false)

                            case .parkingHistory:
                                ParkingHistoryView(isEmbedded: false)
                            }
                        }
                }
            }

            // Global Snackbar Host
            SnackbarHost()
        }
        .onAppear {
            env.updateSystemColorScheme(systemColorScheme)
        }
        .onChange(of: systemColorScheme) { _, newScheme in
            env.updateSystemColorScheme(newScheme)
        }
        .alert(
            env.l10n.t("carArrivalTitle"),
            isPresented: Bindable(env).showArrival
        ) {
            Button(env.l10n.t("foundMyCar")) {
                env.foundCar()
            }
            Button(env.l10n.t("cancel"), role: .cancel) {
                env.showArrival = false
            }
        } message: {
            Text(env.l10n.t("carArrivalMessage"))
        }
    }
}
