import SwiftUI

struct ExportSpotsSheetView: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            // Drag handle
            Capsule()
                .fill(env.palette.border)
                .frame(width: 36, height: 4)
                .padding(.top, 10)

            // Header Row
            HStack(spacing: 12) {
                Image(systemName: "square.and.arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(env.palette.primary)

                Text(env.l10n.t("exportSpotsTitle"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(env.palette.textPrimary)

                Spacer()

                CircleIconButton(systemName: "xmark", size: 32) {
                    dismiss()
                }
            }
            .padding(.horizontal, 20)

            // Option 1: Export as Excel (CSV)
            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    ShareService.shareCSV(env.allSpots, l10n: env.l10n)
                }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.green.opacity(0.15))
                        Image(systemName: "tablecells.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.green)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(env.l10n.t("exportAsExcel"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(env.palette.textPrimary)
                        Text(env.l10n.t("exportAsExcelSubtitle"))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(env.palette.textSecondary)
                    }

                    Spacer()

                    Image(systemName: env.isRTL ? "chevron.left" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(env.palette.textTertiary)
                }
                .padding(16)
                .appCardStyle(cornerRadius: 16)
            }
            .buttonStyle(LiquidGlassButtonStyle())
            .padding(.horizontal, 20)

            // Option 2: Export as Text
            Button {
                dismiss()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    ShareService.shareAll(env.allSpots, l10n: env.l10n)
                }
            } label: {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(env.palette.primary.opacity(0.15))
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(env.palette.primary)
                    }
                    .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(env.l10n.t("exportAsText"))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(env.palette.textPrimary)
                        Text(env.l10n.t("exportAsTextSubtitle"))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(env.palette.textSecondary)
                    }

                    Spacer()

                    Image(systemName: env.isRTL ? "chevron.left" : "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(env.palette.textTertiary)
                }
                .padding(16)
                .appCardStyle(cornerRadius: 16)
            }
            .buttonStyle(LiquidGlassButtonStyle())
            .padding(.horizontal, 20)

            Spacer()
        }
        .environment(\.layoutDirection, env.layoutDirection)
        .presentationDetents([.height(290)])
        .presentationDragIndicator(.hidden)
    }
}
