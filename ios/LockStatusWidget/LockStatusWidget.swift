import ActivityKit
import WidgetKit
import SwiftUI

/// LockStatusWidget
/// 锁屏 Live Activity 小组件
/// 在锁屏和灵动岛展示当前锁定状态和倒计时
struct LockStatusWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LockStatusAttributes.self) { context in
            LockScreenLockView(state: context.state, attributes: context.attributes)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 4) {
                        Image(systemName: context.state.isLocked ? "lock.fill" : "lock.open.fill")
                            .foregroundColor(context.state.isLocked ? .red : .green)
                        Text(context.state.isLocked ? "休息时间" : "已解锁")
                            .font(.subheadline)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("解锁时间")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(context.state.unlockHour):\(String(format: "%02d", context.state.unlockMinute))")
                            .font(.headline)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Image(systemName: "moon.zzz.fill")
                            .foregroundColor(.indigo)
                        Text("距离解锁还有 \(context.state.remainingMinutes) 分钟")
                            .font(.subheadline)
                    }
                    .padding(.top, 4)
                }
            } compactLeading: {
                Image(systemName: context.state.isLocked ? "lock.fill" : "lock.open.fill")
                    .foregroundColor(context.state.isLocked ? .red : .green)
                    .font(.caption)
            } compactTrailing: {
                Text("\(context.state.remainingMinutes)m")
                    .font(.caption2)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "lock.fill")
                    .foregroundColor(.red)
                    .font(.caption2)
            }
        }
    }
}

struct LockScreenLockView: View {
    let state: LockStatusAttributes.ContentState
    let attributes: LockStatusAttributes

    var body: some View {
        HStack(spacing: 16) {
            VStack {
                Image(systemName: state.isLocked ? "lock.fill" : "lock.open.fill")
                    .font(.largeTitle)
                    .foregroundColor(state.isLocked ? .red : .green)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(state.isLocked ? "休息时间" : "已解锁")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("解锁时间 \(state.unlockHour):\(String(format: "%02d", state.unlockMinute))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("剩余 \(state.remainingMinutes) 分钟")
                    .font(.caption)
                    .foregroundColor(state.isLocked ? .red : .secondary)
                    .monospacedDigit()
            }
            Spacer()
            Image(systemName: "moon.stars.fill")
                .font(.title2)
                .foregroundColor(.indigo)
                .opacity(0.6)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
