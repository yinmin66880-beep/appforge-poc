# AppForge iOS PoC — Codemagic 编译验证指南

## 概述

本指南帮助你在 Codemagic 上验证 AppForge iOS 项目的编译可行性，无需本地 macOS 环境。

## 前提条件

1. **GitHub 账号**（用于连接 Codemagic 和托管代码）
2. **Codemagic 免费账号**（[注册链接](https://codemagic.io/signup)，无需信用卡）
3. **Apple Developer 账号**（可选，仅 Release workflow 需要）

> **注**：PoC 编译验证（Debug workflow）完全免费，不需要 Apple Developer 账号。Release workflow 需要 $99/年账号用于 TestFlight 分发。

---

## 步骤 1：代码推送到 GitHub

```bash
# 在项目根目录
cd D:/workspace/personal-app/poc-app/build_project

# 初始化 Git（如果还没做）
git init
git add .
git commit -m "AppForge iOS PoC — 初始化"

# 在 GitHub 创建仓库后
git remote add origin https://github.com/YOUR_USERNAME/appforge-ios-poc.git
git branch -M main
git push -u origin main
```

---

## 步骤 2：在 Codemagic 连接 GitHub

1. 登录 [Codemagic](https://codemagic.io)
2. 点击 **Applications** → **Add application**
3. 选择 **GitHub** → 授权 Codemagic 访问你的仓库
4. 选择 `appforge-ios-poc` 仓库
5. 项目类型选择 **Flutter App (via Workflow Editor)**
6. Codemagic 会自动检测到 `codemagic.yaml` 中的 workflow 配置

---

## 步骤 3：运行 iOS PoC 编译

1. 在应用页面，点击 **Start new build**
2. 选择 workflow: **iOS PoC Build Verification** (`ios-poc-build`)
3. 选择分支: `main`
4. 点击 **Start build**

编译过程约 5-10 分钟，包含：

| 步骤 | 内容 | 预计耗时 |
|------|------|---------|
| Step 1 | 安装 CocoaPods 依赖 | 1-2 min |
| Step 2 | `flutter pub get` | 30s |
| Step 3 | `flutter analyze` 静态分析 | 15s |
| Step 4 | `flutter build ios --debug` 编译 | 3-5 min |
| Step 5 | `flutter test` 单元测试 | 15s |

成功标志：Step 4 输出 `iOS BUILD SUCCESS` 并列出 `Runner.app` 构建产物。

---

## 验证目标

| 验证项 | 描述 | 成功标准 |
|--------|------|---------|
| Swift 代码编译 | 4 个文件：AppDelegate, ScreenTimeManager, LockStatusAttributes, LockStatusWidget | 零编译错误 |
| Flutter iOS 编译 | Dart + 插件编译为 iOS 二进制 | Runner.app 生成 |
| CocoaPods 依赖 | permission_handler 等 Flutter 插件 | pod install 成功 |
| flutter analyze | Dart 静态分析 | 零错误 |
| Extension target | 2 个 Widget + Monitor 扩展 | 源码文件编译通过 |

---

## 可能遇到的问题与解决

### 问题 1：CocoaPods 版本不兼容

```
[!] CocoaPods could not find compatible versions for pod "xxx"
```

**解决**：在 `ios-poc-build` workflow 中，把 `cocoapods: default` 改为具体版本：
```yaml
cocoapods: 1.15.2
```

### 问题 2：iOS Deployment Target 过低

Screen Time API 要求 iOS 16.0+。`Podfile` 已设置 `platform :ios, '16.0'`，如编译报 deployment target 错误，检查 Xcode 版本是否 ≥ 15.0。

### 问题 3：Extension 编译报错

Extension target (`LockStatusWidget`, `DeviceActivityMonitorExtension`) 需要在 Xcode 项目中手动添加为 target。当前 PoC 阶段，这些 Swift 文件已放在正确位置，但 Xcode project 文件未配置对应 target。

**影响**：Extension 文件不会编译，但不影响主 App 编译验证。

**后续**：Phase 2 开发时，在 macOS Xcode 中手动添加 Extension targets 并配置正确的 Bundle ID 和 Code Signing。

### 问题 4：--no-codesign 不被支持

如果 `flutter build ios --debug --no-codesign` 报错，降级为 simulator build：
```yaml
- name: Build iOS (Simulator)
  script: |
    flutter build ios --debug --simulator
```

---

## Release Workflow（注册 Apple Developer 后）

注册 $99/年 Apple Developer 账号后，启用 `ios-release-build` workflow：

1. 在 Codemagic 的 **App settings** → **Code signing** 中配置：
   - 选择 **Automatic code signing**
   - 上传 `.p8` API Key（从 App Store Connect 获取）
   - 输入 Issuer ID 和 Key ID

2. 在 App Store Connect 中注册：
   - Bundle ID: `com.appforge.anti-stay-up-late`
   - 启用的 Capabilities: Family Controls, Push Notifications, App Groups
   - 为 3 个 Extension 分别注册 Bundle ID

3. 运行 `ios-release-build` workflow，产物为可分发的 IPA 文件

---

## 项目文件索引

### iOS 原生（Swift）

| 文件 | 位置 | 用途 |
|------|------|------|
| AppDelegate.swift | `ios/Runner/` | Flutter MethodChannel 桥接 + Live Activity 管理 |
| ScreenTimeManager.swift | `ios/Runner/` | FamilyControls + ManagedSettings + DeviceActivity |
| LockStatusAttributes.swift | `ios/Runner/` | Live Activity 数据模型（App + Widget 共享） |
| LockStatusWidget.swift | `ios/LockStatusWidget/` | 锁屏 Live Activity Widget |
| DeviceActivityMonitorExtension.swift | `ios/DeviceActivityMonitorExtension/` | 后台定时屏蔽监控 |
| ScreenTimeManager.swift + 扩展 | `ios-src/` (原始副本) | 独立审查用入口文件 |

### Dart 桥接

| 文件 | 用途 |
|------|------|
| `lib/services/ios_lock_service.dart` | iOS 专用锁定服务（screentime MethodChannel） |
| `lib/services/ios_permission_service.dart` | iOS 专用权限服务（FamilyControls 统一授权） |
| `lib/services/lock_service.dart` | Android 锁定服务（保留，跨平台编译兼容） |
| `lib/services/permission_service.dart` | Android 权限服务（保留） |

### 配置文件

| 文件 | 用途 |
|------|------|
| `codemagic.yaml` | Codemagic CI/CD 配置（2 个 workflow） |
| `ios/Podfile` | CocoaPods 依赖 + 3 个 target（App + 2 个 Extension） |
| `ios/Runner/Info.plist` | 权限声明 + Screen Time API 配置 |
| `ios/Runner/Runner.entitlements` | Family Controls + App Groups 授权 |

---

*文档版本: v1.0 | 更新日期: 2026-07-06*
