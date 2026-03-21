# AGENTS.md - AI 开发助手操作手册

## 1. 身份与使命

你是 **Hedge（密码本）** 项目的负责人。

**核心价值观**: Local-First（本地优先）、Zero-Knowledge（零知识架构）、Native Experience（原生体验 - Cupertino）

---

## 2. 必读文档

在开始任何任务之前，**必须**先阅读项目核心文档。

### 核心文档
- **`docs/Plan.md`** - 产品路线图，当前版本功能和待实现功能
- **`docs/PRD.md`** - 产品需求文档（包含 UI/UX 规范）
- **`docs/Architecture.md`** - 技术架构和实现细节（包含国际化、安全规范） 
- **`docs/plan-*.md`** - 产品生产计划

---

## 3. 约定
### 开发计划
    - 禁止有时间概念
    - 禁止估算工时
    - 禁止给出具体时间
    - 需求大时，分阶段
    - 每个阶段，包含有序的计划

### 开发命令
```bash
# 生成代码（JSON 序列化等）
flutter pub run build_runner build --delete-conflicting-outputs

# 生成国际化文件
flutter gen-l10n

# 运行（macOS）
flutter run -d macos

# 运行（iOS 模拟器）
flutter run -d iphonesimulator
```

### 提交前必须执行的验证命令
```bash
# 静态分析（检查错误）
flutter analyze | grep -E "error"

# 运行测试
flutter test
```

---

## 4. 工作流

### 新增需求 
1. 撰写独立需求文档 plan-{计划是名称}.md 
2. 召集产品专家、用户体验大师、技术专家 进行至少3轮评审，有问题修改，直到 一致通过；
3. 产出最终的 独立需求文档 plan-{计划是名称}.md 
4. plan-{计划是名称}.md  至少包含：
    - 需求说明
    - 用户故事
    - ui、ux方案
    - 技术方案
    - 开发计划

### 开发 
1. 加载 plan-xx.md 文档
2. 按照 开发计划 制定 任务，注意先后顺序、并行关系
3. 开发 
    1. **设计数据结构**: 修改 `VaultItem` 或创建新模型
    2. **实现业务逻辑**: 在 `lib/domain/` 创建服务或用例
    3. **实现 UI**: 在 `lib/presentation/` 创建页面/组件（遵循 PRD 中的 UI/UX 规范）
    4. **添加国际化**: 修改 `.arb` 文件并运行 `flutter gen-l10n`
    5. **编写测试**: 在 `test/` 添加单元测试
    6. **验证**: 运行 `flutter analyze` 和 `flutter test`
    7. **提交**: 创建 PR，描述清楚变更内容

### 测试
1. 单元测试
2. 集成测试

### Bug 修复流程
1. **复现问题**: 确认 Bug 可复现
2. **定位代码**: 使用 `flutter run --verbose` 查看日志
3. **修复**: 修改代码
4. **验证**: 确认 Bug 已修复，没有引入新问题
5. **测试**: 添加回归测试防止再次出现
6. **提交**: 创建 PR，引用 Issue 编号

---

## 5. 设计原则

### 品牌个性
**安全、简洁、可信** — 像一个不张扬但可靠的工具，安静地做好本职工作。

### 用户情感目标
界面应让用户感到：**安全感、平静、掌控感、专业感**。

### 视觉参考
- **参考**：Things 3 — 优雅、专注、原生感，强排版层级，留白克制
- **反参考**：避免营销感重的视觉风格；避免任何 Web App 套壳感；禁止 Material Design 影响

### 设计原则
1. **Native first** — 严格遵循 Cupertino 规范，不重新发明平台模式
2. **Security is visible** — 安全 UX 要让人感到放心，而不是焦虑（密码默认隐藏、剪贴板自动清除）
3. **Calm hierarchy** — 信息分层，主要操作清晰，次要细节退后，没有东西无谓地争夺注意力
4. **Whitespace is structure** — 用间距组织内容，而非装饰元素，让内容呼吸
5. **Consistency over cleverness** — 可预测的模式建立信任，有疑问时跟随平台惯例

### 主题
深色和浅色模式同等重要，两者都要精心设计：
- 深色：`#1C1C1E` / `#2C2C2E` / `#38383A` 三层表面层级
- 浅色：`#FFFFFF` / `#F2F2F7` / `#E5E5EA` 三层表面层级

---

## 6. 版本发布约定

### 发布前必须更新的文件
当发布新版本时，必须同步更新以下文件：

| 文件 | 更新内容 |
|------|---------|
| `CHANGELOG.md` | 添加新版本 entry，列出新增/修改/修复内容 |
| `README.md` | 更新 Roadmap，标记已完成版本为 ✅ |
| `docs/产品规划.md` | 更新版本状态，更新优先级矩阵 |
| `docs/plan-*.md` | 更新对应的计划文档状态为 ✅ 已完成 |
| `AGENTS.md` | 更新"最后更新"日期 |

### 版本号规范
- **主版本号 (x.0.0)**: 重大功能或架构变更
- **次版本号 (1.x.0)**: 新功能
- **修订号 (1.0.x)**: Bug 修复

### 提交信息规范
```
feat: 新功能描述
fix: 修复描述
docs: 文档更新
chore: 构建/工具链变更
```

---

## 7. 参考资源

### 官方文档
- [Flutter 官方文档](https://flutter.dev/docs)
- [Cupertino 组件库](https://api.flutter.dev/flutter/cupertino/cupertino-library.html)
- [Riverpod 文档](https://riverpod.dev/)

### 项目文档
- `docs/产品规划.md` - 产品路线图
- `docs/PRD.md` - 产品需求 + UI/UX 规范
- `docs/Architecture.md` - 技术架构 + 实现细节
- `docs/plan-cli-foundation.md` - CLI 计划
- `docs/plan-pwd-autogen.md` - 密码生成器计划

---

## 8. Hedge CLI Skill (密码管理)

当需要操作 Hedge 密码库时，使用 hedge-cli skill。

### 安装 Skill

```bash
npx skills add HardyDou/hedge-cli-skill
```

### 构建 CLI（首次需要）

如果 CLI 未构建，自动构建：

```bash
cd /path/to/hedge
cd cli
dart pub get
dart compile exe bin/hedge.dart -o ../build/hedge
```

### 使用方式

用户说"获取密码"时，Agent 自动执行：

| 用户请求 | Agent 执行 |
|---------|-----------|
| "获取 GitHub 密码" | `hedge get github` |
| "列出所有密码" | `hedge list` |
| "搜索 AWS" | `hedge search aws` |
| "同步密码库" | `hedge sync` |
| "锁定" | `hedge lock` |

### 认证

- **生物识别**（默认）：需要 Desktop App 运行，使用 Touch ID/Face ID
- **独立模式**：`--no-app` + `HEDGE_MASTER_PASSWORD` 环境变量

---

**最后更新**: 2026-03-21
**维护者**: Hedge Team
