# 参与贡献

感谢你对 **轻记账 Windows 桌面端** 的关注！本仓库是个人记账软件电脑端先行版本，核心层（`lib/core/`）预留与手机端共用，欢迎 Issue 与 Pull Request。

## 开始之前

1. 阅读 [README.md](README.md) 了解项目定位与运行方式
2. 阅读 [docs/目录结构.md](docs/目录结构.md) 熟悉目录规范
3. 仓库根目录的 [.cursorrules](.cursorrules) 与 [.cursor/rules/project.mdc](.cursor/rules/project.mdc) 描述了技术栈与强制约束（Flutter + Riverpod + SQLite，禁止换栈）

## 环境准备

| 工具 | 说明 |
|------|------|
| Flutter SDK | 含 Desktop 支持，`flutter doctor` 无严重错误 |
| Visual Studio 2022 | Windows 原生编译（「使用 C++ 的桌面开发」工作负载） |
| Git | 克隆与提交 |

```powershell
git clone https://github.com/agentai2026/Accounting-book-Windows.git
cd Accounting-book-Windows
flutter pub get
powershell -ExecutionPolicy Bypass -File tool\generate_icons.ps1
flutter run -d windows
```

## 开发约定

### 分支

- 从 `main` 拉取最新代码后创建功能分支，例如 `feat/budget-export`、`fix/statistics-scroll`
- 一个 PR 只做一件事，便于审查

### 代码规范（摘要）

- **状态管理**：仅使用 Riverpod；页面用 `ConsumerWidget` / `ConsumerStatefulWidget`
- **数据库**：仅通过 DAO 层访问，禁止在 UI 或 Provider 中直接 `openDatabase`
- **核心层**：`lib/core/` 不得引入桌面端特有包
- **模型**：必须含 `updatedAt` 字段；金额、日期使用 `money_utils` / `date_utils` 统一格式化
- **命名**：文件 `snake_case.dart`，类 `UpperCamelCase`

### 提交信息

```
type(scope): subject

type: feat | fix | docs | style | refactor | test | chore
scope: core | db | ui | sync | export
```

示例：`feat(ui): 添加账单列表表格视图`

## 测试与检查

提交前请在本地执行：

```powershell
flutter analyze
flutter test
```

推送后 [CI 工作流](.github/workflows/ci.yml) 会自动运行相同检查。

可选：OCR 真实图片基准测试需本地图片与 Tesseract，默认跳过：

```powershell
$env:RUN_OCR_BENCHMARK = "1"
flutter test test/core/ai/real_image_benchmark_test.dart
```

## Pull Request 流程

1. Fork 本仓库（或直接在本仓库分支开发，若已有写权限）
2. 完成改动并确保 `flutter analyze` 与 `flutter test` 通过
3. 推送分支并发起 PR，说明：
   - 改动目的
   - 如何手动验证
   - 是否涉及数据库迁移（如有，请说明版本号与脚本路径）
4. 等待 CI 绿灯后再合并

## 报告问题

[新建 Issue](https://github.com/agentai2026/Accounting-book-Windows/issues/new) 时请尽量包含：

- 操作系统与 Flutter 版本（`flutter doctor -v` 摘要）
- 复现步骤
- 期望行为 vs 实际行为
- 截图或日志（如有）

## 许可证

贡献即表示你同意在 [Apache License 2.0](LICENSE) 下授权你的改动。
