import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/settings_page.dart';
import 'pages/permission_guide_page.dart';

/// AppForge App 根组件
class AppForgeApp extends StatelessWidget {
  final bool showPermissionGuide;

  const AppForgeApp({
    super.key,
    required this.showPermissionGuide,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '防熬夜助手',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF378ADD),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF378ADD),
          foregroundColor: Colors.white,
        ),
      ),
      // 首次启动显示权限引导页，否则显示主页
      home: showPermissionGuide
          ? const PermissionGuidePage()
          : const HomePage(),
      routes: {
        '/home': (context) => const HomePage(),
        '/settings': (context) => const SettingsPage(),
        '/permission_guide': (context) => const PermissionGuidePage(),
      },
    );
  }
}
