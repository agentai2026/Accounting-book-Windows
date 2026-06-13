# QingJiZhang launcher (ASCII-only, avoids PowerShell encoding issues)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location -LiteralPath $root

Write-Host ''
Write-Host '  QingJiZhang - Launching...' -ForegroundColor Cyan
Write-Host "  Project: $root"
Write-Host ''

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  Write-Host '  ERROR: flutter not found in PATH' -ForegroundColor Red
  exit 1
}

& flutter pub get
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

& flutter run -d windows
exit $LASTEXITCODE
