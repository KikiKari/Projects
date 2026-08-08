#!/usr/bin/env python3
# TelegramMonitorCompanion.ps1 — portiert nach python
# Quelle: powershell, Projects@Telegram-Monitor:TelegramMonitorCompanion.ps1
# Erzeugt: 2026-08-08 durch ABSTRACTIONS_MANAGER.py

# Telegram Monitor Companion — Starter
#
# Startet den lokalen Monitor im Hintergrund (kein Konsolenfenster), wartet,
# bis der Port wirklich antwortet, und oeffnet die Oberflaeche als eigenes
# Fenster ohne Adressleiste. Laeuft der Monitor schon, wird er nicht erneut
# gestartet — dann wird nur das Fenster geoeffnet.
#
# Aufruf:
#   .\TelegramMonitorCompanion.ps1              starten und oeffnen
#   .\TelegramMonitorCompanion.ps1 -Stop        beenden
#   .\TelegramMonitorCompanion.ps1 -Status      nachsehen, ob er laeuft
#   .\TelegramMonitorCompanion.ps1 -Port 9000   anderer Port
#   .\TelegramMonitorCompanion.ps1 -Console     mit sichtbarem Fenster (Fehlersuche)

import argparse
import os
import sys
import time
import subprocess
import requests
import psutil
from pathlib import Path

def write_step(msg):
    print(f"  {msg}")

def test_monitor(url):
    try:
        response = requests.get(f"{url}/api/status", timeout=2)
        return response.status_code == 200
    except:
        return False

def get_monitor_process(pid_file):
    if not pid_file.exists():
        return None
    try:
        with pid_file.open('r') as f:
            pid = int(f.read().strip())
        return psutil.Process(pid)
    except:
        return None

def find_python():
    """Suche Python im System"""
    candidates = [
        (['py', '-3'], 'py'),
        (['python'], 'python'),
        (['python3'], 'python3')
    ]
    
    for args, cmd in candidates:
        try:
            subprocess.run([cmd, '--version'], 
                         capture_output=True, check=True)
            return args
        except:
            continue
    return None

def main():
    parser = argparse.ArgumentParser(description='Telegram Monitor Companion')
    parser.add_argument('-Port', type=int, default=8765, help='Port number')
    parser.add_argument('-Interval', type=int, default=120, help='Poll interval')
    parser.add_argument('-Stop', action='store_true', help='Stop monitor')
    parser.add_argument('-Status', action='store_true', help='Check status')
    parser.add_argument('-Console', action='store_true', help='Show console window')
    parser.add_argument('-NoBrowser', action='store_true', help='Do not open browser')
    
    args = parser.parse_args()
    
    root = Path(__file__).parent
    pid_file = root / 'data' / 'companion.pid'
    log_file = root / 'data' / 'companion.log'
    url = f"http://127.0.0.1:{args.Port}"
    
    # ---------------------------------------------------------------- beenden ---
    if args.Stop:
        proc = get_monitor_process(pid_file)
        if proc:
            proc.terminate()
            try:
                proc.wait(timeout=5)
            except:
                proc.kill()
            write_step(f"Monitor beendet (PID {proc.pid}).")
        else:
            write_step('Es lief kein Monitor aus diesem Starter.')
        pid_file.unlink(missing_ok=True)
        return
    
    # ----------------------------------------------------------------- Status ---
    if args.Status:
        if test_monitor(url):
            proc = get_monitor_process(pid_file)
            msg = f"Monitor laeuft auf {url}"
            if proc:
                msg += f"  (PID {proc.pid})"
            write_step(msg)
        else:
            write_step(f"Auf {url} antwortet nichts.")
        return
    
    # ------------------------------------------------------------------ Start ---
    print('')
    print('  Telegram Monitor Companion')
    print('  --------------------------')
    
    # Python suchen
    python_cmd = find_python()
    if not python_cmd:
        print('')
        print('  Python wurde nicht gefunden.')
        print('  Herunterladen: https://www.python.org/downloads/')
        print('  Beim Installieren "Add python.exe to PATH" ankreuzen.')
        print('')
        input('  Eingabetaste zum Schliessen')
        sys.exit(1)
    
    write_step(f"Python: {' '.join(python_cmd)}")
    
    if test_monitor(url):
        write_step(f"Monitor laeuft bereits auf {url} — wird nicht erneut gestartet.")
    else:
        # Verzeichnis erstellen
        pid_file.parent.mkdir(parents=True, exist_ok=True)
        
        # Server starten
        server_args = python_cmd + [
            'server.py', 
            '--port', str(args.Port),
            '--poll-interval', str(args.Interval),
            '--no-browser'
        ]
        
        if args.Console:
            proc = subprocess.Popen(
                server_args,
                cwd=str(root)
            )
        else:
            # Ohne Fenster, Ausgabe in die Protokolldatei
            with log_file.open('w') as stdout, log_file.with_suffix('.log.err').open('w') as stderr:
                proc = subprocess.Popen(
                    server_args,
                    cwd=str(root),
                    stdout=stdout,
                    stderr=stderr,
                    creationflags=subprocess.CREATE_NO_WINDOW if sys.platform == 'win32' else 0
                )
        
        # PID speichern
        pid_file.write_text(str(proc.pid))
        write_step(f"Gestartet (PID {proc.pid}), warte auf Antwort ...")
        
        # Auf Antwort warten
        ok = False
        for i in range(40):  # bis zu 20 Sekunden
            time.sleep(0.5)
            if test_monitor(url):
                ok = True
                break
            if proc.poll() is not None:  # Prozess beendet
                break
        
        if not ok:
            print('')
            print('  Der Monitor hat nicht geantwortet.')
            err_file = log_file.with_suffix('.log.err')
            if err_file.exists():
                print('  Letzte Zeilen der Fehlerausgabe:')
                lines = err_file.read_text(encoding='utf-8').splitlines()[-15:]
                for line in lines:
                    print(f"    {line}")
            print('')
            print('  Nochmal mit sichtbarem Fenster:  .\\TelegramMonitorCompanion.ps1 -Console')
            input('  Eingabetaste zum Schliessen')
            sys.exit(1)
        
        write_step('Antwortet.')
    
    if args.NoBrowser:
        write_step(f"Bereit: {url}")
        return
    
    # Als eigenes Fenster oeffnen (App-Modus), sonst normaler Tab
    import webbrowser
    import platform
    
    if platform.system() == 'Windows':
        edge = Path(os.environ.get('ProgramFiles(x86)', '')) / 'Microsoft' / 'Edge' / 'Application' / 'msedge.exe'
        chrome = Path(os.environ.get('ProgramFiles', '')) / 'Google' / 'Chrome' / 'Application' / 'chrome.exe'
        
        if edge.exists():
            subprocess.Popen([str(edge), f"--app={url}"])
            write_step('Als eigenes Fenster geoeffnet (Edge).')
        elif chrome.exists():
            subprocess.Popen([str(chrome), f"--app={url}"])
            write_step('Als eigenes Fenster geoeffnet (Chrome).')
        else:
            webbrowser.open(url)
            write_step('Im Standardbrowser geoeffnet.')
    else:
        webbrowser.open(url)
        write_step('Im Standardbrowser geoeffnet.')
    
    print('')
    print(f"  Laeuft im Hintergrund auf {url}")
    print('  Beenden:  .\\TelegramMonitorCompanion.ps1 -Stop')
    print('')

if __name__ == '__main__':
    main()
