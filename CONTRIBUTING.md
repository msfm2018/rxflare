# Contributing to rxflare

感谢你对 rxflare 的兴趣！欢迎所有形式的贡献：修复 bug、改进文档、提交示例或提出特性建议。

为让贡献流程顺畅，请按下列步骤进行：

## 一步到位（快速指南）
1. Fork 本仓库并创建分支：
```bash
git clone git@github.com:your-username/rxflare.git
cd rxflare
git checkout -b feat/my-change
```
2. 安装依赖并运行示例/测试：
```bash
flutter pub get
# 运行包的测试（若有）
flutter test
# 运行示例
cd example
flutter pub get
flutter run -d <device>
```
3. 提交代码并创建 PR：
- 保持分支名语义化（feat/、fix/、docs/、chore/）
- 单一变更一次 PR
- 在 PR 描述中说明改动目的、影响范围、如何验证

## 开发规范
- 使用 Flutter 的官方格式化：`dart format .`
- 遵守 repo 的 lint（`flutter_lints`）
- 编写或更新测试（若改动影响行为）
- 尽量保持 API 向后兼容，若不兼容请在 PR 中说明并更新 CHANGELOG

## 本地调试建议
- 使用 `example/` 目录里的示例来验证 UI 行为
- 若改动核心模块（如 rx_state、computed、rx_event_bus），补充单元测试验证预期逻辑

## PR 检查清单（提交 PR 前）
- [ ] 代码通过 `dart analyze`
- [ ] 代码通过 `dart format` 且风格一致
- [ ] 添加/更新相应测试（如适用）
- [ ] 更新文档（README 或 docs/）

## 贡献者守则
请遵循仓库的 [行为准则](CODE_OF_CONDUCT.md)。在互动中保持礼貌和建设性讨论。

---

# Contributing to rxflare (EN)

Thanks for your interest in rxflare! Contributions are welcome — bug fixes, docs, examples, and feature requests.

Quick steps:
1. Fork and branch:
```bash
git clone git@github.com:your-username/rxflare.git
cd rxflare
git checkout -b feat/my-change
```
2. Prepare and run:
```bash
flutter pub get
flutter test
cd example
flutter pub get
flutter run -d <device>
```
3. Open a PR with a clear description and test instructions.

Development:
- Format with `dart format .`
- Follow `flutter_lints`
- Prefer small, focused PRs
- Update CHANGELOG for breaking changes

Checklist before PR:
- [ ] dart analyze succeeds
- [ ] Code formatted
- [ ] Tests added/updated
- [ ] Documentation updated

If you'd like help picking a starter issue, look for `good first issue` labeled issues.
