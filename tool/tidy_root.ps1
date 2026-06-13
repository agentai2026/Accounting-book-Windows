# 在 Windows 资源管理器中隐藏 Flutter 开发缓存（不影响编译）
$ErrorActionPreference = 'SilentlyContinue'
$root = Split-Path -Parent $PSScriptRoot

$targets = @('.dart_tool', 'build', '.idea', '.metadata', '.flutter-plugins-dependencies')
foreach ($name in $targets) {
  $path = Join-Path $root $name
  if (Test-Path -LiteralPath $path) {
    (Get-Item -LiteralPath $path -Force).Attributes = `
      (Get-Item -LiteralPath $path -Force).Attributes -bor [IO.FileAttributes]::Hidden
  }
}
Get-ChildItem -LiteralPath $root -Filter '*.iml' -Force | ForEach-Object {
  $_.Attributes = $_.Attributes -bor [IO.FileAttributes]::Hidden
}

Write-Host ''
Write-Host '  已隐藏: .dart_tool  build  .metadata  .flutter-plugins-dependencies'
Write-Host '  恢复显示: tool\show_dev_folders.bat'
Write-Host ''
