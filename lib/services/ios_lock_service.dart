import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lock_config.dart';

/// iOS 锁定服务
/// 对应 Android 版的 LockService，但使用 Screen Time API
///
/// 关键差异：
/// - Android: Device Admin lockNow() + SYSTEM_ALERT_WINDOW 遮罩
/// - iOS: ManagedSettings shieldApplications() + Live Activities 倒计时
class IosLockService {
  static final IosLockService instance = IosLockService._internal();
  IosLockService._internal();

  static const platform = MethodChannel('com.appforge.anti_stay_up_late/screentime');

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  LockConfig _config = LockConfig();
  Timer? _checkTimer;
  bool _isLocked = false;
  bool _isRunning = false;

  bool get isLocked => _isLocked;
  LockConfig get config => _config;
  bool get isRunning => _isRunning;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('lock_config');
    if (configJson != null) {
      _config = LockConfig();
    }

    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(iOS: iosSettings);
    await _notificationsPlugin.initialize(settings);

    _isLocked = _config.isLockedTime(DateTime.now());
    if (_isLocked) {
      await _startNativeShielding();
    }
  }

  void startMonitoring() {
    if (_isRunning) return;
    _isRunning = true;

    _setupNativeSchedule();

    _checkTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkLockStatus();
    });
    _checkLockStatus();
  }

  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isRunning = false;
  }

  void _checkLockStatus() {
    final now = DateTime.now();
    final shouldLock = _config.isLockedTime(now);

    if (shouldLock && !_isLocked) {
      _isLocked = true;
      _onLockStarted();
    } else if (!shouldLock && _isLocked) {
      _isLocked = false;
      _onLockEnded();
    }
  }

  void _onLockStarted() {
    _startNativeShielding();
    _startLiveActivity();
    _showNotification(
      title: '已进入锁定模式',
      body: '明早 ${_config.unlockHour}:${_config.unlockMinute.toString().padLeft(2, '0')} 解锁',
    );
  }

  void _onLockEnded() {
    _stopNativeShielding();
    _stopLiveActivity();
    _config = _config.copyWith(delayUsed: false);
    _showNotification(title: '已解锁', body: '早上好！注意今晚继续按时休息。');
  }

  Future<bool> delayLock() async {
    if (_config.delayUsed) return false;
    _config = _config.copyWith(delayUsed: true);

    _stopNativeShielding();
    _stopLiveActivity();
    _isLocked = false;

    Timer(Duration(minutes: _config.delayMinutes), () {
      if (_config.isLockedTime(DateTime.now())) {
        _isLocked = true;
        _onLockStarted();
      }
    });

    try {
      await platform.invokeMethod('delayShielding', {'delayMinutes': _config.delayMinutes});
    } on PlatformException { /* ignore */ }

    _showNotification(
      title: '已推迟锁定',
      body: '推迟 ${_config.delayMinutes} 分钟，请尽快完成手头的事情。',
    );
    return true;
  }

  Future<void> updateConfig(LockConfig newConfig) async {
    _config = newConfig;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lock_config', 'saved');
    _isLocked = _config.isLockedTime(DateTime.now());
    if (_isRunning) _setupNativeSchedule();
  }

  Future<void> _startNativeShielding() async {
    try { await platform.invokeMethod('startShielding'); } on PlatformException { /* ignore */ }
  }

  Future<void> _stopNativeShielding() async {
    try { await platform.invokeMethod('stopShielding'); } on PlatformException { /* ignore */ }
  }

  void _setupNativeSchedule() {
    try {
      platform.invokeMethod('scheduleShielding', {
        'startHour': _config.lockStartHour,
        'startMinute': _config.lockStartMinute,
        'endHour': _config.unlockHour,
        'endMinute': _config.unlockMinute,
      });
    } on PlatformException { /* ignore */ }
  }

  void _startLiveActivity() {
    try {
      platform.invokeMethod('startLiveActivity', {
        'unlockHour': _config.unlockHour,
        'unlockMinute': _config.unlockMinute,
      });
    } on PlatformException { /* ignore */ }
  }

  void _stopLiveActivity() {
    try { platform.invokeMethod('stopLiveActivity'); } on PlatformException { /* ignore */ }
  }

  void _showNotification({required String title, required String body}) {
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true, presentBadge: true, presentSound: true,
    );
    const details = NotificationDetails(iOS: iosDetails);
    _notificationsPlugin.show(0, title, body, details);
  }

  String getCountdownText() {
    final duration = _config.timeUntilNextChange(DateTime.now());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return _isLocked ? '距离解锁还有 ${hours}h ${minutes}m' : '距离锁定还有 ${hours}h ${minutes}m';
  }

  String getStatusText() => _isLocked ? '已锁定' : '未锁定';
}
