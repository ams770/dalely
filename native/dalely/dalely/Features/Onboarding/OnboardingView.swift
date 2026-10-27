import SwiftUI

struct OnboardingView: View {
    @Environment(AppEnvironment.self) private var env
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button(env.l10n.t("onboardingSkip")) {
                    env.completeOnboarding()
                }
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(env.palette.primaryDarker)
//                .buttonStyle(LiquidGlassButtonStyle())
//                .background()
//                .safeAreaPadding(AppDimens.space24)
            }
            .safeAreaPadding()
            .padding(.top, AppDimens.space24)
            
            

            TabView(selection: $page) {
                OnboardingPage(
                    imageName: "Onboarding2",
                    symbol: "map.fill",
                    title: env.l10n.t("onboarding2Title"),
                    bodyText: env.l10n.t("onboarding2Body")
                ).tag(0)
                OnboardingPage(
                    imageName: "Onboarding1",
                    symbol: "car.fill",
                    title: env.l10n.t("onboarding1Title"),
                    bodyText: env.l10n.t("onboarding1Body")
                ).tag(1)
                OnboardingPage(
                    imageName: "Onboarding3",
                    symbol: "lock.shield.fill",
                    title: env.l10n.t("onboarding3Title"),
                    bodyText: env.l10n.t("onboarding3Body")
                ).tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index == page ? env.palette.primary : env.palette.border)
                        .frame(width: index == page ? 22 : 8, height: 8)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: page)
                }
            }
            .padding(.bottom, 16)

            if page < 2 {
                PrimaryBottomButton(label: env.l10n.t("onboardingNext"), systemImage: nil) {
                    withAnimation { page += 1 }
                }.frame(maxWidth: 600)
            } else {
                VStack(spacing: 8) {
                    PrimaryBottomButton(label: env.l10n.t("onboardingAllowLocation"), systemImage: "location.fill") {
                        env.location.requestPermission()
                        env.completeOnboarding()
                    }
                }.frame(maxWidth: 600)
            }
                
        }
        .background(env.effectiveColorScheme == .dark ? env.palette.background : Color.white)
        .safeAreaPadding()
      
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct OnboardingPage: View {
    var imageName: String? = nil
    let symbol: String
    let title: String
    let bodyText: String
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        VStack(spacing: 24) {
            
            
            if let imageName {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                    .shadow(color: env.palette.primary.opacity(0.22), radius: 16, y: 6)
            } else {
                Image(systemName: symbol)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(env.palette.primary)
            }
            
            
            
            
            Text(title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(env.palette.textPrimary)
            Text(bodyText)
                .font(.system(size: 16, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundStyle(env.palette.textSecondary)
                .padding(.horizontal, 28)
        }
        .padding(.bottom, 24)
    }
}
