# 托盘快捷面板技术验证报告

**验证日期**: 2026-03-02
**验证环境**: macOS
**Flutter 版本**: 3.11.0
**依赖版本**:
- tray_manager: 0.2.4
- window_manager: 0.4.3

---

## 验证结果总览

| 验证项 | 状态 | 说明 |
|--------|------|------|
| 1. 托盘图标创建 | ✅ 通过 | 托盘图标成功显示在菜单栏 |
| 2. 主窗口关闭进入托盘 | ✅ 通过 | 关闭主窗口后应用不退出，进入托盘状态 |
| 3. Dock 图标隐藏 | ✅ 通过 | 进入托盘状态后 Dock 图标自动隐藏 |
| 4. 点击托盘切换 Panel | ✅ 通过 | 点击托盘图标可以切换 Panel 显示/隐藏 |
| 5. Panel 窗口样式 | ✅ 通过 | 无边框、不可移动、置顶、固定尺寸 240x320 |
| 6. Panel 主题支持 | ✅ 通过 | 支持深色/浅色主题，自动跟随系统 |
| 7. Panel 失焦隐藏 | ✅ 通过 | 点击外部区域自动隐藏 |
| 8. 从 Panel 打开主窗口 | ✅ 通过 | 点击按钮可以恢复主窗口和 Dock 图标 |
| 9. 从 Panel 退出应用 | ✅ 通过 | 点击"退出应用"可以完全退出 |
| 10. Panel 位置定位 | ⚠️ 待优化 | Panel 与托盘图标有间距，无法紧贴显示 |

---

## 关键技术点

### 1. 阻止窗口关闭时退出应用 ✅

**问题**: macOS 应用默认在最后一个窗口关闭时会自动退出

**解决方案**: 修改 `AppDelegate.swift`

```swift
override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return false  // 关闭窗口后不退出应用
}
```

### 2. 窗口关闭时隐藏到托盘 ✅

**实现方式**:
```dart
// 设置阻止默认关闭行为
await windowManager.setPreventClose(true);

// 监听窗口关闭事件
@override
void onWindowClose() async {
    await windowManager.hide();  // 隐藏窗口
    await windowManager.setSkipTaskbar(true);  // 隐藏 Dock 图标
}
```

### 3. 托盘图标管理 ✅

**实现方式**:
```dart
// 设置托盘图标
await trayManager.setIcon('assets/icons/tray_icon.png', isTemplate: true);
await trayManager.setToolTip('Hedge 密码管理器');

// 设置托盘菜单
Menu menu = Menu(items: [
    MenuItem(key: 'show_panel', label: '显示快捷面板'),
    MenuItem(key: 'show_main', label: '打开主窗口'),
    MenuItem.separator(),
    MenuItem(key: 'exit', label: '退出应用'),
]);
await trayManager.setContextMenu(menu);
```

### 4. 点击托盘切换 Panel ✅

**实现方式**:
```dart
@override
void onTrayIconMouseDown() {
    _togglePanel();
}

Future<void> _togglePanel() async {
    if (_isPanelMode) {
        final isVisible = await windowManager.isVisible();
        if (isVisible) {
            await windowManager.hide();
        } else {
            await windowManager.show();
        }
    } else {
        _showPanel();
    }
}
```

### 5. Panel 窗口样式 ✅

**实现方式**:
```dart
// 配置 Panel 窗口
await windowManager.setSize(const Size(240, 320));
await windowManager.setAlwaysOnTop(true);
await windowManager.setSkipTaskbar(true);
await windowManager.setResizable(false);
await windowManager.setMovable(false);  // 禁止移动
await windowManager.setTitleBarStyle(
    TitleBarStyle.hidden,
    windowButtonVisibility: false,  // 隐藏窗口按钮
);
```

### 6. Panel 主题支持 ✅

**实现方式**:
```dart
Widget _buildPanelWindow() {
    final brightness = MediaQuery.platformBrightnessOf(context);
    final isDark = brightness == Brightness.dark;

    return Container(
        decoration: BoxDecoration(
            color: isDark
                ? CupertinoColors.darkBackgroundGray
                : CupertinoColors.systemBackground,
            // ...
        ),
        // ...
    );
}
```

### 7. Panel 位置定位 ⚠️

**问题**: Panel 窗口与托盘图标之间有约一个托盘高度的间距

**已尝试的方法**:
- 使用 `trayBounds.bottom`
- 使用 `trayBounds.top + height`
- 使用固定菜单栏高度
- 使用负偏移补偿标题栏高度

**待解决**: 需要进一步研究 window_manager 的坐标系统或使用原生 API

---

## 验证代码

验证代码位于：
- `lib/tech_validation_panel.dart` - Panel 窗口验证
- `lib/main_validation_panel.dart` - 验证入口

运行命令：
```bash
fvm flutter run -d macos -t lib/main_validation_panel.dart
```

---

## 结论

✅ **核心功能验证通过**

关键成果：
1. ✅ 托盘图标可以正常创建和显示
2. ✅ 主窗口关闭后应用继续运行，不退出
3. ✅ Dock 图标可以在托盘状态下隐藏
4. ✅ 点击托盘图标可以切换 Panel 显示/隐藏
5. ✅ Panel 窗口样式符合要求（无边框、不可移动、置顶）
6. ✅ Panel 支持深色/浅色主题
7. ✅ Panel 失焦自动隐藏
8. ✅ 可以从 Panel 重新打开主窗口
9. ✅ 可以从 Panel 完全退出应用

待优化：
- ⚠️ Panel 窗口位置定位需要进一步优化

**技术验证基本完成，可以继续进行后续开发任务。**

---

## 下一步计划

### 已完成 ✅
- [x] 任务 1: 添加项目依赖
- [x] 任务 2: 技术验证（核心功能）

### 待完成 🔄
- [ ] 优化 Panel 窗口位置定位
- [ ] 任务 3: 创建项目结构
- [ ] 任务 4: 实现托盘管理服务
- [ ] 任务 5: 实现窗口管理服务
- [ ] 后续任务...

---

**验证人**: Claude Sonnet 4.6
**审核状态**: ✅ 通过
