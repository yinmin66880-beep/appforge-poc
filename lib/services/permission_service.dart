import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

/// 权限管理服务
/// 统一管理 App 所需的所有系统权限的请求和状态检查
class PermissionService {
  static final PermissionService instance = PermissionService._internal();

  PermissionService._internal();

  /// Method Channel 用于调用 Android 原生权限（Device Admin 等）
  static const platform = MethodChannel('com.appforge.anti_stay_up_late/permissions');

  /// 初始化权限服务
  Future<void> init() async {
    // 预检查当前权限状态，不做请求
    await _checkAllPermissions();
  }

  /// 检查所有权限状态
  Future<Map<String, bool>> _checkAllPermissions() async {
    return {
      'notifications': await Permission.notification.isGranted,
      'systemAlertWindow': await Permission.systemAlertWindow.isGranted,
      'usageStats': await _checkUsageStatsPermission(),
      'deviceAdmin': await _checkDeviceAdminPermission(),
    };
  }

  /// 获取所有权限的当前状态（供 UI 显示）
  Future<Map<String, PermissionStatus>> getAllPermissionStatus() async {
    return {
      'notifications': await Permission.notification.status,
      'systemAlertWindow': await Permission.systemAlertWindow.status,
    };
  }

  /// 请求通知权限
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  /// 请求悬浮窗权限
  Future<bool> requestSystemAlertWindowPermission() async {
    final status = await Permission.systemAlertWindow.request();
    return status.isGranted;
  }

  /// 请求使用统计权限（通过原生 Intent）
  Future<bool> requestUsageStatsPermission() async {
    try {
      final result = await platform.invokeMethod<bool>('requestUsageStats');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 请求设备管理员权限（通过原生 Intent）
  Future<bool> requestDeviceAdminPermission() async {
    try {
      final result = await platform.invokeMethod<bool>('requestDeviceAdmin');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 检查使用统计权限
  Future<bool> _checkUsageStatsPermission() async {
    try {
      final result = await platform.invokeMethod<bool>('checkUsageStats');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 检查设备管理员权限
  Future<bool> _checkDeviceAdminPermission() async {
    try {
      final result = await platform.invokeMethod<bool>('checkDeviceAdmin');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// 检查指定权限是否已授予
  Future<bool> isPermissionGranted(String permissionKey) async {
    final status = await _checkAllPermissions();
    return status[permissionKey] ?? false;
  }

  /// 检查所有必要权限是否已全部授予
  Future<bool> areAllPermissionsGranted() async {
    final status = await _checkAllPermissions();
    return status.values.every((granted) => granted == true);
  }
}

/// 权限项定义（用于权限引导页展示）
class PermissionItem {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const PermissionItem({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  static const List<PermissionItem> requiredPermissions = [
    PermissionItem(
      key: 'deviceAdmin',
      title: '设备管理员',
      description: '用于在设定时间锁定手机屏幕，防止熬夜使用。卸载时需先取消此权限。',
      icon: Icons.lock_outline,
      color: Color(0xFFE53935),
    ),
    PermissionItem(
      key: 'usageStats',
      title: '使用情况访问',
      description: '用于检测您是否尝试打开被屏蔽的 App。数据仅保存在本地，不上传。',
      icon: Icons.analytics_outlined,
      color: Color(0xFF1D9E75),
    ),
    PermissionItem(
      key: 'systemAlertWindow',
      title: '悬浮窗权限',
      description: '当您尝试打开被屏蔽 App 时，显示"该休息了"提示遮罩。',
      icon: Icons.layers_outlined,
      color: Color(0xFFBA7517),
    ),
    PermissionItem(
      key: 'notifications',
      title: '通知权限',
      description: '在通知栏显示当前锁定状态和倒计时。',
      icon: Icons.notifications_outlined,
      color: Color(0xFF378ADD),
    ),
  ];
}
