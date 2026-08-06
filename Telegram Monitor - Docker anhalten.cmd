@echo off
cd /d "%~dp0"
echo Halte den Container an. Der gesammelte Verlauf bleibt im Volume erhalten.
docker compose down
timeout /t 3 >nul
