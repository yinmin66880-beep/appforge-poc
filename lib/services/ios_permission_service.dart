import 'package:flutter/services.dart';

/// iOS 权限管理服务
/// 对应 Android 版的 PermissionService，但使用 Screen Time API
///
/// 关键差异：
/// - Android: Device Admin + UsageStats + SYSTEM_ALERT_WINDOW（逐项授权）
/// - iOS: FamilyControls 统一授权（一次授权覆盖所有 Screen Time 功能）
class IosPermissionService {
  static final IosPermissionService instance = IosPermissionService._internal();
  IosPermissionService._internal();

  static const platform = MethodChannel('com.appforge.anti_stay_up_late/screentime');

  Future<void> init() async {
    await checkAllPermissions();
  }

  Future<Map<String, bool>> checkAllPermissions() async {
    return {
      'familyControls': await checkAuthorization(),
      'notifications': await _checkNotificationPermission(),
    };
  }

  Future<bool> requestAuthorization() async {
    try {
      final result = await platform.invokeMethod<bool>('requestAuthorization');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> checkAuthorization() async {
    try {
      final result = await platform.invokeMethod<bool>('checkAuthorization');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> _checkNotificationPermission() async => true;

  Future<int> showAppPicker() async {
    try {
      final count = await platform.invokeMethod<int>('showAppPicker');
      return count ?? 0;
    } on PlatformException {
      return 0;
    }
  }

  Future<int> getSelectedAppCount() async {
    try {
      final count = await platform.invokeMethod<int>('getSelectedAppCount');
      return count ?? 0;
    } on PlatformException {
      return 0;
    }
  }

  Future<bool> areAllPermissionsGranted() async {
    final status = await checkAllPermissions();
    return status.values.every((granted) => granted == true);
  }
}
