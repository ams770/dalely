import SwiftUI

struct ContentView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.colorScheme) private var systemColorScheme
    @State private var showSplash: Bool = true

    var body: some View {
        @Bindable var env = env
        GeometryReader { rootGeometry in
            let isWide = rootGeometry.size.width >= 700
            ZStack(alignment: .bottom) {
                if !env.settings.hasCompletedOnboarding {
                    OnboardingView()
                        .transition(.opacity)
                } else if isWide {
                    HomeView()
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

                if showSplash {
                    SplashView(isPresented: $showSplash)
                        .transition(.opacity)
                        .zIndex(100)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                env.adaptLayout(toWide: isWide)
            }
            .onChange(of: isWide) { _, newIsWide in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    env.adaptLayout(toWide: newIsWide)
                }
            }
        }
        .onAppear {
            env.updateSystemColorScheme(systemColorScheme)
            env.reloadFromDisk()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            env.reloadFromDisk()
        }
        .onChange(of: systemColorScheme) { _, newScheme in
            env.updateSystemColorScheme(newScheme)
        }
    }
}
