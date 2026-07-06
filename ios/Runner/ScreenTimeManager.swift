import FamilyControls
import ManagedSettings
import DeviceActivity
import SwiftUI
import UIKit

/// ScreenTimeManager
/// 封装 Screen Time API 的核心功能：
/// - FamilyControls 授权管理
/// - ManagedSettings 应用屏蔽/解除
/// - DeviceActivity 定时计划
/// - FamilyActivityPicker 应用选择
class ScreenTimeManager: ObservableObject {

    /// 单例
    static let shared = ScreenTimeManager()

    /// ManagedSettings Store — 用于设置应用屏蔽
    private let store = ManagedSettingsStore()

    /// DeviceActivity Center — 用于定时监控
    private let deviceActivityCenter = DeviceActivityCenter()

    /// 当前授权状态
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined

    /// 用户选择的应用/类别（FamilyActivitySelection 包含不可序列化的 token）
    @Published var selection = FamilyActivitySelection()

    /// App Group 共享存储的 key（用于与 DeviceActivityMonitor 扩展共享选择）
    private let selectionKey = "AppForgeScreenTimeSelection"

    private init() {
        authorizationStatus = AuthorizationCenter.shared.authorizationStatus
        loadSelectionFromSharedStorage()
    }

    // MARK: - 授权管理

    /// 请求 Family Controls 授权
    /// - Returns: 是否授权成功
    func requestAuthorization() async -> Bool {
        do {
            try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
            await MainActor.run {
                self.authorizationStatus = AuthorizationCenter.shared.authorizationStatus
            }
            return authorizationStatus == .approved
        } catch {
            print("Family Controls 授权失败: \(error)")
            return false
        }
    }

    /// 检查是否已授权
    func isAuthorized() -> Bool {
        return AuthorizationCenter.shared.authorizationStatus == .approved
    }

    // MARK: - 应用屏蔽控制

    /// 开始屏蔽已选择的应用
    /// 使用 ManagedSettingsStore.shield 屏蔽选中的应用和类别
    func startShielding() {
        guard isAuthorized() else {
            print("未授权，无法屏蔽应用")
            return
        }

        // 屏蔽选中的具体应用
        store.shield.applications = selection.applicationTokens

        // 屏蔽所有应用类别（如社交媒体、游戏等）
        store.shield.applicationCategories = .all()

        print("应用屏蔽已启动: \(selection.applicationTokens.count) 个应用")
    }

    /// 停止所有应用屏蔽
    func stopShielding() {
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.clearAllSettings()
        print("应用屏蔽已停止")
    }

    // MARK: - 定时屏蔽计划

    /// 设置定时屏蔽计划
    func scheduleShielding(startHour: Int, startMinute: Int, endHour: Int, endMinute: Int) {
        guard isAuthorized() else {
            print("未授权，无法设置计划")
            return
        }

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: startHour, minute: startMinute),
            intervalEnd: DateComponents(hour: endHour, minute: endMinute),
            repeats: true
        )

        do {
            try deviceActivityCenter.startMonitoring(DeviceActivityName("shielding_schedule"), during: schedule)
            print("定时屏蔽计划已设置: \(startHour):\(startMinute) - \(endHour):\(endMinute)")
        } catch {
            print("设置定时计划失败: \(error)")
        }
    }

    /// 停止定时监控
    func stopScheduleMonitoring() {
        deviceActivityCenter.stopMonitoring()
        print("定时监控已停止")
    }

    // MARK: - 推迟屏蔽

    /// 推迟屏蔽（暂时解除，N 分钟后恢复）
    func delayShielding(minutes: Int) {
        stopShielding()
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(minutes * 60)) { [weak self] in
            self?.startShielding()
        }
        print("屏蔽已推迟 \(minutes) 分钟")
    }

    // MARK: - 应用选择器

    /// 弹出 FamilyActivityPicker
    func presentAppPicker(
        from viewController: UIViewController?,
        completion: @escaping (FamilyActivitySelection) -> Void
    ) {
        guard isAuthorized() else {
            print("未授权，无法打开应用选择器")
            completion(FamilyActivitySelection())
            return
        }

        let pickerView = AppPickerView(
            selection: Binding(
                get: { self.selection },
                set: { self.selection = $0 }
            )
        ) { [weak self] finalSelection in
            self?.saveSelectionToSharedStorage(finalSelection)
            completion(finalSelection)
        }

        let hostingController = UIHostingController(rootView: pickerView)
        viewController?.present(hostingController, animated: true)
    }

    /// 获取已选应用数量
    func getSelectedAppCount() -> Int {
        return selection.applicationTokens.count + selection.categoryTokens.count
    }

    // MARK: - 共享存储

    private func saveSelectionToSharedStorage(_ selection: FamilyActivitySelection) {
        if let defaults = UserDefaults(suiteName: "group.com.appforge.anti_stay_up_late") {
            defaults.set(true, forKey: selectionKey)
        }
    }

    private func loadSelectionFromSharedStorage() {
        // 实际产品中应反序列化 FamilyActivitySelection
    }
}

// MARK: - SwiftUI 应用选择器视图

struct AppPickerView: View {
    @Binding var selection: FamilyActivitySelection
    let onCommit: (FamilyActivitySelection) -> Void

    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
            .navigationTitle("选择要屏蔽的应用")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完成") {
                        onCommit(selection)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        onCommit(FamilyActivitySelection())
                    }
                }
            }
        }
    }
}
