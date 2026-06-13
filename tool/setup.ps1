# 轻记账 Desktop 项目初始化脚本
# 前提：已安装 Flutter SDK 并配置到 PATH

$ErrorActionPreference = "Stop"

Write-Host "==> 检查 Flutter 环境..." -ForegroundColor Cyan
flutter --version

Write-Host "==> 生成桌面端平台文件..." -ForegroundColor Cyan
flutter create --org=com.ezbookkeeping --project-name=ezbookkeeping_desktop --platforms=windows,linux,macos .

Write-Host "==> 安装依赖..." -ForegroundColor Cyan
flutter pub get

Write-Host "==> 运行代码分析..." -ForegroundColor Cyan
flutter analyze

Write-Host ""
Write-Host "初始化完成！运行项目：" -ForegroundColor Green
Write-Host "  flutter run -d windows" -ForegroundColor Yellow
