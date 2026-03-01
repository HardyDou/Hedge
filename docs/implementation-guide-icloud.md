# iCloud 同步实施指南

**版本**: 1.0
**日期**: 2026-03-01
**优先级**: P1 (高)

---

## 1. 概述

本文档提供 NotePassword 实现 iCloud Documents 同步的详细技术实施步骤。

### 1.1 目标

- ✅ iPhone/iPad/macOS 设备间自动同步 vault.db 文件
- ✅ 实时感知远程文件变化
- ✅ 优化电池续航（替换 Timer 轮询）
- ✅ 提供清晰的同步状态指示

### 1.2 技术栈

- **iOS/macOS**: NSFileCoordinator + NSMetadataQuery
- **Flutter**: MethodChannel 桥接
- **存储**: iCloud Documents 容器

---

## 2. 实施步骤

### 步骤 1: 创建 iOS Entitlements 文件

**文件路径**: `ios/Runner/Runner.entitlements`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- iCloud Documents 权限 -->
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.$(CFBundleIdentifier)</string>
    </array>

    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudDocuments</string>
    </array>

    <key>com.apple.developer.ubiquity-container-identifiers</key>
    <array>
        <string>iCloud.$(CFBundleIdentifier)</string>
    </array>

    <!-- 保留现有权限 -->
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)$(CFBundleIdentifier)</string>
    </array>
</dict>
</plist>
```

### 步骤 2: 更新 macOS Entitlements

**文件路径**: `macos/Runner/Release.entitlements` 和 `macos/Runner/DebugProfile.entitlements`

在现有配置中添加：

```xml
<!-- 在 </dict> 之前添加 -->
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.$(CFBundleIdentifier)</string>
</array>

<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudDocuments</string>
</array>

<key>com.apple.developer.ubiquity-container-identifiers</key>
<array>
    <string>iCloud.$(CFBundleIdentifier)</string>
</array>
```

### 步骤 3: 配置 Xcode 项目

**iOS 项目配置**:

1. 打开 `ios/Runner.xcworkspace`
2. 选择 Runner target
3. 进入 "Signing & Capabilities" 标签
4. 点击 "+ Capability"
5. 添加 "iCloud"
6. 勾选 "iCloud Documents"
7. 确认 Container 为 `iCloud.com.hardydou.hedge`

**macOS 项目配置**:

1. 打开 `macos/Runner.xcworkspace`
2. 重复上述步骤

### 步骤 4: 创建 iCloud 服务类（iOS/macOS 原生）

**文件路径**: `ios/Runner/ICloudService.swift`

```swift
import Foundation

class ICloudService {
    static let shared = ICloudService()
    private var metadataQuery: NSMetadataQuery?
    private var onFileChanged: ((String) -> Void)?

    // 获取 iCloud Documents 路径
    func getICloudDocumentsPath() -> String? {
        guard let containerURL = FileManager.default.url(
            forUbiquityContainerIdentifier: nil
        ) else {
            print("[iCloud] Container not available")
            return nil
        }

        let documentsURL = containerURL.appendingPathComponent("Documents")

        // 确保目录存在
        try? FileManager.default.createDirectory(
            at: documentsURL,
            withIntermediateDirectories: true,
            attributes: nil
        )

        print("[iCloud] Documents path: \(documentsURL.path)")
        return documentsURL.path
    }

    // 检查 iCloud 是否可用
    func isICloudAvailable() -> Bool {
        return FileManager.default.ubiquityIdentityToken != nil
    }

    // 开始监听文件变化
    func startWatching(fileName: String, onChanged: @escaping (String) -> Void) {
        self.onFileChanged = onChanged

        metadataQuery = NSMetadataQuery()
        guard let query = metadataQuery else { return }

        // 设置搜索范围为 iCloud Documents
        query.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]

        // 搜索指定文件
        query.predicate = NSPredicate(
            format: "%K LIKE %@",
            NSMetadataItemFSNameKey,
            fileName
        )

        // 监听查询更新
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(queryDidUpdate(_:)),
            name: .NSMetadataQueryDidUpdate,
            object: query
        )

        // 监听初始查询完成
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(queryDidFinishGathering(_:)),
            name: .NSMetadataQueryDidFinishGathering,
            object: query
        )

        // 启动查询
        query.start()
        print("[iCloud] Started watching: \(fileName)")
    }

    // 停止监听
    func stopWatching() {
        metadataQuery?.stop()
        NotificationCenter.default.removeObserver(self)
        print("[iCloud] Stopped watching")
    }

    @objc private func queryDidUpdate(_ notification: Notification) {
        handleQueryResults()
    }

    @objc private func queryDidFinishGathering(_ notification: Notification) {
        handleQueryResults()
    }

    private func handleQueryResults() {
        guard let query = metadataQuery else { return }

        query.disableUpdates()
        defer { query.enableUpdates() }

        if query.resultCount > 0 {
            if let item = query.result(at: 0) as? NSMetadataItem,
               let url = item.value(forAttribute: NSMetadataItemURLKey) as? URL {

                // 检查下载状态
                if let downloadStatus = item.value(
                    forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey
                ) as? String {
                    print("[iCloud] Download status: \(downloadStatus)")

                    if downloadStatus == NSMetadataUbiquitousItemDownloadingStatusCurrent {
                        // 文件已下载，通知 Dart 层
                        onFileChanged?(url.path)
                    } else if downloadStatus == NSMetadataUbiquitousItemDownloadingStatusNotDownloaded {
                        // 触发下载
                        try? FileManager.default.startDownloadingUbiquitousItem(at: url)
                    }
                }
            }
        }
    }

    // 获取同步状态
    func getSyncStatus(filePath: String) -> [String: Any] {
        let url = URL(fileURLWithPath: filePath)

        guard let query = metadataQuery,
              query.resultCount > 0,
              let item = query.result(at: 0) as? NSMetadataItem else {
            return ["status": "unknown"]
        }

        var status: [String: Any] = [:]

        // 下载状态
        if let downloadStatus = item.value(
            forAttribute: NSMetadataUbiquitousItemDownloadingStatusKey
        ) as? String {
            status["downloadStatus"] = downloadStatus
        }

        // 上传状态
        if let isUploading = item.value(
            forAttribute: NSMetadataUbiquitousItemIsUploadingKey
        ) as? Bool {
            status["isUploading"] = isUploading
        }

        if let isUploaded = item.value(
            forAttribute: NSMetadataUbiquitousItemIsUploadedKey
        ) as? Bool {
            status["isUploaded"] = isUploaded
        }

        // 上传进度
        if let uploadingError = item.value(
            forAttribute: NSMetadataUbiquitousItemUploadingErrorKey
        ) as? NSError {
            status["uploadError"] = uploadingError.localizedDescription
        }

        return status
    }
}
```

### 步骤 5: 更新 AppDelegate（iOS）

**文件路径**: `ios/Runner/AppDelegate.swift`

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    private var iCloudChannel: FlutterMethodChannel?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller = window?.rootViewController as! FlutterViewController

        // 创建 iCloud MethodChannel
        iCloudChannel = FlutterMethodChannel(
            name: "com.hardydou.hedge/icloud",
            binaryMessenger: controller.binaryMessenger
        )

        iCloudChannel?.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call, result: result)
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getICloudDocumentsPath":
            if let path = ICloudService.shared.getICloudDocumentsPath() {
                result(path)
            } else {
                result(FlutterError(
                    code: "UNAVAILABLE",
                    message: "iCloud is not available",
                    details: nil
                ))
            }

        case "isICloudAvailable":
            result(ICloudService.shared.isICloudAvailable())

        case "startWatching":
            guard let args = call.arguments as? [String: Any],
                  let fileName = args["fileName"] as? String else {
                result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Missing fileName",
                    details: nil
                ))
                return
            }

            ICloudService.shared.startWatching(fileName: fileName) { [weak self] path in
                // 通知 Dart 层文件已变化
                self?.iCloudChannel?.invokeMethod("onFileChanged", arguments: ["path": path])
            }
            result(nil)

        case "stopWatching":
            ICloudService.shared.stopWatching()
            result(nil)

        case "getSyncStatus":
            guard let args = call.arguments as? [String: Any],
                  let filePath = args["filePath"] as? String else {
                result(FlutterError(
                    code: "INVALID_ARGS",
                    message: "Missing filePath",
                    details: nil
                ))
                return
            }

            let status = ICloudService.shared.getSyncStatus(filePath: filePath)
            result(status)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
```

### 步骤 6: 更新 AppDelegate（macOS）

**文件路径**: `macos/Runner/AppDelegate.swift`

创建相同的 `ICloudService.swift` 文件（可以共享代码），然后更新 AppDelegate：

```swift
import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    private var iCloudChannel: FlutterMethodChannel?

    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = mainFlutterWindow?.contentViewController as! FlutterViewController

        // 创建 iCloud MethodChannel
        iCloudChannel = FlutterMethodChannel(
            name: "com.hardydou.hedge/icloud",
            binaryMessenger: controller.engine.binaryMessenger
        )

        iCloudChannel?.setMethodCallHandler { [weak self] (call, result) in
            self?.handleMethodCall(call, result: result)
        }
    }

    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // 与 iOS 相同的实现
        // ... (复制 iOS AppDelegate 的 handleMethodCall 方法)
    }
}
```

### 步骤 7: 更新 Dart 层存储路径

**文件路径**: `lib/presentation/providers/vault_provider.dart`

```dart
static Future<String> _getDefaultVaultPath() async {
  // iOS/macOS: 优先使用 iCloud
  if (Platform.isIOS || Platform.isMacOS) {
    try {
      const channel = MethodChannel('com.hardydou.hedge/icloud');

      // 检查 iCloud 是否可用
      final isAvailable = await channel.invokeMethod<bool>('isICloudAvailable');

      if (isAvailable == true) {
        // 获取 iCloud Documents 路径
        final iCloudPath = await channel.invokeMethod<String>('getICloudDocumentsPath');

        if (iCloudPath != null && iCloudPath.isNotEmpty) {
          print('[Vault] Using iCloud path: $iCloudPath');
          return '$iCloudPath/vault.db';
        }
      } else {
        print('[Vault] iCloud not available, using local storage');
      }
    } catch (e) {
      print('[Vault] Failed to get iCloud path: $e');
    }
  }

  // Fallback: 使用本地 Documents 目录
  final directory = await getApplicationDocumentsDirectory();
  return '${directory.path}/vault.db';
}
```

### 步骤 8: 重构 iOS 同步服务

**文件路径**: `lib/platform/ios_sync_service.dart`

```dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:hedge/services/sync_service.dart';

class IOSSyncService implements SyncService {
  static const _channel = MethodChannel('com.hardydou.hedge/icloud');
  final _eventController = StreamController<FileChangeEvent>.broadcast();
  String? _vaultPath;
  bool _isWatching = false;

  IOSSyncService() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onFileChanged') {
      final args = call.arguments as Map<dynamic, dynamic>;
      final path = args['path'] as String?;

      print('[iCloud Sync] File changed: $path');

      _eventController.add(FileChangeEvent(
        type: ChangeType.modified,
        timestamp: DateTime.now(),
        filePath: path,
      ));
    }
  }

  @override
  Future<void> startWatching(String vaultPath, {String? masterPassword}) async {
    if (_isWatching) return;

    _vaultPath = vaultPath;

    try {
      // 开始监听文件变化
      await _channel.invokeMethod('startWatching', {
        'fileName': 'vault.db',
      });

      _isWatching = true;
      print('[iCloud Sync] Started watching: $vaultPath');
    } catch (e) {
      print('[iCloud Sync] Failed to start watching: $e');
      rethrow;
    }
  }

  @override
  Future<void> stopWatching() async {
    if (!_isWatching) return;

    try {
      await _channel.invokeMethod('stopWatching');
      _isWatching = false;
      _vaultPath = null;
      print('[iCloud Sync] Stopped watching');
    } catch (e) {
      print('[iCloud Sync] Failed to stop watching: $e');
    }
  }

  @override
  Stream<FileChangeEvent> get onFileChanged => _eventController.stream;

  @override
  Future<SyncStatus> getSyncStatus() async {
    if (_vaultPath == null) {
      return SyncStatus.unknown;
    }

    try {
      final status = await _channel.invokeMethod<Map>('getSyncStatus', {
        'filePath': _vaultPath,
      });

      if (status == null) return SyncStatus.unknown;

      // 解析同步状态
      final isUploading = status['isUploading'] as bool?;
      final isUploaded = status['isUploaded'] as bool?;
      final downloadStatus = status['downloadStatus'] as String?;

      if (isUploading == true) {
        return SyncStatus.uploading;
      }

      if (downloadStatus == 'NSMetadataUbiquitousItemDownloadingStatusCurrent' &&
          isUploaded == true) {
        return SyncStatus.synced;
      }

      return SyncStatus.syncing;
    } catch (e) {
      print('[iCloud Sync] Failed to get sync status: $e');
      return SyncStatus.unknown;
    }
  }

  @override
  Future<bool> hasConflict(String vaultPath) async {
    final file = File(vaultPath);
    final directory = file.parent;
    final fileName = file.path.split('/').last.replaceAll('.db', '');

    try {
      final files = directory.listSync();
      return files.any((f) =>
        f.path.contains('${fileName}_') &&
        f.path.endsWith('.db') &&
        f.path != vaultPath
      );
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> createConflictBackup(String vaultPath) async {
    final file = File(vaultPath);
    if (!await file.exists()) return;

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = vaultPath.replaceAll('.db', '_conflict_$timestamp.db');

    await file.copy(backupPath);
    print('[iCloud Sync] Created conflict backup: $backupPath');
  }

  void dispose() {
    stopWatching();
    _eventController.close();
  }
}
```

### 步骤 9: 更新同步状态枚举

**文件路径**: `lib/services/sync_service.dart`

```dart
enum SyncStatus {
  unknown,      // 未知状态
  synced,       // 已同步
  syncing,      // 同步中
  uploading,    // 上传中
  downloading,  // 下载中
  error,        // 错误
}
```

---

## 3. 测试步骤

### 3.1 单设备测试

1. **编译并运行应用**
   ```bash
   cd ios
   pod install
   cd ..
   fvm flutter run -d iPhone
   ```

2. **检查 iCloud 状态**
   - 确保设备已登录 iCloud 账号
   - 进入"设置 > Apple ID > iCloud"，确认 iCloud Drive 已开启

3. **创建测试数据**
   - 在应用中创建几个密码条目
   - 检查日志确认文件保存到 iCloud 路径

4. **验证文件位置**
   - 在 macOS Finder 中打开 `~/Library/Mobile Documents/iCloud~com~hardydou~hedge/Documents/`
   - 确认 `vault.db` 文件存在

### 3.2 多设备同步测试

1. **在第二台设备上安装应用**
   - 使用相同的 Apple ID 登录
   - 启动应用

2. **验证自动同步**
   - 在设备 A 添加新密码
   - 等待 10-30 秒
   - 在设备 B 上检查是否出现新密码

3. **测试冲突场景**
   - 在两台设备上同时编辑同一条目
   - 验证冲突备份文件是否生成

### 3.3 性能测试

1. **电池续航**
   - 运行应用 1 小时，监控电池消耗
   - 对比旧版本（Timer 轮询）

2. **同步延迟**
   - 测量从修改到同步完成的时间
   - 目标: < 30 秒

---

## 4. 故障排查

### 4.1 iCloud 不可用

**症状**: `isICloudAvailable()` 返回 false

**可能原因**:
- 用户未登录 iCloud
- iCloud Drive 未开启
- Entitlements 配置错误
- 网络问题

**解决方案**:
1. 检查设备 iCloud 登录状态
2. 验证 Entitlements 文件配置
3. 在 Xcode 中检查 Capabilities 是否正确启用

### 4.2 文件未同步

**症状**: 修改后其他设备未收到更新

**可能原因**:
- NSMetadataQuery 未正确启动
- 文件未保存到 iCloud 容器
- iCloud 同步延迟

**解决方案**:
1. 检查日志确认 `startWatching` 成功
2. 验证文件路径是否在 iCloud 容器内
3. 手动触发同步（下拉刷新）

### 4.3 冲突文件过多

**症状**: 生成大量 `vault_conflict_*.db` 文件

**可能原因**:
- 冲突检测逻辑过于敏感
- 时间戳比较不准确

**解决方案**:
1. 优化冲突检测算法
2. 添加文件内容哈希比较
3. 提供冲突文件清理功能

---

## 5. 用户文档

### 5.1 设置指南

**标题**: 如何启用 iCloud 同步

**步骤**:
1. 确保您的设备已登录 iCloud 账号
2. 进入"设置 > Apple ID > iCloud"
3. 开启"iCloud Drive"
4. 在应用列表中找到"Hedge"并开启
5. 重启 Hedge 应用

### 5.2 常见问题

**Q: 为什么我的密码没有同步到其他设备？**

A: 请检查：
- 所有设备是否使用相同的 Apple ID
- iCloud Drive 是否已开启
- 设备是否连接到互联网
- iCloud 存储空间是否充足

**Q: 同步需要多长时间？**

A: 通常在 10-30 秒内完成，取决于网络状况和文件大小。

**Q: 如果出现冲突怎么办？**

A: 应用会自动保留两个版本，您可以在设置中查看和合并冲突文件。

---

## 6. 后续优化

### 6.1 短期优化（1-2 周）

- [ ] 添加同步状态指示器（UI）
- [ ] 实现手动触发同步
- [ ] 优化冲突检测算法
- [ ] 添加同步日志查看功能

### 6.2 中期优化（1-2 月）

- [ ] 实现增量同步（仅同步变更部分）
- [ ] 添加同步历史记录
- [ ] 支持冲突文件合并工具
- [ ] 优化大文件同步性能

### 6.3 长期优化（3-6 月）

- [ ] 实现端到端加密（在 iCloud 之上）
- [ ] 支持多密码库同步
- [ ] 添加同步统计和分析
- [ ] 实现智能冲突解决

---

**实施完成标准**:
- ✅ 所有测试用例通过
- ✅ 多设备同步延迟 < 30 秒
- ✅ 电池消耗降低 > 50%（相比 Timer 轮询）
- ✅ 用户文档完成
- ✅ 代码审查通过
