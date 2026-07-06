import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'services/permission_service.dart';

/// App 入口
void main() async {
  // 确保 Flutter 绑定初始化（使用 plugin 前必须调用）
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化权限服务
  await PermissionService.instance.init();

  // 检查是否已完成权限引导
  final prefs = await SharedPreferences.getInstance();
  final bool permissionGuideCompleted =
      prefs.getBool('permission_guide_completed') ?? false;

  runApp(AppForgeApp(
    showPermissionGuide: !permissionGuideCompleted,
  ));
}
