import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/permission_service.dart';

/// 权限引导页
/// 首次启动时引导用户逐步授权所有必要权限
class PermissionGuidePage extends StatefulWidget {
  const PermissionGuidePage({super.key});

  @override
  State<PermissionGuidePage> createState() => _PermissionGuidePageState();
}

class _PermissionGuidePageState extends State<PermissionGuidePage> {
  final PermissionService _permissionService = PermissionService.instance;
  int _currentStep = 0;
  final Map<String, bool> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _checkAllStatus();
  }

  /// 检查所有权限的当前状态
  Future<void> _checkAllStatus() async {
    for (final perm in PermissionItem.requiredPermissions) {
      final granted = await _permissionService.isPermissionGranted(perm.key);
      if (mounted) {
        setState(() {
          _permissionStatus[perm.key] = granted;
        });
      }
    }
  }

  /// 请求当前步骤的权限
  Future<void> _requestCurrentPermission() async {
    final perm = PermissionItem.requiredPermissions[_currentStep];
    bool granted = false;

    switch (perm.key) {
      case 'deviceAdmin':
        granted = await _permissionService.requestDeviceAdminPermission();
        break;
      case 'usageStats':
        granted = await _permissionService.requestUsageStatsPermission();
        break;
      case 'systemAlertWindow':
        granted = await _permissionService.requestSystemAlertWindowPermission();
        break;
      case 'notifications':
        granted = await _permissionService.requestNotificationPermission();
        break;
    }

    setState(() {
      _permissionStatus[perm.key] = granted;
    });

    if (granted) {
      // 自动进入下一步
      _nextStep();
    } else {
      // 显示失败提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${perm.title}授权失败，请重试或手动在设置中开启'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    }
  }

  /// 下一步
  void _nextStep() {
    if (_currentStep < PermissionItem.requiredPermissions.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      // 所有权限处理完毕
      _completeGuide();
    }
  }

  /// 完成引导
  Future<void> _completeGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permission_guide_completed', true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  /// 跳过（允许用户跳过部分权限）
  void _skipStep() {
    _nextStep();
  }

  @override
  Widget build(BuildContext context) {
    final perm = PermissionItem.requiredPermissions[_currentStep];
    final isGranted = _permissionStatus[perm.key] ?? false;
    final isLastStep = _currentStep == PermissionItem.requiredPermissions.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('权限设置'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // 进度指示器
            LinearProgressIndicator(
              value: (_currentStep + 1) / PermissionItem.requiredPermissions.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF378ADD)),
            ),
            const SizedBox(height: 8),
            Text(
              '步骤 ${_currentStep + 1} / ${PermissionItem.requiredPermissions.length}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),

            const Spacer(),

            // 权限图标
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: perm.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(perm.icon, size: 48, color: perm.color),
            ),
            const SizedBox(height: 24),

            // 权限标题
            Text(
              perm.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // 权限描述
            Text(
              perm.description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey, height: 1.6),
            ),

            const Spacer(),

            // 已授权状态
            if (isGranted)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D9E75).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Color(0xFF1D9E75), size: 20),
                    SizedBox(width: 8),
                    Text('已授权', style: TextStyle(color: Color(0xFF1D9E75))),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // 操作按钮
            Row(
              children: [
                // 跳过按钮
                TextButton(
                  onPressed: _skipStep,
                  child: Text(
                    isLastStep ? '完成' : '跳过',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                const SizedBox(width: 12),
                // 授权按钮
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isGranted ? _nextStep : _requestCurrentPermission,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF378ADD),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isGranted ? '下一步' : '去授权',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
