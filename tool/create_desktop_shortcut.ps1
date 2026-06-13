# Create desktop shortcut for QingJiZhang launcher
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$launcher = Get-ChildItem -LiteralPath $root -Filter '*.bat' -File |
  Where-Object { $_.Directory.FullName -eq $root } |
  Select-Object -First 1 -ExpandProperty FullName
if (-not $launcher) {
  Write-Host 'Launcher bat not found in project root.' -ForegroundColor Red
  exit 1
}

$desktop = [Environment]::GetFolderPath('Desktop')
$linkName = -join ([char]0x8F7B, [char]0x8BB0, [char]0x8D26) + '.lnk'
$shortcutPath = Join-Path $desktop $linkName

$shell = New-Object -ComObject WScript.Shell
$shortcut = $shell.CreateShortcut($shortcutPath)
$shortcut.TargetPath = $launcher
$shortcut.WorkingDirectory = $root
$shortcut.WindowStyle = 1
$iconPath = Join-Path $root 'windows\runner\resources\app_icon.ico'
if (Test-Path -LiteralPath $iconPath) {
  $shortcut.IconLocation = "$iconPath,0"
}
$shortcut.Description = 'QingJiZhang Desktop'
$shortcut.Save()

Write-Host ''
Write-Host "Shortcut: $shortcutPath" -ForegroundColor Green
Write-Host ''
