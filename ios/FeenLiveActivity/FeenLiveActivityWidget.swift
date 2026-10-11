import ActivityKit
import SwiftUI
import WidgetKit

private let indigo = Color(red: 0.31, green: 0.27, blue: 0.90) // #4F46E5
private let coral = Color(red: 1.0, green: 0.54, blue: 0.40)  // #FF8A65
private let cardDark = Color(red: 0.08, green: 0.08, blue: 0.23) // #14143A
private let ink = Color(red: 0.11, green: 0.11, blue: 0.23)    // #1B1B3A
private let arrivedGreen = Color(red: 0.05, green: 0.62, blue: 0.46) // #0E9F75

struct FeenLiveActivityWidget: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: FeenTrackingAttributes.self) { context in
      LockScreenCard(state: context.state)
        .widgetURL(URL(string: "feen://map?spot=car"))
        .activityBackgroundTint(cardDark.opacity(0.85))
        .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          HStack(spacing: 6) {
            Image(systemName: "mappin.circle.fill")
              .font(.title3)
              .foregroundColor(indigo)
            Text(context.state.appName)
              .font(.headline)
              .foregroundColor(.white)
          }
          .padding(.leading, 4)
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text(context.state.detailText)
            .font(.subheadline)
            .foregroundColor(.white.opacity(0.85))
            .padding(.trailing, 4)
        }
        DynamicIslandExpandedRegion(.bottom) {
          VStack(spacing: 10) {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
              Text(context.state.distanceText)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
              Text(context.state.isArrived ? context.state.detailText : "to your car")
                .font(.caption.weight(.semibold))
                .foregroundColor(context.state.isArrived ? arrivedGreen : .white.opacity(0.85))
              Spacer()
            }
            HStack(spacing: 8) {
              MapActionButton(label: context.state.onMapLabel, isCompact: true)
              FoundActionButton(label: context.state.foundLabel, isCompact: true)
            }
          }
          .padding(.horizontal, 4)
        }
      } compactLeading: {
        Image(systemName: "mappin")
          .font(.caption.bold())
          .foregroundColor(context.state.isArrived ? arrivedGreen : coral)
      } compactTrailing: {
        Text(context.state.distanceText)
          .font(.caption.bold())
          .foregroundColor(.white)
      } minimal: {
        Image(systemName: "mappin")
          .font(.caption.bold())
          .foregroundColor(context.state.isArrived ? arrivedGreen : coral)
      }
    }
  }
}

private struct LockScreenCard: View {
  let state: FeenTrackingAttributes.ContentState

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      // Header row
      HStack {
        HStack(spacing: 7) {
          Image(systemName: "mappin.circle.fill")
            .font(.system(size: 15, weight: .bold))
            .foregroundColor(.white)
            .padding(4)
            .background(indigo)
            .clipShape(Circle())
          Text(state.appName)
            .font(.subheadline.weight(.bold))
            .foregroundColor(.white)
        }
        Spacer()
        if !state.parkedText.isEmpty {
          Text(state.parkedText)
            .font(.footnote.weight(.medium))
            .foregroundColor(.white.opacity(0.8))
        }
      }

      // Large distance + detail
      HStack(alignment: .lastTextBaseline, spacing: 8) {
        Text(state.distanceText)
          .font(.system(size: 34, weight: .heavy, design: .rounded))
          .foregroundColor(.white)
        Text(state.detailText)
          .font(.footnote.weight(.semibold))
          .foregroundColor(state.isArrived ? arrivedGreen : .white.opacity(0.9))
      }
      .lineLimit(1)
      .minimumScaleFactor(0.7)

      // Action Buttons
      HStack(spacing: 10) {
        MapActionButton(label: state.onMapLabel, isCompact: false)
        FoundActionButton(label: state.foundLabel, isCompact: false)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(cardDark.opacity(0.62))
  }
}

private struct MapActionButton: View {
  let label: String
  let isCompact: Bool

  var body: some View {
    Link(destination: URL(string: "feen://map?spot=car")!) {
      HStack(spacing: 6) {
        Image(systemName: "map.fill")
          .font(.system(size: isCompact ? 12 : 13, weight: .bold))
        Text(label)
          .font(.system(size: isCompact ? 13 : 14, weight: .bold))
      }
      .foregroundColor(ink)
      .frame(maxWidth: .infinity, minHeight: isCompact ? 32 : 40)
      .background(Color.white)
      .clipShape(Capsule())
    }
  }
}

private struct FoundActionButton: View {
  let label: String
  let isCompact: Bool

  var body: some View {
    Link(destination: URL(string: "feen://found_car")!) {
      Text(label)
        .font(.system(size: isCompact ? 13 : 14, weight: .bold))
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, minHeight: isCompact ? 32 : 40)
        .background(Color.white.opacity(0.22))
        .clipShape(Capsule())
    }
  }
}
