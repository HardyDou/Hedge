# iCloud 同步功能设计文档

## 1. 概述

实现跨设备密码库同步功能，支持 iOS/macOS (iCloud) 和 Android (厂商云)。

## 2. 技术方案

### 2.1 iOS - NSFilePresenter + NSMetadataQuery

```swift
// 文件监听核心逻辑
class VaultFilePresenter: NSObject, NSFilePresenter {
    var presentedItemURL: URL?
    var presentedItemOperationQueue: OperationQueue
    
    func presentedItemDidChange() {
        // 文件发生变化，通知 Dart 层
    }
    
    func presentedSubitemDidChange(at url: URL) {
        // 子项目变化
    }
}
```

### 2.2 Android - FileObserver

```kotlin
// 文件监听
class VaultFileObserver(path: String) : FileObserver(path) {
    override fun onEvent(event: Int, path: String?) {
        // 通知 Dart 层
    }
}
```

### 2.3 Dart 层架构

```
lib/
├── services/
│   └── sync_service.dart      # 同步服务抽象
├── platform/
│   ├── ios_sync_service.dart   # iOS 实现
│   └── android_sync_service.dart # Android 实现
```

## 3. 冲突解决策略

### 3.1 检测冲突
- 记录本地 `updatedAt` 时间戳
- 检测到外部变更时，比较时间戳

### 3.2 保留冲突副本
```
vault.db          # 主文件
vault_2026-02-27_10-30-00.db  # 冲突备份
vault_2026-02-27_11-45-00.db  # 另一个冲突备份
```

### 3.3 用户通知
- 检测到冲突时显示提示
- 允许用户手动合并

## 4. 实现计划

### Phase 1: 基础架构
1. 创建同步服务抽象接口
2. 实现 iOS 文件监听
3. 实现 Android 文件监听

### Phase 2: 冲突处理
1. 时间戳比较逻辑
2. 冲突备份机制
3. 用户通知 UI

### Phase 3: 状态同步
1. 加载时检测远程变更
2. 自动刷新 UI
3. iCloud 状态显示

## 5. API 设计

```dart
abstract class SyncService {
    // 启动监听
    Future<void> startWatching(String vaultPath);
    
    // 停止监听
    Future<void> stopWatching();
    
    // 监听变更流
    Stream<FileChangeEvent> get onFileChanged;
    
    // 获取同步状态
    Future<SyncStatus> getSyncStatus();
}

class FileChangeEvent {
    final ChangeType type; // modified, deleted, created
    final DateTime timestamp;
}
```
