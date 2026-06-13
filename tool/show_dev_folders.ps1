# 恢复显示被隐藏的 Flutter 开发缓存
$ErrorActionPreference = 'SilentlyContinue'
$root = Split-Path -Parent $PSScriptRoot

$targets = @('.dart_tool', 'build', '.idea', '.metadata', '.flutter-plugins-dependencies')
foreach ($name in $targets) {
  $path = Join-Path $root $name
  if (Test-Path -LiteralPath $path) {
    (Get-Item -LiteralPath $path -Force).Attributes = `
      (Get-Item -LiteralPath $path -Force).Attributes -band (-bnot [IO.FileAttributes]::Hidden)
  }
}
Get-ChildItem -LiteralPath $root -Filter '*.iml' -Force | ForEach-Object {
  $_.Attributes = $_.Attributes -band (-bnot [IO.FileAttributes]::Hidden)
}

Write-Host '已恢复显示开发缓存目录。'
