@echo off
chcp 65001 >nul
title Telegram Monitor - fuer das Handy freigeben
cd /d "%~dp0"

echo ============================================================
echo   Monitor im eigenen Tailnet freigeben
echo ============================================================
echo.
echo   Danach ist er unter einer https-Adresse erreichbar - nur
echo   fuer deine eigenen Geraete, nicht aus dem Internet.
echo.

where tailscale >nul 2>&1
if errorlevel 1 (
  if exist "%ProgramFiles%\Tailscale\tailscale.exe" (
    set "TS=%ProgramFiles%\Tailscale\tailscale.exe"
  ) else (
    echo FEHLER: tailscale wurde nicht gefunden.
    echo Tailscale installieren: https://tailscale.com/download/windows
    echo.
    pause
    exit /b 1
  )
) else (
  set "TS=tailscale"
)

echo Pruefe, ob der Monitor ueberhaupt laeuft ...
powershell -NoProfile -Command "try{ if((Invoke-WebRequest -Uri 'http://127.0.0.1:8765/api/status' -TimeoutSec 3 -UseBasicParsing).StatusCode -eq 200){exit 0} }catch{}; exit 1" >nul 2>&1
if errorlevel 1 (
  echo.
  echo Auf 127.0.0.1:8765 antwortet nichts.
  echo Starte zuerst "Telegram Monitor - Docker.cmd".
  echo.
  pause
  exit /b 1
)
echo Laeuft.
echo.

echo Richte die Freigabe ein ...
"%TS%" serve --bg 8765
if errorlevel 1 (
  echo.
  echo Das hat nicht geklappt. Haeufigste Ursache: In der Tailscale-Verwaltung
  echo sind HTTPS-Zertifikate noch nicht eingeschaltet.
  echo    login.tailscale.com  ^>  DNS  ^>  HTTPS Certificates  ^>  Enable
  echo MagicDNS muss ebenfalls an sein.
  echo.
  pause
  exit /b 1
)

echo.
echo ============================================================
"%TS%" serve status
echo ============================================================
echo.
echo   Diese https-Adresse auf dem Handy in Chrome oeffnen, dann
echo   Menue ^> "App installieren" bzw. "Zum Startbildschirm".
echo.
echo   In der App einmal auf "Meldungen erlauben" tippen - danach
echo   meldet sie den Livegang wie eine gewoehnliche App.
echo.
echo   Freigabe wieder aufheben:
echo      "Telegram Monitor - Handy sperren.cmd"
echo ============================================================
echo.
pause
