# 轻记账 · Windows 桌面端

[![CI](https://github.com/agentai2026/Accounting-book-Windows/actions/workflows/ci.yml/badge.svg)](https://github.com/agentai2026/Accounting-book-Windows/actions/workflows/ci.yml)

个人记账软件电脑端（Flutter Desktop + SQLite），数据本地优先，核心层预留手机端复用。

仓库：[agentai2026/Accounting-book-Windows](https://github.com/agentai2026/Accounting-book-Windows)

## 环境要求

- [Flutter SDK](https://docs.flutter.dev/get-started/install)（含 Desktop 支持）
- Windows 10/11（当前主要开发平台）
- Visual Studio 2022（含「使用 C++ 的桌面开发」工作负载，用于 Windows 原生编译）

```powershell
flutter doctor
flutter config --enable-windows-desktop
```

## 克隆与运行

```powershell
git clone https://github.com/agentai2026/Accounting-book-Windows.git
cd Accounting-book-Windows
flutter pub get
powershell -ExecutionPolicy Bypass -File tool\generate_icons.ps1
flutter run -d windows
```

- 也可双击项目根目录的 `启动.bat`（若存在）
- 详细命令见 [启动命令](启动命令)

## 生成代码（模型变更后）

```powershell
dart run build_runner build --delete-conflicting-outputs
```

## Windows 发布包

```powershell
powershell -ExecutionPolicy Bypass -File scripts\build_windows_release.ps1
```

预编译包见 [Releases](https://github.com/agentai2026/Accounting-book-Windows/releases)（推送 `v*` 标签时自动构建 Windows 安装目录压缩包）。

## 参与贡献

请参阅 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 数据目录

`%USERPROFILE%\Documents\ezbookkeeping\`（本地 SQLite，不上传云端）

## 文档

- [docs/目录结构.md](docs/目录结构.md)
- [docs/项目说明文档.md](docs/项目说明文档.md)

## 许可证

[Apache License 2.0](LICENSE)
