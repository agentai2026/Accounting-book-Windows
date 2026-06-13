# 轻记账 Windows 发布包构建脚本
# 用法：在项目根目录执行  powershell -ExecutionPolicy Bypass -File scripts\build_windows_release.ps1

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $projectRoot

Write-Host '==> flutter pub get' -ForegroundColor Cyan
flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '==> flutter test' -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host '==> flutter build windows --release' -ForegroundColor Cyan
Write-Host '    提示：请先关闭正在运行的轻记账 / flutter run 终端，否则可能因文件占用失败。' -ForegroundColor DarkGray
flutter build windows --release
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host '构建失败常见原因：' -ForegroundColor Yellow
    Write-Host '  1. 应用或 flutter run 仍占用 build / .dart_tool 目录 — 全部退出后重试'
    Write-Host '  2. 项目路径含中文时 MSBuild 偶发编码错误 — 可改用纯英文路径，例如：'
    Write-Host '     subst Z: "' + $projectRoot + '"'
    Write-Host '     然后在 Z: 下执行本脚本'
    exit $LASTEXITCODE
}

$versionLine = Select-String -Path 'pubspec.yaml' -Pattern '^version:\s*(.+)$' | Select-Object -First 1
$version = '0.1.0'
if ($versionLine) {
    $version = ($versionLine.Matches.Groups[1].Value -split '\+')[0].Trim()
}

$sourceDir = Join-Path $projectRoot 'build\windows\x64\runner\Release'
if (-not (Test-Path $sourceDir)) {
    Write-Error "未找到 Release 目录: $sourceDir"
}

$distRoot = Join-Path $projectRoot 'dist'
$outDir = Join-Path $distRoot "ezbookkeeping-$version-windows-x64"

if (Test-Path $outDir) {
    Remove-Item $outDir -Recurse -Force
}
New-Item -ItemType Directory -Path $distRoot -Force | Out-Null

Write-Host "==> 复制到 $outDir" -ForegroundColor Cyan
Copy-Item -Path $sourceDir -Destination $outDir -Recurse

$zipPath = Join-Path $distRoot "ezbookkeeping-$version-windows-x64.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}
Compress-Archive -Path $outDir -DestinationPath $zipPath

Write-Host ''
Write-Host '构建完成。' -ForegroundColor Green
Write-Host "  文件夹: $outDir"
Write-Host "  压缩包: $zipPath"
Write-Host ''
Write-Host '运行方式: 双击目录中的 ezbookkeeping_desktop.exe' -ForegroundColor Green
