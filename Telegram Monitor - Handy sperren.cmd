@echo off
cd /d "%~dp0"
where tailscale >nul 2>&1 && (set "TS=tailscale") || (set "TS=%ProgramFiles%\Tailscale\tailscale.exe")
echo Hebe die Freigabe auf. Der Monitor laeuft weiter, ist aber nur noch
echo auf diesem Rechner erreichbar.
"%TS%" serve --https=443 off
"%TS%" serve status
timeout /t 4 >nul
