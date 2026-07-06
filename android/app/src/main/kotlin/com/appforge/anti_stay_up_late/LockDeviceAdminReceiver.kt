package com.appforge.anti_stay_up_late

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/// Device Admin Receiver
/// 接收设备管理员权限变更的广播
/// 当用户授予或撤销设备管理员权限时触发
class LockDeviceAdminReceiver : DeviceAdminReceiver() {

    /// 设备管理员权限被授予时调用
    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.i("LockDeviceAdmin", "设备管理员权限已启用")
    }

    /// 设备管理员权限被撤销时调用
    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.i("LockDeviceAdmin", "设备管理员权限已禁用")
    }
}
