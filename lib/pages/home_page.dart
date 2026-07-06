import 'package:flutter/material.dart';
import '../widgets/status_card.dart';
import '../services/lock_service.dart';
import '../models/lock_config.dart';

/// 首页
/// 显示锁定状态、倒计时、推迟按钮
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final LockService _lockService = LockService.instance;

  @override
  void initState() {
    super.initState();
    _lockService.init().then((_) {
      _lockService.startMonitoring();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _lockService.stopMonitoring();
    super.dispose();
  }

  /// 点击推迟按钮
  void _onDelayPressed() {
    final success = _lockService.delayLock();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success
            ? '已推迟 ${_lockService.config.delayMinutes} 分钟'
            : '本次锁定已使用过推迟，无法再次推迟'),
        backgroundColor: success ? const Color(0xFF1D9E75) : const Color(0xFFE53935),
      ),
    );

    if (success) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final config = _lockService.config;
    final isLocked = _lockService.isLocked;
    final delayUsed = config.delayUsed;

    return Scaffold(
      appBar: AppBar(
        title: const Text('防熬夜助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // 状态卡片（倒计时）
            const StatusCard(),

            const SizedBox(height: 32),

            // 锁定时间段显示
            _buildTimeRangeCard(config),

            const SizedBox(height: 16),

            // 屏蔽 App 列表预览
            _buildBlockedAppsPreview(config),

            const Spacer(),

            // 推迟按钮（仅在锁定时显示）
            if (isLocked)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: delayUsed ? null : _onDelayPressed,
                  icon: Icon(
                    delayUsed ? Icons.lock_clock : Icons.snooze,
                    size: 24,
                  ),
                  label: Text(
                    delayUsed ? '已推迟过，无法再次推迟' : '推迟 ${config.delayMinutes} 分钟',
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA7517),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 构建锁定时间段卡片
  Widget _buildTimeRangeCard(LockConfig config) {
    final start = '${config.lockStartHour.toString().padLeft(2, '0')}:${config.lockStartMinute.toString().padLeft(2, '0')}';
    final end = '${config.unlockHour.toString().padLeft(2, '0')}:${config.unlockMinute.toString().padLeft(2, '0')}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text('锁定时间', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text(start, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const Icon(Icons.arrow_forward, color: Colors.grey),
            Column(
              children: [
                const Text('解锁时间', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text(end, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建屏蔽 App 预览
  Widget _buildBlockedAppsPreview(LockConfig config) {
    // 从预设列表中找到对应的显示名称
    final displayNames = <String>[];
    for (final packageName in config.blockedApps) {
      final match = BlockedAppInfo.presetApps.where((a) => a.packageName == packageName);
      displayNames.add(match.isNotEmpty ? match.first.displayName : packageName);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.block, size: 20, color: Color(0xFFE53935)),
                const SizedBox(width: 8),
                Text(
                  '屏蔽 App (${config.blockedApps.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: displayNames.map((name) {
                return Chip(
                  label: Text(name),
                  backgroundColor: Colors.red.shade50,
                  side: BorderSide.none,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
