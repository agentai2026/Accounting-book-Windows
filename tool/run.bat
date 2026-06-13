@echo off
chcp 65001 >nul
cd /d "%~dp0\.."
title 轻记账

echo.
echo  ========================================
echo    轻记账  一键启动
echo  ========================================
echo.

where flutter >nul 2>&1
if errorlevel 1 (
    echo  [错误] 未找到 Flutter
    pause
    exit /b 1
)

call flutter pub get
call flutter run -d windows
if errorlevel 1 pause
exit /b %ERRORLEVEL%
