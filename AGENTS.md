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

## 5. 参考资源

### 官方文档
- [Flutter 官方文档](https://flutter.dev/docs)
- [Cupertino 组件库](https://api.flutter.dev/flutter/cupertino/cupertino-library.html)
- [Riverpod 文档](https://riverpod.dev/)

### 项目文档
- `docs/Plan.md` - 产品路线图
- `docs/PRD.md` - 产品需求 + UI/UX 规范
- `docs/Architecture.md` - 技术架构 + 实现细节
- `docs/plan-*.md` - 排期计划

---

**最后更新**: 2026-03-06
**维护者**: Hedge Team
