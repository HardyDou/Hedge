# Agent 经验总结与反思 (Lessons Learned)

## 1. 为什么 PRD 中已有的功能未被完整实现？

在 NotePassword 的第一阶段研发中，虽然 PRD 明确要求了“数据导入”、“搜索”等功能，但在实际开发过程中出现了遗漏。

### 经验总结：
*   **研发冲刺（Sprint）目标过窄**：作为 Agent，在执行“继续”或“下一步”指令时，往往倾向于优先构建“最小闭环”（MVP中的MVP），即增删改查的基础链路。这导致了 PRD 中定义的其他 P0 级功能（如导入、搜索）被推迟到了“未来”。
*   **缺乏 Checklist 强约束**：在开发过程中，没有将 PRD 拆解为一份可追踪的 Task List 并逐项对比。
*   **状态管理惯性**：在实现 UI 时，容易陷入“先跑通界面”的思维，而忽略了复杂的交互（如完整录入表单、国际化配置）。

## 2. 改进对策
*   **任务开始前强制对齐 PRD**：在每个阶段性任务开始前，必须重新扫描 PRD 的 `Functional Requirements` 章节，并在 `TodoWrite` 工具中显式列出所有涉及的功能点。
*   **模块化验证**：每个功能模块（如 Crypto, UI, Sync）完成后，应进行交叉检查。
*   **国际化优先**：所有新功能开发时，必须同步创建 ARB 键值对，避免后期重构压力。
*   **UI/UX 细节同步执行**：搜索、主题切换等核心交互功能应与列表功能同步实现，而非作为补丁。

---

## 3. 针对用户反馈的技术反思

### 3.1 模拟器生物识别失效
*   **原因**：iOS Simulator 默认不开启 FaceID 模拟。
*   **解决**：需要在虚拟机运行后，手动执行 `Features -> Face ID -> Enrolled`。

### 3.2 国际化 (i18n) 优先级
*   **教训**：在架构设计初期就应引入 `flutter_localizations`，否则后期重构所有硬编码字符串成本较高。

### 3.3 导入功能的复杂性
*   **分析**：1Password 导出的 `.1pux` 是一个包含加密 JSON 的压缩包，处理逻辑较重，应放入 Rust Core 中完成解析。

---

## 4. 本次会话开发记录 (Session Log 2026-02-26)

### 4.1 代码修复
*   **detail_page.dart**: 修复语法错误 (缺失 `)`, 错误的 `IconButton` 嵌套)

### 4.2 UI 优化
*   **edit_page.dart**: 按 iOS 设计规范重新设计，分组样式、圆角卡片
*   **add_item_page.dart**: 参考 edit_page 调整，保持一致的 iOS 风格
*   **detail_page.dart**:
  *   密码右侧功能按钮紧凑化 (32x32, 18px 图标)
  *   放大显示改为弹窗对话框 (不再横屏)
  *   使用 `TextPainter` 可靠检测密码是否超出屏幕宽度，自动切换横/竖向显示

### 4.3 功能改进
*   **URL 解析优化**: 支持不带 `http(s)://` 前缀的 URL 自动补全，确保 favicon 图标正常下载

### 4.4 多平台本地化
*   **iOS**: 创建 `Base.lproj/InfoPlist.strings` (英文) 和 `zh-Hans.lproj/InfoPlist.strings` (中文)
*   **Android**: 创建 `values/strings.xml` 和 `values-zh-rCN/strings.xml`
*   **macOS**: 同 iOS 结构
*   应用名称根据系统语言自动切换 ("密码本" / "Password Vault")

### 4.5 文档整理
*   删除多余的 review/approval 文档
*   合并 Build_Guide.md 到 Architecture_Design.md
*   移动 agent.md 到项目根目录

---

## 5. 国际化键值 (i18n Keys)

新增键值：
*   `basicInfo`: 基本信息
*   `titleHint`: 例如：Gmail、Netflix
*   `usernameHint`: 用户名或邮箱
*   `passwordHint`: 密码
*   `notesHint`: 备注信息...
*   `noAttachments`: 暂无附件
*   `vertical`: 纵向
*   `horizontal`: 横向
*   `copied`: 已复制
*   `copyPassword`: 复制密码

---

## 6. 密码全屏放大页面 (LargePasswordPage)

### 最终实现方案
使用 `SystemChrome.setPreferredOrientations` 真正旋转屏幕，而非模拟横屏。

**功能：**
- 点击放大按钮 → 进入全屏页面（竖屏）
- 点击旋转按钮 → 屏幕真正横过来
- 退出时 → 先恢复竖屏再退出，体验更平滑
- 横向模式时隐藏 AppBar 标题

**按钮：**
- 旋转屏幕按钮：切换横竖屏方向
- 复制密码按钮：一键复制

**布局：**
- 标题在上、密码在中间、按钮在下
- 每个字符 + 位号 上下结构显示
- 字符隔位换色

---

## 7. 密码详情页按钮优化

**优化内容：**
- 按钮统一为 28x28 大小
- 添加垂直居中对齐 `crossAxisAlignment: CrossAxisAlignment.center`
- 使用 `constraints: const BoxConstraints()` 移除额外间距
- 统一使用 iOS 蓝色 (0xFF007AFF)
- 统一图标大小为 18px

---

## 8. 接下来的计划 (Next Steps)

### P0 待完成
1. ~~**iCloud 同步**~~ ✅
2. ~~**数据导入优化**~~ ✅
3. ~~**生物识别优化**~~ ✅ (修复闪退问题)
4. ~~**批量删除**~~ ✅
5. ~~**自动锁屏修复**~~ ✅

### P1 计划
6. **Linux 构建验证**：测试 Linux 平台构建
7. **密码历史记录**：查看密码修改历史
8. **本地定期备份**：自动备份功能

### 长期规划
9. **WebDAV 同步协议支持**
10. **TOTP/2FA 验证码生成器**
11. **Passkeys 支持**

---

## 9. 会话记录 (2026-02-27)

### 9.1 iCloud 同步功能
- 实现文件监听机制（Timer 轮询）
- 自动检测远程变更并刷新
- 冲突检测与备份

### 9.2 数据导入优化
- 智能检测 CSV 是否包含表头
- 支持无表头 CSV（按顺序解析）
- 导入结果显示成功/失败数量

### 9.3 批量删除功能
- 右上角添加删除按钮
- 选择模式：点击项目勾选
- 弹窗确认后批量删除

### 9.4 密码全屏放大
- 使用 `SystemChrome` 真正旋转屏幕
- 横屏模式：隐藏标题、内容旋转 90°
- 按钮在底部，文字方向适配

### 9.5 生物识别优化
- 移除自动触发生物识别（用户手动点击）
- 增加异常处理避免闪退

### 9.6 动画预热
- 添加 `SystemChannels` 预热修复首次点击无动画问题

### 9.7 自动锁屏修复
- 使用 `AppLifecycleState.paused` 立即检查超时
- 确保按 Home 键时正确锁定
