@echo off
rem  Telegram Monitor Companion - Doppelklick-Start.
rem  Ruft den PowerShell-Starter auf. -ExecutionPolicy Bypass gilt nur fuer
rem  diesen einen Aufruf und aendert nichts an den Einstellungen des Rechners.
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0TelegramMonitorCompanion.ps1" %*
if errorlevel 1 pause
