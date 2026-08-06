@echo off
rem  Wie der normale Start, aber mit sichtbarem Serverfenster.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0TelegramMonitorCompanion.ps1" -Console
pause
