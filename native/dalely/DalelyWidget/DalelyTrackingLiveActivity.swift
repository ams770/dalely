import ActivityKit
import SwiftUI
import WidgetKit

struct DalelyTrackingLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DalelyTrackingAttributes.self) { context in
            // Lock Screen / Notification Banner Live Activity Card
            LockScreenLiveActivityView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.85))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Leading
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image("CarIllustration")
                            .renderingMode(.original)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                        Text(context.attributes.carName)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                }

                // Expanded Trailing
                DynamicIslandExpandedRegion(.trailing) {
                    if !context.state.distanceText.isEmpty {
                        Text(context.state.distanceText)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color(hex: 0x3C79F3))
                            .padding(.trailing, 4)
                    }
                }

                // Expanded Center
                DynamicIslandExpandedRegion(.center) {
                    Text(context.state.detailText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }

                // Expanded Bottom
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        Link(destination: URL(string: "dalely://car")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(context.state.onMapLabel)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Capsule().fill(Color(hex: 0x3C79F3)))
                        }

                        Link(destination: URL(string: "dalely://found")!) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 12, weight: .semibold))
                                Text(context.state.foundLabel)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Capsule().fill(Color(hex: 0x0E9F75)))
                        }
                    }
                    .padding(.top, 4)
                    .padding(.horizontal, 4)
                }
            } compactLeading: {
                Image("CarIllustration")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
            } compactTrailing: {
                if !context.state.distanceText.isEmpty {
                    Text(context.state.distanceText)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(hex: 0x3C79F3))
                }
            } minimal: {
                Image("CarIllustration")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            }
        }
    }
}

// MARK: - Lock Screen / Banner Live Activity View
fileprivate struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<DalelyTrackingAttributes>

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image("CarIllustration")
                    .renderingMode(.original)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(context.attributes.carName)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text(context.state.parkedText)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    if !context.state.distanceText.isEmpty {
                        Text(context.state.distanceText)
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundStyle(Color(hex: 0x3C79F3))
                    }

                    Text(context.state.detailText)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 6)

                    Capsule()
                        .fill(Color(hex: 0x3C79F3))
                        .frame(width: max(12, geo.size.width * CGFloat(min(1.0, max(0.0, context.state.progress)))), height: 6)
                }
            }
            .frame(height: 6)

            // Buttons
            HStack(spacing: 12) {
                Link(destination: URL(string: "dalely://car")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "location.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(context.state.onMapLabel)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Capsule().fill(Color(hex: 0x3C79F3)))
                }

                Link(destination: URL(string: "dalely://found")!) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13, weight: .semibold))
                        Text(context.state.foundLabel)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(Capsule().fill(Color(hex: 0x0E9F75)))
                }
            }
        }
        .padding(16)
        .background(Color(hex: 0x12263F))
    }
}

fileprivate extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
