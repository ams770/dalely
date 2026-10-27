import SwiftUI

struct HomeHeaderView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        HStack(spacing: AppDimens.space12) {
            
            
            // Settings Glass Icon Button
            CircleIconButton(systemName: "slider.horizontal.3") {
                Haptics.tap()
                env.openSettings()
            }.accessibilityLabel(Text(env.l10n.t("settingsTooltip")))

            
            
  
            
    

            // App Brand Title
            Text(env.l10n.t("appTitle"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(env.palette.textPrimary)

            Spacer()

            // Elegant Add Spot Pill Button
            Button {
                Haptics.tap()
                env.openSaveSpot()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                    Text(env.l10n.t("addSpot"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .frame(height: 40)
                .background(
                    Capsule()
                        .fill(env.palette.primary)
                        .overlay(
                            Capsule()
                                .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
                        )
                        .shadow(color: env.palette.primary.opacity(0.30), radius: 6, y: 2)
                )
            }
            .buttonStyle(LiquidGlassButtonStyle())
            .accessibilityLabel(Text(env.l10n.t("addSpot")))
        }
        .padding(.horizontal, AppDimens.space16)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}
