package com.appforge.anti_stay_up_late

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/// 开机自启动 Receiver
/// 手机重启后自动启动锁定监控服务
class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED) {
            Log.i("BootReceiver", "开机启动：准备恢复锁定服务")
            // 实际产品中这里会启动 Foreground Service 恢复锁定监控
            // PoC 阶段仅记录日志
        }
    }
}
