import ActivityKit
import Foundation

/// LockStatusAttributes
/// Live Activities 的属性定义
/// 此文件在 App 和 Widget Extension 之间共享
struct LockStatusAttributes: ActivityAttributes {

    public struct ContentState: Codable, Hashable {
        var isLocked: Bool
        var unlockHour: Int
        var unlockMinute: Int
        var remainingMinutes: Int
    }

    var lockStartHour: Int
    var lockStartMinute: Int
}
