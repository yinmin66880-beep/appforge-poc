import Flutter
import UIKit
import FamilyControls
import ManagedSettings
import ActivityKit

/// AppDelegate
/// Flutter 与 iOS 原生交互的桥梁
/// 处理 Screen Time API 授权、应用屏蔽、Live Activities 管理
@main
class AppDelegate: FlutterAppDelegate {

    /// Method Channel 名称
    private let channelName = "com.appforge.anti_stay_up_late/screentime"

    /// Live Activity 实例引用
    private var lockActivity: Activity<LockStatusAttributes>?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        let controller = window?.rootViewController as? FlutterViewController

        if let controller = controller {
            MethodChannel(
                binaryMessenger: controller.binaryMessenger,
                name: channelName
            ).setMethodCallHandler { [weak self] call, result in
                self?.handleMethodCall(call, result: result)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // MARK: - Method Channel 处理

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        // --- Screen Time API 授权 ---
        case "requestAuthorization":
            Task {
                let success = await ScreenTimeManager.shared.requestAuthorization()
                DispatchQueue.main.async { result(success) }
            }

        case "checkAuthorization":
            result(ScreenTimeManager.shared.isAuthorized())

        // --- 应用屏蔽控制 ---
        case "startShielding":
            ScreenTimeManager.shared.startShielding()
            result(true)

        case "stopShielding":
            ScreenTimeManager.shared.stopShielding()
            result(true)

        // --- 定时屏蔽计划 ---
        case "scheduleShielding":
            guard let args = call.arguments as? [String: Any],
                  let startHour = args["startHour"] as? Int,
                  let startMinute = args["startMinute"] as? Int,
                  let endHour = args["endHour"] as? Int,
                  let endMinute = args["endMinute"] as? Int else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing schedule parameters", details: nil))
                return
            }
            ScreenTimeManager.shared.scheduleShielding(
                startHour: startHour,
                startMinute: startMinute,
                endHour: endHour,
                endMinute: endMinute
            )
            result(true)

        case "stopSchedule":
            ScreenTimeManager.shared.stopScheduleMonitoring()
            result(true)

        // --- 应用选择器 ---
        case "showAppPicker":
            ScreenTimeManager.shared.presentAppPicker(from: window?.rootViewController) { selection in
                let count = selection.applicationTokens.count + selection.categoryTokens.count
                result(count)
            }

        case "getSelectedAppCount":
            let count = ScreenTimeManager.shared.getSelectedAppCount()
            result(count)

        // --- Live Activities ---
        case "startLiveActivity":
            guard let args = call.arguments as? [String: Any],
                  let unlockHour = args["unlockHour"] as? Int,
                  let unlockMinute = args["unlockMinute"] as? Int else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing unlock time", details: nil))
                return
            }
            startLiveActivity(unlockHour: unlockHour, unlockMinute: unlockMinute)
            result(true)

        case "stopLiveActivity":
            stopLiveActivity()
            result(true)

        // --- 推迟屏蔽 ---
        case "delayShielding":
            guard let args = call.arguments as? [String: Any],
                  let delayMinutes = args["delayMinutes"] as? Int else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing delay minutes", details: nil))
                return
            }
            ScreenTimeManager.shared.delayShielding(minutes: delayMinutes)
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Live Activities 管理

    private func startLiveActivity(unlockHour: Int, unlockMinute: Int) {
        stopLiveActivity()

        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("Live Activities 不可用")
            return
        }

        let attributes = LockStatusAttributes(lockStartHour: 23, lockStartMinute: 0)

        let now = Date()
        let calendar = Calendar.current
        var unlockComponents = DateComponents()
        unlockComponents.hour = unlockHour
        unlockComponents.minute = unlockMinute

        let unlockDate = calendar.nextDate(
            after: now,
            matching: unlockComponents,
            matchingPolicy: .nextTime
        ) ?? now

        let remainingMinutes = Int(unlockDate.timeIntervalSince(now) / 60)

        let state = LockStatusAttributes.ContentState(
            isLocked: true,
            unlockHour: unlockHour,
            unlockMinute: unlockMinute,
            remainingMinutes: max(0, remainingMinutes)
        )

        do {
            lockActivity = try Activity.request(
                attributes: attributes,
                content: ActivityContent(
                    state: state,
                    staleDate: unlockDate
                )
            )
            print("Live Activity 已启动")
        } catch {
            print("启动 Live Activity 失败: \(error)")
        }
    }

    private func stopLiveActivity() {
        Task {
            for activity in Activity<LockStatusAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            lockActivity = nil
        }
    }
}
