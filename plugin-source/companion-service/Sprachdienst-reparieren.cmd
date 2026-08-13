@echo off
setlocal EnableExtensions
title TikTok LIVE Companion - Sprachdienst reparieren
echo TikTok LIVE Companion repariert den lokalen Sprachdienst ...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0repair-service.ps1"
if errorlevel 1 goto repair_failed

echo.
echo Reparatur abgeschlossen. Im Sidepanel jetzt Sprachdienst starten anklicken.
pause
exit /b 0

:repair_failed
echo.
echo Reparatur fehlgeschlagen. Die angezeigte Fehlermeldung bitte fuer die Diagnose aufbewahren.
pause
exit /b 1
