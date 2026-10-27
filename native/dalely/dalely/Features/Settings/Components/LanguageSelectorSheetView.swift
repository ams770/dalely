import SwiftUI

struct LanguageSelectorSheetView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(env.palette.border)
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            HStack {
                Text(env.l10n.t("language"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(env.palette.textPrimary)

                Spacer()

                CircleIconButton(systemName: "xmark", size: 32) {
                    dismiss()
                }
            }
            .padding(.horizontal, 20)

            VStack(spacing: 8) {
                languageOption(title: env.l10n.t("languageSystem"), code: nil)
                languageOption(title: "English", code: "en")
                languageOption(title: "العربية", code: "ar")
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .presentationDetents([.height(280)])
        .presentationDragIndicator(.hidden)
    }

    private func languageOption(title: String, code: String?) -> some View {
        let isSelected = env.settings.localeCode == code

        return Button {
            Haptics.selection()
            env.setLocale(code)
            dismiss()
        } label: {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundStyle(isSelected ? env.palette.primary : env.palette.textPrimary)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(env.palette.primary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .appCardStyle(
                cornerRadius: 14,
                borderColor: isSelected ? env.palette.primary.opacity(0.45) : nil
            )
        }
        .buttonStyle(LiquidGlassButtonStyle())
    }
}
