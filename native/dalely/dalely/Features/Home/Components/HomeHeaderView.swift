import SwiftUI

struct HomeHeaderView: View {
    @Environment(AppEnvironment.self) private var env

    var body: some View {
        HStack(spacing: AppDimens.space12) {
            CircleIconButton(systemName: "slider.horizontal.3", size: 42) {
                env.openSettings()
            }

            Text(env.l10n.t("appTitle"))
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(env.palette.textPrimary)

            Spacer()

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
                        .shadow(color: Color.black.opacity(0.12), radius: 5, y: 2)
                )
            }
            .buttonStyle(LiquidGlassButtonStyle())
            .accessibilityLabel(Text(env.l10n.t("addSpot")))
        }
        .padding(.horizontal, AppDimens.space16)
        .padding(.top, AppDimens.space12)
        .padding(.bottom, AppDimens.space8)
    }
}
