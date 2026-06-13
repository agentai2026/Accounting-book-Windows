# Generate Windows .ico from assets/icons/app_icon.png (standard multi-size ICO)
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host '==> dart run tool/generate_icons.dart' -ForegroundColor Cyan
dart run tool/generate_icons.dart $root
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ''
Write-Host 'Next: quit the running app (q), then  flutter run -d windows' -ForegroundColor Yellow
