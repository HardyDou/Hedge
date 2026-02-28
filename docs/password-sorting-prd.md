# Product Requirements Document: 密码列表排序与字母索引

**Version**: 1.0
**Date**: 2026-02-28
**Author**: NotePassword Team
**Status**: Draft

---

## Executive Summary

本需求旨在提升 NotePassword 密码列表的用户体验，通过实现统一的排序规则（0-9-A-Z，中文按拼音）和在移动端添加字母索引栏（类似 iOS 通讯录），让用户能够快速定位目标密码条目。

这是提升"原生体验"的重要优化，参照了 1Password 等主流密码管理器的交互模式。

---

## Problem Statement

### Current Situation
- 当前密码列表按创建时间/修改时间排序，用户难以快速找到目标密码
- 列表较长时，滚动查找效率低
- 缺少快速导航机制

### Proposed Solution
- 实现统一排序：数字 0-9 → 字母 A-Z → 中文按拼音
- 移动端右侧添加可拖动的字母索引栏，支持快速跳转

### Business Impact
- 提升用户查找密码效率，预计减少 30-50% 的滚动时间
- 优化原生体验，缩小与 1Password 的体验差距

---

## Success Metrics

### Primary KPIs
- **列表定位时间**: 用户从打开列表到找到目标密码的平均时间 < 3秒
- **字母索引使用率**: 有 >30% 的用户在 50+ 密码时使用索引功能
- **排序性能**: 1000 条数据排序 < 100ms

### Validation
- 通过用户测试和埋点数据分析

---

## User Personas

### Primary: 隐私敏感的多设备用户
- **Role**: 普通消费者，拥有 50-200 个密码
- **Goals**: 快速找到需要的密码，享受原生流畅体验
- **Pain Points**: 列表长时滚动麻烦，找密码耗时
- **Technical Level**: Intermediate

---

## User Stories & Acceptance Criteria

### Story 1: 密码列表排序

**As a** 用户
**I want to** 密码按标题首字符统一排序（数字→字母→拼音）
**So that** 我能快速定位目标密码

**Acceptance Criteria:**
- [ ] 数字开头的标题（如 "12306"）排在最前面
- [ ] 英文字母开头的标题按 A-Z 顺序排列
- [ ] 中文标题按拼音字母顺序排列（如"银行"在"测试"前面）
- [ ] 排序在列表加载时自动应用，无需用户操作
- [ ] 排序结果持久化（每次打开列表都保持一致顺序）

### Story 2: 移动端字母索引栏

**As a** 移动端用户
**I want to** 通过右侧字母索引快速跳转到指定位置
**So that** 无需大量滚动即可找到目标密码

**Acceptance Criteria:**
- [ ] 右侧显示 A-Z + # 的垂直索引条
- [ ] 手指触摸索引时显示对应的字母覆盖层（放大镜效果）
- [ ] 拖动索引时列表实时滚动到对应位置
- [ ] 索引只在密码数量 >= 20 时显示（避免小列表拥挤）
- [ ] 索引支持滑动手势（快速扫过多个字母）

### Story 3: 桌面端排序

**As a** 桌面端用户
**I want to** 密码按字母顺序排列
**So that** 我能快速找到目标密码

**Acceptance Criteria:**
- [ ] 桌面端密码列表自动按统一规则排序
- [ ] 桌面端不需要字母索引（屏幕空间大，可直接滚动）

---

## Functional Requirements

### Core Features

#### Feature 1: 统一排序引擎
- 实现 SortService，支持 Comparator 接口
- 排序规则：数字(0-9) → 字母(A-Z) → 拼音中文
- 拼音排序：使用 intl package 的 Collator
- 性能要求：排序 1000 条数据 < 100ms

#### Feature 2: 移动端字母索引栏
- 使用 CustomScrollView 实现
- 索引数据源：动态生成（根据当前列表实际包含的首字符）
- 手势处理：GestureDetector
- 视觉设计：跟随系统深色/浅色模式
- 索引项：A, B, C, ..., Z, #（# 代表数字和非字母开头）

#### Feature 3: 桌面端排序
- 复用移动端的排序逻辑
- 保持现有的 ListView 布局

### Out of Scope
- TOTP/2FA 列表的排序（后续单独处理）
- 文件夹/标签的排序
- 搜索结果的排序（搜索结果保持原顺序）
- 排序开关选项（MVP 阶段默认开启）

---

## Technical Constraints

### Performance
- **排序性能**: 1000 条数据排序 < 100ms
- **索引响应**: 手势触发到列表滚动 < 16ms (60fps)
- **内存**: 不额外存储排序后的列表，复用原数据

### Security
- 排序不影响数据加密和安全性

### Integration
- **依赖包**: 需要添加 `intl` package 用于拼音排序
- **现有代码**: 需要修改 VaultProvider 的 items Getter

### Technology Stack
- **Flutter**: Cupertino widgets
- **Package**: `intl` (for Chinese pinyin sorting)
- **Platform**: iOS, Android (移动端字母索引), macOS, Windows, Linux (桌面端仅排序)

---

## MVP Scope & Phasing

### Phase 1: MVP (本次开发)
- [x] 密码列表按统一规则排序（数字→字母→拼音）
- [x] 移动端字母索引栏实现
- [x] 桌面端排序实现

### Phase 2: Enhancements (Post-Launch)
- [ ] 索引使用率埋点分析
- [ ] 根据使用数据优化索引触发阈值
- [ ] 字母索引的 VoiceOver/TalkBack 支持

### Future Considerations
- 文件夹/标签的独立排序
- 按用户名排序的选项

---

## Risk Assessment

| Risk | Probability | Impact | Mitigation Strategy |
|------|------------|--------|---------------------|
| 拼音排序性能问题 | Low | Medium | 使用 intl Collator，必要时缓存排序结果 |
| 字母索引手势冲突 | Medium | Low | 使用 GestureDetector.excludeFromSemantics 避免冲突 |
| 排序导致列表闪烁 | Low | Medium | 使用 const constructor 或 key 避免重建 |

---

## Dependencies & Blockers

### Dependencies
- `intl` package: 需要添加到 pubspec.yaml

### Known Blockers
- 无

---

## Appendix

### Glossary
- **拼音排序**: 根据中文词汇的拼音字母顺序排列
- **字母索引**: 屏幕右侧的可交互索引条，支持快速滚动定位

### References
- iOS Contacts App - 字母索引交互参考
- 1Password Mobile - 密码列表交互参考
