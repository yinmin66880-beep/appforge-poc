import 'dart:async';
import 'package:flutter/material.dart';
import '../services/lock_service.dart';

/// 状态卡片组件
/// 显示当前锁定状态和倒计时
class StatusCard extends StatefulWidget {
  const StatusCard({super.key});

  @override
  State<StatusCard> createState() => _StatusCardState();
}

class _StatusCardState extends State<StatusCard> {
  final LockService _lockService = LockService.instance;
  late Timer _updateTimer;

  @override
  void initState() {
    super.initState();
    // 每秒更新倒计时显示
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _updateTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = _lockService.isLocked;
    final countdown = _lockService.getCountdownText();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLocked
              ? [const Color(0xFFE53935), const Color(0xFFFF7043)]
              : [const Color(0xFF378ADD), const Color(0xFF4FC3F7)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isLocked ? Colors.red : Colors.blue).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // 状态图标
          Icon(
            isLocked ? Icons.nightlight_round : Icons.wb_sunny,
            size: 64,
            color: Colors.white,
          ),
          const SizedBox(height: 16),

          // 状态文字
          Text(
            isLocked ? '已锁定' : '未锁定',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),

          // 倒计时
          Text(
            countdown,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
