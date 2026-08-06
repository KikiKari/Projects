@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0TelegramMonitorCompanion.ps1" -Stop
timeout /t 2 >nul
