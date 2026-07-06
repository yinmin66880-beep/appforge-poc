package com.appforge.anti_stay_up_late

import android.app.admin.DevicePolicyManager
import android.app.AppOpsManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// MainActivity
/// Flutter 与 Android 原生交互的桥梁
/// 处理 Device Admin、UsageStats 等系统级权限
class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.appforge.anti_stay_up_late/permissions"

    private lateinit var devicePolicyManager: DevicePolicyManager
    private lateinit var adminComponent: ComponentName

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        devicePolicyManager = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
        adminComponent = ComponentName(this, LockDeviceAdminReceiver::class.java)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestDeviceAdmin" -> {
                    requestDeviceAdmin()
                    result.success(true)
                }
                "checkDeviceAdmin" -> {
                    result.success(checkDeviceAdmin())
                }
                "requestUsageStats" -> {
                    requestUsageStats()
                    result.success(true)
                }
                "checkUsageStats" -> {
                    result.success(checkUsageStats())
                }
                "lockScreen" -> {
                    lockScreen()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    /// 请求设备管理员权限
    private fun requestDeviceAdmin() {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
        intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "防熬夜助手需要此权限在设定时间锁定屏幕")
        startActivity(intent)
    }

    /// 检查设备管理员权限是否已授予
    private fun checkDeviceAdmin(): Boolean {
        return devicePolicyManager.isAdminActive(adminComponent)
    }

    /// 请求使用统计权限（跳转到系统设置页）
    private fun requestUsageStats() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    /// 检查使用统计权限
    private fun checkUsageStats(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                android.os.Process.myUid(),
                packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /// 锁定屏幕
    private fun lockScreen() {
        if (checkDeviceAdmin()) {
            devicePolicyManager.lockNow()
        }
    }
}
