# Product Requirements Document: 桌面版常驻图标快速访问功能

**Version**: 1.1 (评审修订版)
**Date**: 2026-03-01
**Author**: Sarah (Product Owner)
**Quality Score**: 90/100
**Review Status**: ✅ 已通过 3 位专家 3 轮评审

---

## Executive Summary

为 NotePassword（Hedge）桌面版添加**常驻图标快速访问功能**（Quick Access），用户无需打开主窗口即可通过系统托盘/菜单栏图标快速搜索和复制密码。该功能对标 1Password 的 Quick Access，旨在显著提升桌面端用户的使用效率和体验。

**核心价值：**
- **快速访问**：点击图标即可搜索和复制密码，无需打开主窗口
- **效率提升**：减少用户操作步骤，从"打开应用 → 搜索 → 复制"简化为"点击图标 → 搜索 → 复制"
- **体验对齐**：与 1Password 等行业标杆保持一致的交互体验

**预期影响：**
- 目标使用率：50% 以上的桌面端用户使用该功能
- 提升桌面端用户满意度和日活跃度
- 增强产品竞争力，缩小与 1Password 的体验差距

---

## Problem Statement

**Current Situation**:
目前 NotePassword 桌面版用户每次需要复制密码时，都必须：
1. 打开主窗口（如果未打开）
2. 在列表中搜索或滚动查找目标密码
3. 点击进入详情页
4. 复制密码
5. 关闭或最小化窗口

这个流程对于频繁使用密码的场景（如登录网站、填写表单）来说过于繁琐。

**Proposed Solution**:
添加常驻图标（系统托盘/菜单栏），点击后弹出紧凑型下拉面板，支持实时搜索和快速复制。用户可以在不打开主窗口的情况下，快速访问密码库。

**Business Impact**:
- 提升桌面端用户体验，增强产品竞争力
- 提高用户日活跃度和使用频率
- 缩小与 1Password 等竞品的功能差距

---

## Success Metrics

**Primary KPIs:**
- **首次使用率**: 50% 以上的桌面端用户在上线后 30 天内至少使用过一次常驻图标功能
- **7 日留存率**: 30% 使用过该功能的用户在首次使用后 7 天内再次使用
- **月活跃使用频率**: 活跃用户平均每月使用 10 次以上
- **用户满意度**: NPS (Net Promoter Score) > 40

**Secondary KPIs:**
- 平均每次使用的复制操作次数 > 1.5（表示用户找到了目标密码）
- 面板打开到复制完成的平均时长 < 10 秒

**Validation**:
- 通过应用内埋点统计：
  - 常驻图标点击次数
  - 面板打开次数（区分冷启动和热启动）
  - 搜索使用次数
  - 复制操作次数（区分用户名、密码、网址）
  - 用户从打开面板到复制的时长
- 收集用户反馈和满意度评分（应用内问卷 + App Store 评分）
- A/B 测试：对比使用该功能和不使用该功能的用户活跃度差异

---

## User Personas

### Primary: 桌面端重度用户

- **Role**: 开发者、设计师、产品经理等需要频繁登录各种网站和服务的用户
- **Goals**: 快速访问密码，无需打开主窗口，提升工作效率
- **Pain Points**:
  - 每次复制密码都要打开主窗口太麻烦
  - 主窗口占用屏幕空间，影响工作流
  - 希望有类似 1Password 的快速访问体验
- **Technical Level**: 中高级用户，熟悉桌面应用的常见交互模式

---

## User Stories & Acceptance Criteria

### Story 1: 常驻图标显示

**As a** 桌面端用户
**I want to** 在系统托盘/菜单栏看到 NotePassword 的常驻图标
**So that** 我可以随时快速访问密码库

**Acceptance Criteria:**
- [ ] macOS 用户在菜单栏右侧看到 NotePassword 图标
- [ ] Windows/Linux 用户在系统托盘看到 NotePassword 图标
- [ ] 图标设计与应用主图标保持一致
- [ ] 图标在应用启动后自动显示，关闭应用后自动隐藏

### Story 2: 下拉面板显示

**As a** 桌面端用户
**I want to** 点击常驻图标后弹出下拉面板
**So that** 我可以快速查看和搜索密码列表

**Acceptance Criteria:**
- [ ] 点击图标后，在图标下方弹出 360x480 的紧凑型面板
- [ ] 面板包含搜索框（高度 40px）和密码列表（高度约 400px，可滚动）
- [ ] 面板固定在图标下方，不可拖动
- [ ] 点击面板外部区域或按 ESC 键关闭面板
- [ ] 面板打开速度：热启动 < 200ms，冷启动 < 500ms
- [ ] 面板支持键盘导航：上下键选择列表项，回车键查看详情

### Story 3: 解锁机制

**As a** 桌面端用户
**I want to** 在首次点击图标时解锁密码库
**So that** 我的密码数据保持安全

**Acceptance Criteria:**
- [ ] 如果密码库已锁定，点击图标后显示解锁界面（密码输入或生物识别）
- [ ] 解锁成功后显示密码列表
- [ ] 解锁状态与主窗口共享（主窗口解锁后，面板也处于解锁状态）
- [ ] 解锁状态在一定时间后自动失效（与主窗口的自动锁定设置一致）

### Story 4: 实时搜索

**As a** 桌面端用户
**I want to** 在搜索框中输入关键词时实时过滤密码列表
**So that** 我可以快速找到目标密码

**Acceptance Criteria:**
- [ ] 搜索框位于面板顶部，占位符文本为"搜索密码..."
- [ ] 用户输入时，列表实时过滤显示匹配结果
- [ ] 搜索规则与现有密码列表搜索规则一致（支持标题、用户名、拼音搜索）
- [ ] 搜索响应时间 < 100ms（1000 条数据）
- [ ] 清空搜索框后恢复显示完整列表

### Story 5: 密码列表显示

**As a** 桌面端用户
**I want to** 在面板中看到密码列表
**So that** 我可以浏览和选择目标密码

**Acceptance Criteria:**
- [ ] 列表项显示与现有密码列表一致的信息（标题、用户名、图标等）
- [ ] 列表支持滚动（固定高度，约 300px）
- [ ] 列表按现有排序规则排序（数字优先，英文+中文按拼音混排）
- [ ] 列表为空时显示"无匹配结果"提示

### Story 6: 密码详情显示（核心功能）

**As a** 桌面端用户
**I want to** 点击列表项后查看密码详情
**So that** 我可以查看完整的密码信息并快速复制

**Acceptance Criteria:**
- [ ] 点击列表项后，列表项高亮显示
- [ ] 在面板右侧（或列表下方）显示详情区域，包含完整信息：标题、用户名、密码（隐藏）、网址、备注
- [ ] 详情区域宽度约 200px（如果面板右侧空间不足，则显示在列表下方）
- [ ] 点击其他列表项或关闭按钮隐藏详情
- [ ] 支持键盘导航：回车键显示详情，ESC 键关闭详情

### Story 7: 快速复制（核心功能）

**As a** 桌面端用户
**I want to** 在详情区域中快速复制用户名和密码
**So that** 我可以快速粘贴到需要的地方

**Acceptance Criteria:**
- [ ] 详情区域中用户名和密码字段旁边显示复制按钮
- [ ] 点击复制按钮后，内容复制到剪贴板
- [ ] 复制成功后显示"已复制"提示（Toast 或按钮状态变化）
- [ ] 密码字段默认隐藏（显示为 ••••），点击眼睛图标可切换显示/隐藏
- [ ] 支持密码放大显示（点击放大图标后，密码以更大字体显示）
- [ ] 支持键盘快捷键：Cmd/Ctrl+C 复制当前选中字段

### Story 8: 键盘导航支持（核心功能）

**As a** 桌面端用户
**I want to** 使用键盘快速导航和操作
**So that** 我可以不使用鼠标完成所有操作

**Acceptance Criteria:**
- [ ] 面板打开后，搜索框自动获得焦点（可通过设置关闭）
- [ ] 上下方向键：在列表中选择密码项
- [ ] 回车键：显示当前选中项的详情
- [ ] ESC 键：关闭详情区域或关闭面板
- [ ] Tab 键：在搜索框、列表、详情区域之间切换焦点
- [ ] Cmd/Ctrl+C：复制当前选中的字段
- [ ] Cmd/Ctrl+数字键：快速复制（1=用户名，2=密码，3=网址）

### Story 9: 与主窗口独立运行

**As a** 桌面端用户
**I want to** 下拉面板与主窗口独立运行
**So that** 我可以同时使用两者而互不影响

**Acceptance Criteria:**
- [ ] 主窗口打开时，点击常驻图标仍然显示下拉面板
- [ ] 下拉面板和主窗口可以同时显示
- [ ] 在下拉面板中的操作（如复制）不影响主窗口的状态
- [ ] 在主窗口中的操作（如编辑密码）实时同步到下拉面板

---

## Functional Requirements

### Core Features

**Feature 1: 常驻图标**
- Description: 在系统托盘（Windows/Linux）或菜单栏（macOS）显示 NotePassword 图标
- User flow:
  1. 用户启动应用
  2. 图标自动显示在系统托盘/菜单栏
  3. 用户点击图标触发下拉面板
- Edge cases:
  - 如果系统托盘/菜单栏空间不足，图标可能被隐藏（需要用户手动调整系统设置）
  - 多显示器场景下，面板应显示在图标所在显示器上
- Error handling:
  - 如果图标创建失败，应在日志中记录错误，但不影响主窗口功能

**Feature 2: 下拉面板**
- Description: 点击图标后弹出的紧凑型面板，包含搜索框和密码列表
- Technical Implementation: 使用 `window_manager` 插件创建无边框独立窗口，通过 Native API 获取图标位置并计算面板坐标
- User flow:
  1. 用户点击常驻图标
  2. 面板在图标下方弹出（如果已锁定，先显示解锁界面）
  3. 用户在搜索框中输入关键词或使用键盘导航浏览列表
  4. 用户点击列表项查看详情
  5. 用户在详情区域中复制密码
  6. 用户点击外部区域或按 ESC 关闭面板
- Edge cases:
  - 如果屏幕空间不足（如图标靠近屏幕边缘），面板位置应智能调整（优先下方，空间不足时显示在上方）
  - 如果密码库为空，显示"暂无密码"提示和引导文案
  - 多显示器场景：面板应显示在图标所在显示器上
- Error handling:
  - 如果面板创建失败，显示错误提示并记录日志
  - 如果窗口位置计算失败，使用默认位置（屏幕中心）

**Feature 3: 解锁界面**
- Description: 当密码库锁定时，显示解锁界面
- User flow:
  1. 用户点击常驻图标
  2. 如果密码库已锁定，显示解锁界面
  3. 用户输入主密码或使用生物识别解锁
  4. 解锁成功后显示密码列表
- Edge cases:
  - 如果用户连续输入错误密码 3 次，显示警告提示
  - 如果生物识别失败，回退到密码输入
- Error handling:
  - 解锁失败时显示明确的错误提示（如"密码错误"）

**Feature 4: 实时搜索**
- Description: 在搜索框中输入关键词时，列表实时过滤显示匹配结果
- User flow:
  1. 用户在搜索框中输入关键词
  2. 列表实时过滤显示匹配结果
  3. 用户继续输入或删除字符，列表持续更新
  4. 用户清空搜索框，列表恢复显示完整内容
- Edge cases:
  - 如果搜索结果为空，显示"无匹配结果"提示
  - 如果搜索关键词包含特殊字符，应正确处理
- Error handling:
  - 如果搜索过程中发生错误，显示错误提示并保持列表不变

**Feature 5: 密码详情显示**
- Description: 点击列表项后，在面板右侧或下方显示详情区域
- User flow:
  1. 用户点击列表项（或使用键盘回车键）
  2. 列表项高亮显示
  3. 在面板右侧（空间充足）或列表下方（空间不足）显示详情区域
  4. 详情区域显示完整信息和复制按钮
  5. 用户点击其他列表项或按 ESC 关闭详情
- Edge cases:
  - 如果面板宽度不足以显示右侧详情（< 560px），则显示在列表下方
  - 如果某些字段为空（如备注），不显示该字段
- Error handling:
  - 如果详情区域创建失败，记录日志但不影响列表显示

**Feature 6: 快速复制**
- Description: 在详情区域中点击复制按钮，快速复制用户名或密码
- User flow:
  1. 用户在详情区域中点击用户名或密码旁边的复制按钮（或使用键盘快捷键）
  2. 内容复制到剪贴板
  3. 显示"已复制"提示
  4. 60 秒后自动清空剪贴板（与现有功能一致）
- Edge cases:
  - 如果字段为空（如没有用户名），复制按钮应禁用或隐藏
  - 如果剪贴板权限被拒绝，显示错误提示
- Error handling:
  - 复制失败时显示明确的错误提示

**Feature 7: 键盘导航**
- Description: 支持完整的键盘导航和快捷键操作
- User flow:
  1. 面板打开后，搜索框自动获得焦点
  2. 用户使用上下键选择列表项
  3. 用户按回车键查看详情
  4. 用户使用 Tab 键在不同区域间切换焦点
  5. 用户使用快捷键快速复制
- Edge cases:
  - 如果列表为空，上下键无效
  - 如果用户在搜索框中按上下键，应移动焦点到列表
- Error handling:
  - 键盘事件处理失败时，记录日志但不影响鼠标操作

### Out of Scope (P2 功能)
- 在面板中编辑密码项
- 在面板中删除密码项
- 在面板中新建密码项
- 字母索引快速定位
- 全局键盘快捷键（如 Cmd+Shift+Space 打开面板）
- 面板尺寸自定义
- 鼠标悬停显示详情气泡（已改为点击显示）

---

## Technical Constraints

### Performance
- 面板打开速度：
  - **热启动**（应用已运行，面板已初始化）< 200ms
  - **冷启动**（首次打开面板，需要初始化 Flutter 引擎）< 500ms
- 搜索响应时间 < 100ms（1000 条数据）
- 详情区域显示延迟 < 50ms（点击后）
- 列表滚动保持 60fps
- 内存占用：面板窗口额外占用 < 100MB（独立 Flutter 实例）

### Security
- 解锁状态与主窗口共享，使用相同的 Session Key
- 面板关闭后不清空解锁状态（除非超时或用户主动锁定）
- 详情区域中的密码默认隐藏，需要用户主动点击显示
- 复制到剪贴板的密码 60 秒后自动清空

### Integration
- **系统托盘/菜单栏**:
  - macOS: 使用 `NSStatusBar` API 创建菜单栏图标
  - Windows: 使用系统托盘 API
  - Linux: 使用 AppIndicator 或系统托盘 API
- **Flutter 插件**:
  - 系统托盘：`tray_manager` (推荐) 或 `system_tray`
  - 窗口管理：`window_manager` (用于创建无边框独立窗口)
- **状态同步架构**:
  - **方案 A（推荐）**: 独立窗口 + MethodChannel/EventChannel
    - 面板是独立的 Flutter 窗口实例
    - 通过 Native 层（macOS/Windows）的单例管理共享状态
    - 状态变更通过 EventChannel 广播到所有窗口
  - **方案 B（备选）**: 单 Flutter 实例 + Overlay
    - 面板使用 Overlay 在主窗口上层显示
    - 状态直接共享，无需 IPC
    - 缺点：依赖主窗口，无法真正"独立运行"

### Technology Stack
- **Flutter**: 使用 Flutter 构建下拉面板 UI
- **系统托盘插件**: `tray_manager` (优先评估)
- **窗口管理插件**: `window_manager` (用于创建和定位独立窗口)
- **状态管理**: 复用现有的 Riverpod `VaultProvider`
- **搜索**: 复用现有的 `SearchVaultItemsUseCase`
- **UI 风格**: Cupertino 风格，与移动端保持一致

### Platform Compatibility
- **macOS**: macOS 12.0+（与主应用一致）
- **Windows**: Windows 10+
- **Linux**: Ubuntu 20.04+, Arch Linux

### Platform-Specific Considerations
- **macOS**:
  - 菜单栏图标通常左键点击显示下拉内容
  - 需要处理菜单栏图标的高亮状态
- **Windows**:
  - 系统托盘图标通常左键显示窗口，右键显示菜单
  - 需要处理任务栏通知区域的图标显示/隐藏
- **Linux**:
  - 不同桌面环境（GNOME、KDE、XFCE）的系统托盘实现不同
  - 需要充分测试兼容性

### Fallback Strategy (降级方案)
如果系统托盘/菜单栏功能在某些平台或环境下无法实现：
1. **检测机制**: 应用启动时检测系统托盘 API 是否可用
2. **降级处理**:
   - 在设置页面显示提示："您的系统不支持常驻图标功能"
   - 提供替代方案：全局快捷键打开主窗口（如 Cmd+Shift+P）
3. **用户引导**: 提供帮助文档，说明如何启用系统托盘支持（如 Linux 需要安装特定包）

---

## MVP Scope & Phasing

### Phase 1: MVP (Required for Initial Launch)
- 常驻图标显示（系统托盘/菜单栏）
- 下拉面板（360x480，紧凑型）
- 解锁机制（与主窗口共享解锁状态）
- 实时搜索
- 密码列表显示
- **键盘导航支持（核心）**
- **密码详情显示（核心）**
- **快速复制功能（核心）**
- 与主窗口独立运行
- 降级方案（系统托盘不可用时的处理）

**MVP Definition**: 用户可以通过常驻图标快速搜索和复制密码，支持完整的键盘导航，无需打开主窗口。

### Phase 2: Enhancements (Post-Launch)
- 在面板中编辑密码项
- 在面板中删除密码项
- 在面板中新建密码项
- 字母索引快速定位
- 全局键盘快捷键（如 Cmd+Shift+Space 打开面板）
- 面板尺寸自定义
- 鼠标悬停快速预览（可选的交互增强）

### Future Considerations
- 支持多密码库切换
- 支持收藏夹快速访问
- 支持最近使用记录
- 支持密码生成器
- 支持自动填充集成

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation Strategy |
|------|------------|--------|---------------------|
| 系统托盘/菜单栏插件不稳定 | Medium | High | 1. 提前评估多个插件（tray_manager, system_tray）<br>2. 如果插件不满足需求，考虑自行开发 Platform Channel<br>3. 在多个平台上充分测试<br>4. 实现降级方案（系统托盘不可用时的处理） |
| 面板位置计算错误（多显示器） | Medium | Medium | 1. 获取图标所在显示器的坐标<br>2. 计算面板位置时考虑屏幕边界<br>3. 在多显示器环境下充分测试<br>4. 提供手动调整面板位置的选项（P2） |
| 独立窗口方案内存占用过高 | Medium | Medium | 1. 评估独立 Flutter 实例的内存占用（预计 50-100MB）<br>2. 实现延迟初始化（首次点击图标时才创建窗口）<br>3. 面板关闭后考虑释放资源（需权衡启动速度） |
| 多窗口状态同步复杂度高 | High | High | 1. 采用 MethodChannel + EventChannel 方案<br>2. 通过 Native 层单例管理共享状态<br>3. 充分测试状态同步场景（编辑、删除、新建）<br>4. 如果方案 A 复杂度过高，降级到方案 B（Overlay） |
| 性能指标无法达成（冷启动） | Medium | Medium | 1. 区分冷启动和热启动性能指标<br>2. 实现面板预加载机制（应用启动时初始化）<br>3. 优化 Flutter 引擎启动速度 |
| 键盘导航与系统快捷键冲突 | Low | Low | 1. 使用标准的键盘导航快捷键（上下键、回车、ESC）<br>2. 避免使用可能与系统冲突的快捷键<br>3. 提供快捷键自定义选项（P2） |
| 用户不习惯点击显示详情 | Low | Medium | 1. 提供首次使用引导<br>2. 在列表项上显示提示文字（"点击查看详情"）<br>3. 收集用户反馈，必要时在 P2 增加悬停预览 |

---

## Dependencies & Blockers

**Dependencies:**
- **系统托盘/菜单栏插件**: 需要选择并集成合适的 Flutter 插件（预计 2-3 天）
  - 优先评估：`tray_manager` (更活跃的社区支持)
  - 备选：`system_tray` 或自行开发 Platform Channel
- **窗口管理插件**: 需要集成 `window_manager` 用于创建和定位独立窗口（预计 1-2 天）
- **现有功能复用**: 依赖现有的 VaultProvider、SearchVaultItemsUseCase、SortService（已完成）
- **技术预研**: 需要完成多窗口状态同步方案的技术验证（预计 3-5 天）

**Known Blockers:**
- 无已知阻塞项

**Pre-Development Tasks:**
1. 系统托盘插件技术预研和选型（2-3 天）
2. 多窗口状态同步方案验证（3-5 天）
3. 性能基准测试（冷启动/热启动）（1-2 天）
4. UI 设计稿评审和确认（2-3 天）

---

## Review History

### 评审记录

**第一轮评审 (2026-03-01)**
- Alex Chen (产品经理): 7.5/10 - 成功指标不够具体，缺少用户价值验证
- Maya Rodriguez (UX 设计师): 6.5/10 - 详情气泡交互存在可用性风险，面板尺寸可能不够
- David Kim (技术架构师): 7/10 - 技术实现方案不明确，状态同步架构存在风险

**第二轮评审 (2026-03-01)**
- 补充了细化的成功指标（首次使用率、7 日留存率、月使用频率）
- 重新设计交互方式：从"悬停显示气泡"改为"点击显示详情"
- 调整面板尺寸：从 320x400 改为 360x480
- 将键盘导航移入 MVP 范围
- 明确技术实现方案：独立窗口 + MethodChannel/EventChannel
- 补充降级方案和平台差异处理

**第三轮评审 (2026-03-01)**
- Alex Chen (产品经理): 8/10 - ✅ 批准
- Maya Rodriguez (UX 设计师): 8.5/10 - ✅ 批准
- David Kim (技术架构师): 8/10 - ✅ 批准

**综合评分**: 8.2/10 - ✅ **已批准，可以进入开发阶段**

---

## Appendix

### Glossary
- **常驻图标**: 系统托盘（Windows/Linux）或菜单栏（macOS）中的应用图标
- **下拉面板**: 点击常驻图标后弹出的紧凑型独立窗口
- **详情区域**: 点击列表项后显示的区域，包含完整密码信息和操作按钮
- **Quick Access**: 1Password 的快速访问功能，本功能的参考对象
- **热启动**: 应用已运行，面板已初始化，再次打开面板的场景
- **冷启动**: 首次打开面板，需要初始化 Flutter 引擎的场景
- **IPC (Inter-Process Communication)**: 进程间通信，用于多窗口状态同步

### References
- [1Password Quick Access](https://support.1password.com/quick-access/)
- NotePassword 架构设计文档: `/docs/Architecture_Design.md`
- NotePassword 产品需求文档: `/docs/PRD.md`
- Flutter window_manager 插件: [pub.dev/packages/window_manager](https://pub.dev/packages/window_manager)
- Flutter tray_manager 插件: [pub.dev/packages/tray_manager](https://pub.dev/packages/tray_manager)

### Change Log

**v1.1 (2026-03-01) - 评审修订版**
- ✅ 补充细化的成功指标（首次使用率、7 日留存率、月使用频率、NPS）
- ✅ 调整交互方式：从"悬停显示气泡"改为"点击显示详情"
- ✅ 调整面板尺寸：从 320x400 改为 360x480
- ✅ 将键盘导航移入 MVP 范围
- ✅ 明确技术实现方案：独立窗口 + MethodChannel/EventChannel
- ✅ 区分冷启动和热启动性能指标
- ✅ 补充降级方案（系统托盘不可用时的处理）
- ✅ 补充平台差异处理说明
- ✅ 更新风险评估，增加新识别的风险项
- ✅ 补充评审记录和批准状态

**v1.0 (2026-03-01) - 初始版本**
- 初始需求文档，通过需求收集和质量评分（90/100）

---

*This PRD was created through interactive requirements gathering with quality scoring, and has been reviewed and approved by 3 experts (Product Manager, UX Designer, Tech Architect) through 3 rounds of review to ensure comprehensive coverage of business, functional, UX, and technical dimensions.*
