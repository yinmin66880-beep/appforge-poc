import 'package:flutter/material.dart';
import '../services/lock_service.dart';
import '../models/lock_config.dart';

/// 设置页
/// 调整锁定时间段、屏蔽 App 列表
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final LockService _lockService = LockService.instance;

  late int _lockStartHour;
  late int _unlockHour;
  late List<String> _blockedApps;

  @override
  void initState() {
    super.initState();
    final config = _lockService.config;
    _lockStartHour = config.lockStartHour;
    _unlockHour = config.unlockHour;
    _blockedApps = List.from(config.blockedApps);
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    final newConfig = _lockService.config.copyWith(
      lockStartHour: _lockStartHour,
      unlockHour: _unlockHour,
      blockedApps: _blockedApps,
    );

    await _lockService.updateConfig(newConfig);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('设置已保存'),
          backgroundColor: Color(0xFF1D9E75),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 锁定时间设置
          _buildSectionTitle('锁定时间'),
          const SizedBox(height: 12),
          _buildTimeSelector(
            label: '开始锁定',
            value: _lockStartHour,
            onChanged: (value) => setState(() => _lockStartHour = value),
          ),
          const SizedBox(height: 12),
          _buildTimeSelector(
            label: '解除锁定',
            value: _unlockHour,
            onChanged: (value) => setState(() => _unlockHour = value),
          ),

          const SizedBox(height: 32),

          // 屏蔽 App 设置
          _buildSectionTitle('屏蔽 App'),
          const SizedBox(height: 12),
          _buildBlockedAppsList(),

          const SizedBox(height: 32),

          // 保存按钮
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF378ADD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('保存设置', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建分区标题
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF378ADD),
      ),
    );
  }

  /// 构建时间选择器
  Widget _buildTimeSelector({
    required String label,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 16)),
            DropdownButton<int>(
              value: value,
              items: List.generate(24, (i) => i)
                  .map((h) => DropdownMenuItem(
                        value: h,
                        child: Text('${h.toString().padLeft(2, '0')}:00'),
                      ))
                  .toList(),
              onChanged: (newValue) {
                if (newValue != null) onChanged(newValue);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 构建屏蔽 App 列表（可勾选）
  Widget _buildBlockedAppsList() {
    return Card(
      child: Column(
        children: BlockedAppInfo.presetApps.map((app) {
          final isBlocked = _blockedApps.contains(app.packageName);
          return CheckboxListTile(
            title: Text(app.displayName),
            subtitle: Text(app.packageName, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            value: isBlocked,
            activeColor: const Color(0xFFE53935),
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _blockedApps.add(app.packageName);
                } else {
                  _blockedApps.remove(app.packageName);
                }
              });
            },
          );
        }).toList(),
      ),
    );
  }
}
