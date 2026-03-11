@echo off
chcp 65001 >nul 2>&1
echo ========================================
echo   Subtitle Packer for MKV
echo ========================================
echo.
echo Starting subtitle packing...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pack.ps1"

echo.
echo ========================================
pause
