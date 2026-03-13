# 密码生成器 - 产品规划与开发计划

**功能名称**: 密码生成器（Password Generator）
**目标版本**: v1.8.0
**优先级**: P0（必须完成）
**日期**: 2026-03-06
**文档状态**: ✅ 已完成

---

## 👤 用户画像

**张三** - 30岁，互联网从业者
- 有 50+ 个网站账号需要管理
- 经常注册新网站，每周 2-3 次
- 希望每个网站用不同的强密码
- 不想自己想密码（太麻烦）

---

## 📖 核心用户故事

### 故事 1：注册新网站时生成密码

**场景描述**：
张三在浏览器打开了一个新网站准备注册账号，需要设置密码。他打开 Hedge 密码本准备保存新密码。

**用户目标**：
快速生成一个强密码，保存到密码本，然后复制去注册网站。

**操作流程**：

#### 移动端（iPhone）
```
1. 打开 Hedge App
2. 点击右上角 "+" 按钮（新增密码）
3. 进入"新增密码"页面
4. 点击"生成"按钮
5. 从底部弹出密码生成器面板
6. （可选）如果不满意，点击"重新生成"
7. （可选）调整配置（如长度改为 20）
8. 点击"使用此密码"
9. 密码自动填入密码输入框
10. 点击"保存"
11. 密码条目已保存
12. 点击密码字段旁的"复制"按钮
13. 切换到浏览器，粘贴密码完成注册
```

**时间成本**：约 30 秒

#### 桌面端（MacBook）
```
1. 点击菜单栏 Hedge 图标（或打开主窗口）
2. 点击左上角 "+" 按钮
3. 在右侧详情面板显示新增表单
4. 点击密码输入框右侧的 🔑 图标
5. 在输入框下方弹出 Popover
6. （可选）拖动滑块调整长度
7. （可选）按 Cmd+R 重新生成
8. 点击"使用"按钮（或按 Enter）
9. 密码自动填入输入框
10. 点击"保存"
11. 鼠标悬停在密码字段，点击"复制"
12. 切换到浏览器粘贴
```

**时间成本**：约 20 秒

---

### 故事 2：修改现有密码（定期更换）

**场景描述**：
张三收到邮件提醒"您的 GitHub 密码已使用 6 个月，建议更换"。他打开 Hedge 准备生成新密码。

**用户目标**：
为已有账号生成新密码并更新。

**操作流程**：
```
1. 打开 Hedge App
2. 搜索或滚动找到"GitHub"
3. 点击进入详情页
4. 点击右上角"编辑"按钮
5. 在密码字段右侧点击"生成"按钮
6. 弹出密码生成器面板
7. 点击"使用此密码"
8. 新密码替换旧密码
9. 点击"保存"
10. 复制新密码去 GitHub 修改
```

**时间成本**：约 25 秒

---

### 故事 3：快速生成密码（不保存到条目）

**场景描述**：
张三在填写一个临时表单，需要一个随机密码，但不想保存到密码本（因为是临时的）。

**用户目标**：
快速生成一个密码并复制，不保存。

**操作流程**：
```
1. 点击菜单栏 Hedge 图标
2. 快捷面板弹出
3. 点击右上角 🔑 图标
4. 在搜索框下方展开极简生成器
5. 点击 📋 复制按钮
6. 显示"已复制"提示
7. 切换到浏览器粘贴
```

**时间成本**：约 5 秒（最快！）

---

### 故事 4：生成特定要求的密码

**场景描述**：
张三注册某银行网站，要求密码必须 12-16 位，必须包含大小写字母和数字，但不能有符号。

**用户目标**：
按照网站要求定制密码。

**关键点**：配置会自动保存，下次生成时会记住用户偏好。

---

## 🎯 入口总结

### 移动端入口（2个）
1. **新增密码页面** - 密码输入框右侧的"生成"按钮
2. **编辑密码页面** - 密码输入框右侧的"生成"按钮

### 桌面端入口（3个）
1. **主窗口新增** - 详情面板密码输入框右侧的 🔑 图标
2. **主窗口编辑** - 详情面板密码输入框右侧的 🔑 图标
3. **快捷面板** - 顶部搜索框右侧的 🔑 图标（独立功能）

---

## 💡 设计亮点

### 1. 零学习成本
- 入口明显：密码输入框旁边就是生成按钮
- 自动生成：打开面板就有密码，不需要额外操作
- 一键使用：点击"使用"就自动填入

### 2. 渐进式配置
- **新手**：直接用默认配置生成，点击使用
- **进阶**：调整长度和字符类型
- **专家**：排除易混淆字符，精确控制

### 3. 记忆用户偏好
- 配置自动保存
- 下次打开时使用上次的配置
- 不需要每次都重新设置

### 4. 多场景覆盖
- **保存场景**：新增/编辑密码时生成
- **临时场景**：快捷面板快速生成复制
- **批量场景**：（v2.0.0）批量生成多个密码

---

## 📱 UI 布局图

### 1. 移动端 - 新增密码页面

```
┌─────────────────────────────────┐
│  ← 新增密码              [保存] │
├─────────────────────────────────┤
│                                 │
│  标题                            │
│  ┌─────────────────────────┐   │
│  │ GitHub                  │   │
│  └─────────────────────────┘   │
│                                 │
│  用户名                          │
│  ┌─────────────────────────┐   │
│  │ zhangsan@email.com      │   │
│  └─────────────────────────┘   │
│                                 │
│  密码                            │
│  ┌─────────────────────┐ [生成] │  ← 入口按钮
│  │                     │       │
│  └─────────────────────┘       │
│                                 │
│  网站                            │
│  ┌─────────────────────────┐   │
│  │ github.com              │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

---

### 2. 移动端 - 密码生成器面板（底部弹出）

```
┌─────────────────────────────────┐
│                                 │
│           密码生成器             │  ← 标题
│                                 │
│  ┌───────────────────────────┐ │
│  │  Xy9#mK2$pL4@nQ7         │ │  ← 生成的密码（等宽字体）
│  └───────────────────────────┘ │
│                                 │
│  ██████████████░░░  极强       │  ← 强度指示条（绿色）
│                                 │
│  ───────────────────────────   │  ← 分隔线
│                                 │
│  长度: 16          [- 16 +]   │  ← 步进器
│                                 │
│  ☑ 大写字母 (A-Z)              │
│  ☑ 小写字母 (a-z)              │
│  ☑ 数字 (0-9)                  │
│  ☑ 符号 (!@#$...)              │
│  ☐ 排除易混淆字符               │
│                                 │
│  ───────────────────────────   │
│                                 │
│  [      重新生成      ]        │
│                     [使用此密码]│
│                                 │
└─────────────────────────────────┘
```

---

### 3. 桌面端 - 详情面板 + Popover

```
┌──────────────────┬─────────────────────────────────────────┐
│                  │  新增密码                      [保存]   │
│  密码列表        ├─────────────────────────────────────────┤
│                  │                                          │
│  🔍 搜索...     │  标题:  [GitHub                      ]   │
│                  │                                          │
│  GitHub         │  用户名: [zhangsan@email.com          ]   │
│  Google         │                                          │
│  Twitter        │  密码:  [••••••••••••••••] 🔑           │  ← 入口
│                  │                                          │
│                  │  网站:  [github.com                    ]   │
│                  │                                          │
└──────────────────┴─────────────────────────────────────────┘
                          │
                          ▼
                  
┌─────────────────────────────────────────┐
│  密码生成器                    [×]       │  ← Popover 浮层
├─────────────────────────────────────────┤
│                                         │
│  生成的密码:                             │
│  ┌───────────────────────────────────┐ │
│  │  Xy9#mK2$pL4@nQ7          [👁] [📋]│ │  ← 显示/复制
│  └───────────────────────────────────┘ │
│                                         │
│  强度: ██████████████░░░  极强         │  ← 强度指示
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  长度: [━━━━━━━━━━●━━━━━] 16           │  ← 滑块
│                                         │
│  ☑ 大写字母    ☑ 数字                   │
│  ☑ 小写字母    ☑ 符号                   │
│                                         │
│  ☐ 排除易混淆字符 (0/O, 1/l/I)          │
│                                         │
│  ─────────────────────────────────────  │
│                                         │
│  [🔄 重新生成]              [✓ 使用]    │
│                                         │
└─────────────────────────────────────────┘
```

---

### 4. 桌面端 - 快捷面板（极简生成器）

```
┌─────────────────────────────────────┐
│  🔍 搜索...              [🔑]       │  ← 生成按钮（入口）
├─────────────────────────────────────┤
│                                     │
│  密码列表...                         │
│                                     │
│  ─────────────────────────────────  │
│                                     │
│  GitHub                             │
│  zhangsan@email.com                 │
│                                     │
│  Google                             │
│  john@gmail.com                      │
│                                     │
└─────────────────────────────────────┘
           │
           ▼  点击 🔑 后展开
           
┌─────────────────────────────────────┐
│  🔍 搜索...              [🔑]       │
├─────────────────────────────────────┤
│                                     │
│  ┌─────────────────────────────┐   │
│  │  Xy9#mK2$pL4@nQ7    [👁] [📋]│   │  ← 生成的密码
│  └─────────────────────────────┘   │
│                                     │
│  强度: ██████████░░░░  极强         │  ← 强度指示
│                                     │
│  [⚙️ 配置]  [🔄 重新生成]          │  ← 操作按钮
│                                     │
├─────────────────────────────────────┤
│                                     │
│  密码列表...                         │
│                                     │
└─────────────────────────────────────┘
```

---

### 5. 强度指示条详细设计

```
弱 (0-25%)    ████░░░░░░░░░░░░░░  弱
              🔴 红色

中 (25-50%)   ██████████░░░░░░░░  中
              🟠 橙色

强 (50-75%)   ██████████████░░░░░  强
              🟡 黄色

极强 (75-100%) █████████████████░░  极强
              🟢 绿色
```

---

## 🔄 用户操作流程图

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   打开 App                                                   │
│       │                                                     │
│       ▼                                                     │
│   ┌─────────────────┐                                      │
│   │ 点击 "+" 新增   │ ──→ 场景 1: 新注册                    │
│   └────────┬────────┘                                      │
│            │                                                │
│            ▼                                                │
│   ┌─────────────────┐     ┌─────────────────┐            │
│   │ 填写标题/用户名  │ ──► │ 点击密码 [生成]  │            │
│   └────────┬────────┘     └────────┬────────┘            │
│            │                       │                       │
│            ▼                       ▼                       │
│   ┌─────────────────────────────────────────┐             │
│   │         底部弹出生成器面板               │             │
│   │  ┌─────────────────────────────────┐   │             │
│   │  │  Xy9#mK2$pL4@nQ7  [复制]       │   │             │
│   │  └─────────────────────────────────┘   │             │
│   │  ██████████████████░░░  极强           │             │
│   │                                         │             │
│   │  长度: 16  [ - 16 + ]                  │             │
│   │  ☑大写  ☑小写  ☑数字  ☑符号           │             │
│   │                                         │             │
│   │  [重新生成]        [使用此密码]         │             │
│   └─────────────────────────────────────────┘             │
│                       │                                   │
│                       ▼                                   │
│               密码填入输入框                                │
│                       │                                   │
│                       ▼                                   │
│               [保存] ──► 完成！                           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🎯 核心需求

### 功能需求

**1. 密码生成配置**
- 长度：8-64 字符（默认 16）
- 字符类型：
  - ✅ 大写字母 (A-Z)
  - ✅ 小写字母 (a-z)
  - ✅ 数字 (0-9)
  - ✅ 符号 (!@#$%^&*()_+-=[]{}|;:,.<>?)
- 排除易混淆字符（可选）：0/O, 1/l/I
- 记住用户偏好

**2. 密码强度检测**
- 实时计算强度：弱/中/强/极强
- 彩色强度指示条
- 具体改进建议（如"建议增加符号"）

**3. 使用场景**
- 场景1：新增密码时生成
- 场景2：编辑密码时重新生成
- 场景3：快捷面板快速生成并复制

---

## ⚙️ 技术方案

### 架构设计

**Domain Layer（业务逻辑层）**

```dart
// lib/domain/services/password_generator_service.dart
class PasswordGeneratorService {
  /// 生成密码
  static String generate(PasswordGeneratorConfig config) {
    // 1. 构建字符集
    // 2. 随机选择字符
    // 3. 确保至少包含每种选中的字符类型
    // 4. 打乱顺序
  }

  /// 计算密码强度（0-100）
  static PasswordStrength calculateStrength(String password) {
    // 基于长度、字符类型多样性、熵值计算
    // 返回: 分数 + 等级 + 建议
  }
}

// lib/domain/models/password_generator_config.dart
class PasswordGeneratorConfig {
  final int length;              // 8-64
  final bool includeUppercase;   // A-Z
  final bool includeLowercase;   // a-z
  final bool includeNumbers;     // 0-9
  final bool includeSymbols;     // !@#$...
  final bool excludeAmbiguous;   // 排除 0/O, 1/l/I

  // JSON 序列化
  Map<String, dynamic> toJson();
  factory PasswordGeneratorConfig.fromJson(Map<String, dynamic> json);

  // 默认配置
  factory PasswordGeneratorConfig.defaultConfig() => PasswordGeneratorConfig(
    length: 16,
    includeUppercase: true,
    includeLowercase: true,
    includeNumbers: true,
    includeSymbols: true,
    excludeAmbiguous: false,
  );
}

// lib/domain/models/password_strength.dart
class PasswordStrength {
  final int score;           // 0-100
  final StrengthLevel level; // weak/medium/strong/veryStrong
  final String suggestion;   // 改进建议
  final Color color;         // 指示条颜色
}

enum StrengthLevel {
  weak,       // 0-25
  medium,     // 25-50
  strong,     // 50-75
  veryStrong, // 75-100
}
```

**Presentation Layer（UI层）**

```dart
// lib/presentation/providers/password_generator_provider.dart
@riverpod
class PasswordGeneratorNotifier extends _$PasswordGeneratorNotifier {
  @override
  PasswordGeneratorState build() {
    // 从本地存储加载用户偏好配置
    final config = _loadConfig();
    final password = PasswordGeneratorService.generate(config);
    final strength = PasswordGeneratorService.calculateStrength(password);

    return PasswordGeneratorState(
      config: config,
      generatedPassword: password,
      strength: strength,
    );
  }

  /// 更新配置并重新生成
  void updateConfig(PasswordGeneratorConfig config) {
    state = state.copyWith(config: config);
    regenerate();
    _saveConfig(config); // 持久化用户偏好
  }

  /// 重新生成密码
  void regenerate() {
    final password = PasswordGeneratorService.generate(state.config);
    final strength = PasswordGeneratorService.calculateStrength(password);
    state = state.copyWith(
      generatedPassword: password,
      strength: strength,
    );
  }

  /// 复制到剪贴板
  void copyToClipboard() {
    Clipboard.setData(ClipboardData(text: state.generatedPassword));
    // 显示提示
  }
}

class PasswordGeneratorState {
  final PasswordGeneratorConfig config;
  final String generatedPassword;
  final PasswordStrength strength;
}
```

### 密码强度算法

```dart
// lib/domain/services/password_strength_calculator.dart
class PasswordStrengthCalculator {
  static PasswordStrength calculate(String password) {
    int score = 0;

    // 1. 长度评分（最多40分）
    score += min(password.length * 2, 40);

    // 2. 字符类型多样性（最多30分）
    if (password.contains(RegExp(r'[A-Z]'))) score += 10;
    if (password.contains(RegExp(r'[a-z]'))) score += 10;
    if (password.contains(RegExp(r'[0-9]'))) score += 5;
    if (password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{}|;:,.<>?]'))) score += 15;

    // 3. 熵值评分（最多30分）
    final entropy = _calculateEntropy(password);
    score += min((entropy / 4).round(), 30);

    // 确定等级
    final level = _getLevel(score);

    // 生成建议
    final suggestion = _generateSuggestion(password, score);

    return PasswordStrength(
      score: score,
      level: level,
      suggestion: suggestion,
      color: _getColor(level),
    );
  }

  static double _calculateEntropy(String password) {
    final charSet = password.split('').toSet().length;
    return password.length * (log(charSet) / log(2));
  }

  static StrengthLevel _getLevel(int score) {
    if (score < 25) return StrengthLevel.weak;
    if (score < 50) return StrengthLevel.medium;
    if (score < 75) return StrengthLevel.strong;
    return StrengthLevel.veryStrong;
  }

  static String _generateSuggestion(String password, int score) {
    if (password.length < 12) return '建议增加长度至12位以上';
    if (!password.contains(RegExp(r'[!@#$%^&*()]'))) return '建议添加特殊符号';
    if (score < 50) return '建议使用更多字符类型';
    return '密码强度良好';
  }

  static Color _getColor(StrengthLevel level) {
    switch (level) {
      case StrengthLevel.weak:
        return CupertinoColors.systemRed;
      case StrengthLevel.medium:
        return CupertinoColors.systemOrange;
      case StrengthLevel.strong:
        return CupertinoColors.systemYellow;
      case StrengthLevel.veryStrong:
        return CupertinoColors.systemGreen;
    }
  }
}
```

### 配置持久化

```dart
// lib/domain/services/password_generator_config_service.dart
class PasswordGeneratorConfigService {
  static const _key = 'password_generator_config';

  /// 保存配置
  static Future<void> saveConfig(PasswordGeneratorConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(config.toJson()));
  }

  /// 加载配置
  static Future<PasswordGeneratorConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) {
      return PasswordGeneratorConfig.defaultConfig();
    }
    return PasswordGeneratorConfig.fromJson(jsonDecode(json));
  }
}
```

---

## 📋 开发计划

### 阶段一：核心逻辑

1. 创建 `PasswordGeneratorConfig` 模型
2. 创建 `PasswordStrength` 模型
3. 实现 `PasswordGeneratorService.generate()` 方法
4. 实现 `PasswordStrengthCalculator.calculate()` 方法
5. 实现 `PasswordGeneratorConfigService` 持久化
6. 创建 `PasswordGeneratorProvider` 状态管理

---

### 阶段二：移动端 UI

7. 创建 `PasswordGeneratorSheet` 底部面板组件
8. 实现密码显示区域 Widget
9. 实现强度指示条 Widget
10. 实现配置选项 UI（步进器、复选框）
11. 在 `AddItemPage` 集成"生成"按钮
12. 在 `EditItemPage` 集成"生成"按钮
13. 实现密码回填逻辑

---

### 阶段三：桌面端 UI

14. 创建 `PasswordGeneratorPopover` 浮层组件
15. 实现桌面端布局（滑块、双列复选框）
16. 添加键盘快捷键支持
17. 在桌面端详情面板集成"生成"按钮

---

### 阶段四：快捷面板

18. 创建 `PasswordGeneratorCompact` 极简组件
19. 集成到 `TrayPanelUnlocked` 快捷面板
20. 实现展开/收起动画效果

---

### 阶段五：国际化

21. 添加中英文文案到 `.arb` 文件
22. 运行 `flutter gen-l10n` 生成国际化代码

---

### 阶段六：测试与优化

23. 编写单元测试（覆盖率 > 90%）
24. 移动端完整流程测试
25. 桌面端完整流程测试
26. 快捷面板功能测试
27. 性能验证（生成 < 100ms、强度计算 < 50ms）
28. 添加触觉反馈
29. 完善错误提示

---

## 📊 验收标准

### 功能完整性
- ✅ 支持 8-64 字符长度配置
- ✅ 支持 4 种字符类型选择
- ✅ 支持排除易混淆字符
- ✅ 实时显示密码强度
- ✅ 配置持久化
- ✅ 三端（移动/桌面/快捷面板）全部实现

### 性能指标
- ✅ 密码生成响应 < 100ms
- ✅ 强度计算响应 < 50ms
- ✅ UI 渲染流畅（60fps）

### 用户体验
- ✅ 操作流程简洁（≤ 3 步完成生成）
- ✅ 强度指示直观易懂
- ✅ 支持一键重新生成
- ✅ 支持快速复制

### 代码质量
- ✅ 单元测试覆盖率 > 90%
- ✅ 无 Material 组件引用
- ✅ 通过 `flutter analyze`
- ✅ 符合项目架构规范

---

## 📝 后续优化方向

### v1.9.0 可能的增强
- 密码历史记录（保留最近 10 个生成的密码）
- 自定义符号集
- 密码模式预设（如"易记密码"、"极强密码"）
- 密码强度详细分析（熵值、破解时间估算）

### v2.0.0 可能的增强
- 密码生成规则模板
- 批量生成密码
- 密码强度趋势分析

---

## ❓ 常见问题

**Q1: 为什么不在列表页直接生成？**
A: 密码必须关联到某个账号，所以只在新增/编辑时提供生成功能。快捷面板提供独立生成（不保存）。

**Q2: 能否批量生成多个密码？**
A: v1.8.0 暂不支持，v2.0.0 会考虑添加。

**Q3: 生成的密码会保存历史吗？**
A: v1.8.0 会添加"密码历史记录"功能，保留最近 10 个版本。

**Q4: 能否自定义符号集？**
A: v1.8.0 使用标准符号集，v1.9.0 会考虑自定义。

---

**文档状态**: 评审通过
**责任人**: Flutter 开发团队
**最后更新**: 2026-03-06
