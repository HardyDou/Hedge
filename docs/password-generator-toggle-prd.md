# Product Requirements Document: 密码生成器 Toggle 模式重构

**Version**: 1.0
**Date**: 2026-03-10
**Author**: Sarah (Product Owner)
**Quality Score**: 92/100

---

## Executive Summary

当前密码生成器使用"精确数量控制"模式——用户通过滑块分别设置数字数量和符号数量。这种设计对普通用户认知负担过高：大多数人只关心"要不要包含数字/符号"，而不是"要几个"。

本次重构将配置界面简化为 **Toggle 开关模式**：用户设置总长度，通过开关决定是否包含数字和符号，系统自动保证至少 1 个对应字符。这与 Hedge 的品牌理念"安全、简洁、可信"高度一致，也符合 Things 3 风格的极简 Cupertino 设计方向。

---

## Problem Statement

**Current Situation**: 配置区有两个滑块（数字数量、符号数量），用户需要理解"数量"的概念，且滑块在某些边界条件下会显示"已达上限"的禁用状态，造成困惑。

**Proposed Solution**: 用两个 `CupertinoSwitch` 替换两个滑块，分别控制"是否包含数字"和"是否包含符号"。开关开启时，生成算法保证至少 1 个对应字符随机分布在密码中。

**Business Impact**: 降低用户学习成本，减少配置操作步骤，提升密码生成器的使用频率。

---

## Success Metrics

**Primary KPIs:**
- 配置区交互步骤从 3 步（滑块拖动）减少到 1 步（toggle 点击）
- 消除"已达上限"等边界状态的 UI 异常
- 旧用户配置 100% 无损迁移，无需用户手动重新配置

---

## User Personas

### Primary: 隐私意识强的技术用户
- **Role**: 在多设备（Mac + 手机）上使用 Hedge 的开发者/技术人员
- **Goals**: 快速生成符合网站要求的强密码，不想思考"几个数字"这种细节
- **Pain Points**: 当前滑块需要多次拖动，且数字/符号数量之间有互相约束，容易触发禁用状态
- **Technical Level**: 中高级，但期望工具本身足够简单

---

## User Stories & Acceptance Criteria

### Story 1: 开关控制字符类型

**As a** 用户
**I want to** 通过开关决定密码是否包含数字和符号
**So that** 我不需要思考具体数量，只需表达意图

**Acceptance Criteria:**
- [ ] 配置区显示"数字"和"符号"两个 CupertinoSwitch 行
- [ ] 开关开启时，生成的密码中至少包含 1 个对应字符
- [ ] 开关关闭时，生成的密码中不包含对应字符
- [ ] 两个开关均关闭时，密码仅由大小写字母组成
- [ ] 任意开关状态变化后，立即重新生成密码

### Story 2: 长度控制保持不变

**As a** 用户
**I want to** 继续使用 Stepper（+/-）控制密码长度
**So that** 我可以精确控制密码总长度

**Acceptance Criteria:**
- [ ] 长度范围保持 8-64
- [ ] 默认长度为 16
- [ ] 长度变化后立即重新生成密码

### Story 3: 旧配置自动迁移

**As a** 已有用户
**I want to** 升级后我的配置偏好被保留
**So that** 我不需要重新配置

**Acceptance Criteria:**
- [ ] `numbersCount > 0` → 数字开关 ON
- [ ] `numbersCount == 0` → 数字开关 OFF
- [ ] `symbolsCount > 0` → 符号开关 ON
- [ ] `symbolsCount == 0` → 符号开关 OFF
- [ ] 迁移后立即保存新格式配置，不再触发迁移逻辑

### Story 4: 默认配置

**As a** 新用户
**I want to** 打开密码生成器时有合理的默认配置
**So that** 我无需任何配置即可生成强密码

**Acceptance Criteria:**
- [ ] 默认长度：16
- [ ] 默认数字开关：ON
- [ ] 默认符号开关：ON
- [ ] 默认排除易混淆字符：OFF

---

## Functional Requirements

### 核心功能变更

**Feature 1: PasswordGeneratorConfig 模型重构**
- 移除 `numbersCount: int` 和 `symbolsCount: int`
- 新增 `includeNumbers: bool`（默认 `true`）
- 新增 `includeSymbols: bool`（默认 `true`）
- 保留 `length: int` 和 `excludeAmbiguous: bool`
- 更新 `defaultConfig()` 工厂方法

**Feature 2: PasswordGeneratorService 生成逻辑**
- `includeNumbers: true` → 先放入 1 个随机数字，剩余位置从全字符集随机填充
- `includeSymbols: true` → 先放入 1 个随机符号，剩余位置从全字符集随机填充
- 两者均开启 → 先各放 1 个（共 2 个保证字符），剩余从合并字符集随机填充
- 最终结果打乱顺序（`shuffle`）
- 移除 `totalRequired > length` 的数量校验逻辑

**Feature 3: PasswordGeneratorConfigService 迁移**
- 检测旧格式（含 `numbersCount`/`symbolsCount` 字段）时执行迁移：
  - `numbersCount > 0` → `includeNumbers: true`
  - `symbolsCount > 0` → `includeSymbols: true`
- 移除 `_clampConfig` 方法（新模型不需要数量约束）

**Feature 4: UI 更新（移动端 Sheet + 桌面端 Popover）**
- 移除数字滑块和符号滑块
- 新增"数字 (0-9)"CupertinoSwitch 行
- 新增"符号 (!@#$...)"CupertinoSwitch 行
- 保留长度 Stepper 行
- 保留"排除易混淆字符"Switch 行
- 配置区行顺序：长度 → 数字 → 符号 → 排除易混淆

### Out of Scope
- 不新增"大写字母"和"小写字母"的独立开关（始终包含大小写）
- 不提供精确数量控制（移除滑块后不保留任何数量调节入口）
- 不修改密码强度计算逻辑

---

## Technical Constraints

### 数据模型变更
```dart
// 新模型
PasswordGeneratorConfig({
  required int length,           // 8-64，默认 16
  @Default(true) bool includeNumbers,
  @Default(true) bool includeSymbols,
  @Default(false) bool excludeAmbiguous,
})
```

### 生成算法伪代码
```
guaranteed = []
if includeNumbers: guaranteed.add(randomFrom(numberCharset))
if includeSymbols: guaranteed.add(randomFrom(symbolCharset))

fullCharset = letterCharset
if includeNumbers: fullCharset += numberCharset
if includeSymbols: fullCharset += symbolCharset

remaining = length - guaranteed.length
for i in remaining: guaranteed.add(randomFrom(fullCharset))

return shuffle(guaranteed).join()
```

### 迁移策略
- 旧格式检测条件：JSON 中含 `numbersCount` 或 `symbolsCount` 字段
- 迁移后立即以新格式覆盖保存
- 无法解析时回退到 `defaultConfig()`

### 需要更新的文件
| 文件 | 变更类型 |
|------|---------|
| `lib/domain/models/password_generator_config.dart` | 字段重构 |
| `lib/domain/models/password_generator_config.freezed.dart` | 重新生成 |
| `lib/domain/models/password_generator_config.g.dart` | 重新生成 |
| `lib/domain/services/password_generator_service.dart` | 生成逻辑重写 |
| `lib/domain/services/password_generator_config_service.dart` | 迁移逻辑更新 |
| `lib/presentation/widgets/password_generator_sheet.dart` | 移除滑块，添加 toggle |
| `lib/presentation/widgets/password_generator_popover.dart` | 移除滑块，添加 toggle |
| `test/password_generator_service_test.dart` | 更新测试用例 |
| `test/password_generator_sheet_test.dart` | 更新测试用例 |

---

## MVP Scope & Phasing

### Phase 1: MVP（本次交付）
- PasswordGeneratorConfig 模型重构（freezed 重新生成）
- PasswordGeneratorService 生成逻辑更新
- PasswordGeneratorConfigService 迁移逻辑更新
- 移动端 Sheet UI 更新
- 桌面端 Popover UI 更新
- 测试用例更新

### Future Considerations
- 若用户反馈需要精确控制，可考虑在 toggle 旁增加数量 badge（点击展开 stepper）
- 大写/小写独立开关（目前不在范围内）

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 旧配置迁移失败导致用户配置丢失 | Low | Medium | 迁移失败时回退 defaultConfig，不抛出异常 |
| freezed 重新生成后 JSON key 变化导致反序列化失败 | Medium | Medium | 在 ConfigService 中明确处理新旧两种 JSON 格式 |
| 测试用例未覆盖新的边界条件 | Medium | Low | 更新测试：两开关均关闭、仅一个开启、长度=8 时的最小保证字符 |

---

*This PRD was created through interactive requirements gathering with quality scoring to ensure comprehensive coverage of business, functional, UX, and technical dimensions.*
