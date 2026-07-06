import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/lock_config.dart';

/// 锁定服务
/// 负责定时锁定/解锁逻辑、状态通知、推迟功能
class LockService {
  static final LockService instance = LockService._internal();

  LockService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  LockConfig _config = LockConfig();
  Timer? _checkTimer;
  bool _isLocked = false;
  bool _isRunning = false;

  /// 获取当前锁定状态
  bool get isLocked => _isLocked;

  /// 获取当前配置
  LockConfig get config => _config;

  /// 是否正在运行
  bool get isRunning => _isRunning;

  /// 初始化服务
  Future<void> init() async {
    // 加载保存的配置
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('lock_config');
    if (configJson != null) {
      // 简单解析（实际产品中用 jsonDecode）
      _config = LockConfig();
    }

    // 初始化通知
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _notificationsPlugin.initialize(settings);

    // 检查初始锁定状态
    _isLocked = _config.isLockedTime(DateTime.now());
  }

  /// 启动锁定监控
  void startMonitoring() {
    if (_isRunning) return;

    _isRunning = true;

    // 每分钟检查一次是否应该切换锁定状态
    _checkTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkLockStatus();
    });

    // 立即检查一次
    _checkLockStatus();
  }

  /// 停止锁定监控
  void stopMonitoring() {
    _checkTimer?.cancel();
    _checkTimer = null;
    _isRunning = false;
  }

  /// 检查并更新锁定状态
  void _checkLockStatus() {
    final now = DateTime.now();
    final shouldLock = _config.isLockedTime(now);

    if (shouldLock && !_isLocked) {
      // 从解锁 → 锁定
      _isLocked = true;
      _onLockStarted();
    } else if (!shouldLock && _isLocked) {
      // 从锁定 → 解锁
      _isLocked = false;
      _onLockEnded();
    }
  }

  /// 锁定开始时的处理
  void _onLockStarted() {
    _showNotification(
      title: '已进入锁定模式',
      body: '现在是休息时间，明早 ${_config.unlockHour}:${_config.unlockMinute.toString().padLeft(2, '0')} 解锁',
    );
  }

  /// 锁定结束时的处理
  void _onLockEnded() {
    // 重置推迟状态
    _config = _config.copyWith(delayUsed: false);
    _showNotification(
      title: '已解锁',
      body: '早上好！锁定已解除，注意今晚继续按时休息。',
    );
  }

  /// 推迟锁定（每次锁定周期最多推迟 1 次）
  bool delayLock() {
    if (_config.delayUsed) {
      return false; // 已经使用过推迟
    }

    // 标记已使用推迟
    _config = _config.copyWith(delayUsed: true);

    // 暂时解锁（推迟 15 分钟）
    _isLocked = false;

    // 15 分钟后重新锁定
    Timer(Duration(minutes: _config.delayMinutes), () {
      if (_config.isLockedTime(DateTime.now())) {
        _isLocked = true;
        _onLockStarted();
      }
    });

    _showNotification(
      title: '已推迟锁定',
      body: '推迟 ${_config.delayMinutes} 分钟，请尽快完成手头的事情。',
    );

    return true;
  }

  /// 更新锁定配置
  Future<void> updateConfig(LockConfig newConfig) async {
    _config = newConfig;

    // 持久化保存
    final prefs = await SharedPreferences.getInstance();
    // 实际产品中使用 jsonEncode(newConfig.toJson())
    await prefs.setString('lock_config', 'saved');

    // 重新检查锁定状态
    _isLocked = _config.isLockedTime(DateTime.now());
  }

  /// 显示状态通知
  void _showNotification({required String title, required String body}) {
    const androidDetails = AndroidNotificationDetails(
      'lock_status',
      '锁定状态通知',
      importance: Importance.high,
      ongoing: true,
    );
    const details = NotificationDetails(android: androidDetails);

    _notificationsPlugin.show(0, title, body, details);
  }

  /// 获取倒计时文本
  String getCountdownText() {
    final duration = _config.timeUntilNextChange(DateTime.now());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (_isLocked) {
      return '距离解锁还有 ${hours}h ${minutes}m';
    } else {
      return '距离锁定还有 ${hours}h ${minutes}m';
    }
  }

  /// 获取当前状态描述
  String getStatusText() {
    return _isLocked ? '已锁定' : '未锁定';
  }
}
