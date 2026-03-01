# Xcode iCloud 配置指南

## 步骤 1: 打开项目并选择 Target

1. 在 Xcode 左侧项目导航器中，点击最顶部的蓝色 **Runner** 图标
2. 在中间区域，你会看到两个部分：
   - **PROJECT**: Runner
   - **TARGETS**: Runner
3. 点击 **TARGETS** 下的 **Runner**（不是 PROJECT 下的）

## 步骤 2: 进入 Signing & Capabilities

1. 在顶部标签栏中，点击 **Signing & Capabilities**
2. 你应该看到类似这样的界面：
   ```
   ┌─────────────────────────────────────────────────┐
   │ General | Signing & Capabilities | Info | ...   │
   ├─────────────────────────────────────────────────┤
   │                                                  │
   │ Signing (Debug)                                  │
   │ ☑ Automatically manage signing                   │
   │ Team: [选择你的团队]                              │
   │                                                  │
   └─────────────────────────────────────────────────┘
   ```

## 步骤 3: 添加 iCloud Capability

### 如果你看到 "+ Capability" 按钮：
1. 点击 **+ Capability** 按钮（通常在左上角或标签页下方）
2. 在弹出的列表中搜索 "iCloud"
3. 双击 "iCloud" 添加

### 如果你没看到 "+ Capability" 按钮：

**可能原因 1: 需要先配置签名**
- 确保 "Automatically manage signing" 已勾选
- 在 "Team" 下拉菜单中选择你的 Apple ID
- 如果没有 Team，需要在 Xcode > Settings > Accounts 中添加 Apple ID

**可能原因 2: Xcode 版本问题**
- 确保使用 Xcode 14+ 版本
- 运行: `xcodebuild -version` 检查版本

## 步骤 4: 配置 iCloud

添加 iCloud capability 后：

1. 在 iCloud 部分，勾选 **☑ iCloud Documents**
2. 在 Containers 部分：
   - 如果看到 `iCloud.com.hardydou.hedge`，直接勾选
   - 如果没有，点击 "+" 按钮添加
   - 输入: `iCloud.com.hardydou.hedge`

## 步骤 5: 对 iOS 重复相同操作

1. 关闭当前 Xcode 窗口
2. 打开 iOS 项目: `open ios/Runner.xcworkspace`
3. 重复步骤 1-4

## 常见问题

### Q: 找不到 "+ Capability" 按钮
**A**:
1. 确认你选择的是 TARGETS 下的 Runner，不是 PROJECT
2. 确认你在 "Signing & Capabilities" 标签页
3. 尝试先配置签名（添加 Team）

### Q: 添加 iCloud 后构建失败
**A**:
1. 确保你的 Apple ID 有权限使用 iCloud
2. 免费的 Apple ID 也可以，但需要登录
3. 检查 Entitlements 文件是否正确

### Q: 容器 ID 无法添加
**A**:
1. 确保格式正确: `iCloud.com.hardydou.hedge`
2. 确保 Bundle ID 匹配: `com.hardydou.hedge`
3. 可能需要在 Apple Developer 网站手动创建容器

## 验证配置

配置完成后，检查以下文件是否包含 iCloud 配置：

### macOS:
- `macos/Runner/DebugProfile.entitlements` ✅ 已配置
- `macos/Runner/Release.entitlements` ✅ 已配置
- `macos/Runner/Info.plist` ✅ 已配置

### iOS:
- `ios/Runner/Runner.entitlements` (需要 Xcode 自动生成)

## 下一步

配置完成后，运行：
```bash
fvm flutter clean
fvm flutter build macos --debug
```

如果构建成功，说明配置正确！
