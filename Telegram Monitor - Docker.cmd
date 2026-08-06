@echo off
chcp 65001 >nul
title Telegram Monitor - Docker
cd /d "%~dp0"

echo ============================================================
echo   Telegram Monitor - Dauerbetrieb im Container
echo ============================================================
echo.

docker version >nul 2>&1
if errorlevel 1 (
  echo FEHLER: Docker antwortet nicht.
  echo Starte Docker Desktop und warte, bis unten links "Engine running" steht.
  echo.
  pause
  exit /b 1
)

rem  Fehlt config.json, legt Docker beim Einhaengen einen ORDNER mit diesem
rem  Namen an - danach startet der Container nicht mehr. Deshalb vorher pruefen.
if not exist "config.json" (
  echo config.json fehlt - lege sie aus der Vorlage an.
  copy /y "config.example.json" "config.json" >nul
)

echo Baue und starte den Container ...
docker compose up -d --build
if errorlevel 1 (
  echo.
  echo Der Start ist fehlgeschlagen. Ausgabe ansehen mit:
  echo    docker compose logs
  echo.
  pause
  exit /b 1
)

echo.
echo Warte, bis der Monitor antwortet ...
set /a n=0
:warten
set /a n+=1
powershell -NoProfile -Command "try{ if((Invoke-WebRequest -Uri 'http://127.0.0.1:8765/api/status' -TimeoutSec 2 -UseBasicParsing).StatusCode -eq 200){exit 0} }catch{}; exit 1" >nul 2>&1
if not errorlevel 1 goto bereit
if %n% GEQ 30 goto keineantwort
timeout /t 1 >nul
goto warten

:keineantwort
echo.
echo Keine Antwort nach 30 Sekunden. Letzte Zeilen des Protokolls:
docker compose logs --tail 20
echo.
pause
exit /b 1

:bereit
echo Antwortet.
start "" http://127.0.0.1:8765

echo.
echo ============================================================
echo   Laeuft jetzt dauerhaft auf http://127.0.0.1:8765
echo.
echo   Der Container startet nach jedem Neustart des Rechners
echo   von selbst - vorausgesetzt, in Docker Desktop ist unter
echo   Settings ^> General die Option
echo   "Start Docker Desktop when you sign in" aktiv.
echo.
echo   Zusehen  :  docker compose logs -f
echo   Anhalten :  docker compose down
echo ============================================================
echo.
pause
