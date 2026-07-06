/// 锁定配置数据模型
class LockConfig {
  /// 锁定开始时间（小时，24小时制）
  final int lockStartHour;

  /// 锁定开始分钟
  final int lockStartMinute;

  /// 解锁时间（小时）
  final int unlockHour;

  /// 解锁分钟
  final int unlockMinute;

  /// 被屏蔽的 App 包名列表
  final List<String> blockedApps;

  /// 白名单 App 包名列表（锁定期间允许使用）
  final List<String> whitelistApps;

  /// 是否已使用推迟（每次锁定周期内只能推迟一次）
  bool delayUsed;

  /// 推迟时长（分钟）
  final int delayMinutes;

  LockConfig({
    this.lockStartHour = 23,
    this.lockStartMinute = 0,
    this.unlockHour = 7,
    this.unlockMinute = 0,
    this.blockedApps = const [
      'com.ss.android.ugc.aweme',    // 抖音
      'com.tencent.mm',              // 微信
    ],
    this.whitelistApps = const [
      'com.android.dialer',          // 电话
      'com.android.mms',             // 短信
      'com.android.phone',           // 电话
    ],
    this.delayUsed = false,
    this.delayMinutes = 15,
  });

  /// 是否当前处于锁定时间段
  bool isLockedTime(DateTime now) {
    int currentMinutes = now.hour * 60 + now.minute;
    int startMinutes = lockStartHour * 60 + lockStartMinute;
    int endMinutes = unlockHour * 60 + unlockMinute;

    if (startMinutes > endMinutes) {
      // 跨天锁定（如 23:00 - 07:00）
      return currentMinutes >= startMinutes || currentMinutes < endMinutes;
    } else {
      // 同天锁定
      return currentMinutes >= startMinutes && currentMinutes < endMinutes;
    }
  }

  /// 计算距离下一次锁定状态切换的时间
  Duration timeUntilNextChange(DateTime now) {
    int currentMinutes = now.hour * 60 + now.minute;
    int startMinutes = lockStartHour * 60 + lockStartMinute;
    int endMinutes = unlockHour * 60 + unlockMinute;

    if (isLockedTime(now)) {
      // 当前锁定中，计算距离解锁的时间
      int diff;
      if (endMinutes > currentMinutes) {
        diff = endMinutes - currentMinutes;
      } else {
        diff = (24 * 60 - currentMinutes) + endMinutes;
      }
      return Duration(hours: diff ~/ 60, minutes: diff % 60);
    } else {
      // 当前未锁定，计算距离锁定的时间
      int diff;
      if (startMinutes > currentMinutes) {
        diff = startMinutes - currentMinutes;
      } else {
        diff = (24 * 60 - currentMinutes) + startMinutes;
      }
      return Duration(hours: diff ~/ 60, minutes: diff % 60);
    }
  }

  /// 从 SharedPreferences 的 JSON 恢复配置
  factory LockConfig.fromJson(Map<String, dynamic> json) {
    return LockConfig(
      lockStartHour: json['lockStartHour'] ?? 23,
      lockStartMinute: json['lockStartMinute'] ?? 0,
      unlockHour: json['unlockHour'] ?? 7,
      unlockMinute: json['unlockMinute'] ?? 0,
      blockedApps: List<String>.from(json['blockedApps'] ?? []),
      whitelistApps: List<String>.from(json['whitelistApps'] ?? []),
      delayUsed: json['delayUsed'] ?? false,
      delayMinutes: json['delayMinutes'] ?? 15,
    );
  }

  /// 序列化为 JSON（用于 SharedPreferences 持久化）
  Map<String, dynamic> toJson() {
    return {
      'lockStartHour': lockStartHour,
      'lockStartMinute': lockStartMinute,
      'unlockHour': unlockHour,
      'unlockMinute': unlockMinute,
      'blockedApps': blockedApps,
      'whitelistApps': whitelistApps,
      'delayUsed': delayUsed,
      'delayMinutes': delayMinutes,
    };
  }

  /// 创建修改后的副本
  LockConfig copyWith({
    int? lockStartHour,
    int? lockStartMinute,
    int? unlockHour,
    int? unlockMinute,
    List<String>? blockedApps,
    List<String>? whitelistApps,
    bool? delayUsed,
    int? delayMinutes,
  }) {
    return LockConfig(
      lockStartHour: lockStartHour ?? this.lockStartHour,
      lockStartMinute: lockStartMinute ?? this.lockStartMinute,
      unlockHour: unlockHour ?? this.unlockHour,
      unlockMinute: unlockMinute ?? this.unlockMinute,
      blockedApps: blockedApps ?? this.blockedApps,
      whitelistApps: whitelistApps ?? this.whitelistApps,
      delayUsed: delayUsed ?? this.delayUsed,
      delayMinutes: delayMinutes ?? this.delayMinutes,
    );
  }
}

/// 屏蔽 App 信息（用于 UI 显示）
class BlockedAppInfo {
  final String packageName;
  final String displayName;

  const BlockedAppInfo({
    required this.packageName,
    required this.displayName,
  });

  static const List<BlockedAppInfo> presetApps = [
    BlockedAppInfo(packageName: 'com.ss.android.ugc.aweme', displayName: '抖音'),
    BlockedAppInfo(packageName: 'com.tencent.mm', displayName: '微信'),
    BlockedAppInfo(packageName: 'com.xiaohongshu', displayName: '小红书'),
    BlockedAppInfo(packageName: 'com.kuaishou', displayName: '快手'),
    BlockedAppInfo(packageName: 'com.taobao.taobao', displayName: '淘宝'),
    BlockedAppInfo(packageName: 'com.eg.android.AlipayGphone', displayName: '支付宝'),
  ];
}
