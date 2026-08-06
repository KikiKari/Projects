@echo off
chcp 65001 >nul
title TikTok Live Companion - Monitor
cd /d "%~dp0"

echo ============================================================
echo   TikTok Live Companion - Monitor wird gestartet
echo ============================================================
echo.

where python >nul 2>&1
if errorlevel 1 (
  echo FEHLER: Python wurde nicht gefunden.
  echo Installiere Python von https://www.python.org/downloads/
  echo Wichtig: beim Installieren "Add python.exe to PATH" ankreuzen.
  echo.
  pause
  exit /b 1
)

echo Python gefunden. Starte Monitor auf http://127.0.0.1:8765
echo.
echo   - Reiter TikTok  : laeuft gerade / seit wann / letzte Sendungen
echo   - Reiter Live    : Telegram-Verlauf
echo   - Benachrichtigung beim Livegang laeuft im Hintergrund mit
echo.
echo Fenster offen lassen. Beenden mit Strg+C.
echo ============================================================
echo.

start "" http://127.0.0.1:8765
python server.py --poll-interval 120 --no-browser

echo.
echo Monitor beendet.
pause
