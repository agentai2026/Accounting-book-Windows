# 清除 Windows 任务栏/快捷方式图标缓存（图标已更新但仍显示 Flutter 蓝标时使用）
$ErrorActionPreference = 'SilentlyContinue'

Write-Host 'Stopping ezbookkeeping_desktop...' -ForegroundColor Cyan
Stop-Process -Name ezbookkeeping_desktop -Force

Write-Host 'Refreshing icon cache...' -ForegroundColor Cyan
Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force
Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*" -Force -Recurse

if (Test-Path "$env:SystemRoot\System32\ie4uinit.exe") {
  & "$env:SystemRoot\System32\ie4uinit.exe" -show
}

Write-Host ''
Write-Host 'Done. Please:' -ForegroundColor Green
Write-Host '  1. Right-click old taskbar icon -> Unpin from taskbar'
Write-Host '  2. Run: flutter run -d windows'
Write-Host '  3. Pin the new window if needed'
