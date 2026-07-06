import DeviceActivity
import ManagedSettings
import FamilyControls
import Foundation

/// DeviceActivityMonitorExtension
/// 设备活动监控扩展
/// 在系统后台运行，监听 DeviceActivitySchedule 的时间事件
class DeviceActivityMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore()
    private let appGroupSuite = "group.com.appforge.anti_stay_up_late"
    private let selectionKey = "AppForgeScreenTimeSelection"

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("DeviceActivity: 锁定时段开始 (activity: \(activity))")

        let selection = loadSelectionFromSharedStorage()

        if !selection.applicationTokens.isEmpty {
            store.shield.applications = selection.applicationTokens
            print("DeviceActivity: 已屏蔽 \(selection.applicationTokens.count) 个应用")
        }

        if !selection.categoryTokens.isEmpty {
            store.shield.applicationCategories = .all(except: Set(selection.categoryTokens))
        } else {
            store.shield.applicationCategories = .all()
        }
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("DeviceActivity: 锁定时段结束 (activity: \(activity))")

        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.clearAllSettings()
        print("DeviceActivity: 应用屏蔽已解除")
    }

    private func loadSelectionFromSharedStorage() -> FamilyActivitySelection {
        guard let defaults = UserDefaults(suiteName: appGroupSuite) else {
            return FamilyActivitySelection()
        }
        let hasSelection = defaults.bool(forKey: selectionKey)
        if hasSelection {
            // 实际产品中应反序列化 FamilyActivitySelection
        }
        return FamilyActivitySelection()
    }
}
