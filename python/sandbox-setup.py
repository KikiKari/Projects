#!/usr/bin/env python3
# sandbox-setup.sh — portiert nach python
# Quelle: shell, Onboarding@main:scripts/sandbox-setup.sh
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

import os
import sys
import subprocess
import shutil
import tempfile
import time

def main():
    skip_heavy = len(sys.argv) > 1 and sys.argv[1] == "--skip-heavy"
    
    os.chdir(os.path.join(os.path.dirname(__file__), ".."))
    
    def log(message):
        print(f"[sandbox-setup] {message}")
    
    log("Node-Dependencies (npm install) …")
    try:
        subprocess.run(["npm", "install", "--no-audit", "--no-fund"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        log("FEHLER: npm install fehlgeschlagen")
        sys.exit(1)
    
    log("Python-Dependencies (backend/requirements-dev.txt) …")
    try:
        subprocess.run(["pip3", "install", "--quiet", "-r", "backend/requirements-dev.txt"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except subprocess.CalledProcessError:
        log("FEHLER: pip install fehlgeschlagen")
        sys.exit(1)
    
    apt_updated = False
    
    def apt_install(pkg, binary):
        nonlocal apt_updated
        if shutil.which(binary):
            try:
                version_output = subprocess.check_output([binary, "-version"], stderr=subprocess.STDOUT, text=True)
                version_line = version_output.split('\n')[0] if version_output else ""
            except subprocess.CalledProcessError:
                version_line = ""
            log(f"{pkg} bereits vorhanden ({version_line})")
            return
        
        log(f"Installiere {pkg} …")
        if not apt_updated:
            env = os.environ.copy()
            env["DEBIAN_FRONTEND"] = "noninteractive"
            try:
                subprocess.run(["apt-get", "update", "-qq"], check=True, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                apt_updated = True
            except subprocess.CalledProcessError:
                pass
        
        env = os.environ.copy()
        env["DEBIAN_FRONTEND"] = "noninteractive"
        try:
            subprocess.run(["apt-get", "install", "-y", "-qq", pkg], check=True, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError:
            log(f"WARNUNG: {pkg} konnte nicht installiert werden (Netzwerk-Policy?) — Medien-Schritte ggf. eingeschraenkt")
    
    apt_install("ffmpeg", "ffmpeg")
    apt_install("imagemagick", "convert")
    if not skip_heavy:
        apt_install("gimp", "gimp")
        apt_install("blender", "blender")
    
    apt_install("xvfb", "Xvfb")
    apt_install("x11-utils", "xdpyinfo")
    apt_install("libnss3-tools", "certutil")
    
    if not shutil.which("google-chrome-stable"):
        log("Installiere Google Chrome Stable …")
        with tempfile.NamedTemporaryFile(suffix=".deb", delete=False) as tmp_deb:
            tmp_deb_path = tmp_deb.name
        try:
            subprocess.run(["curl", "-fsSL", "-o", tmp_deb_path, "https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb"], check=True)
            env = os.environ.copy()
            env["DEBIAN_FRONTEND"] = "noninteractive"
            result = subprocess.run(["apt-get", "install", "-y", "-qq", tmp_deb_path], env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            if result.returncode == 0:
                try:
                    chrome_version = subprocess.check_output(["google-chrome-stable", "--version"], stderr=subprocess.DEVNULL, text=True).strip()
                    log(f"Chrome installiert: {chrome_version}")
                except subprocess.CalledProcessError:
                    pass
            else:
                log("WARNUNG: Chrome-Installation fehlgeschlagen")
        except subprocess.CalledProcessError:
            log("WARNUNG: Chrome-Download fehlgeschlagen (Netzwerk-Policy?)")
        finally:
            if os.path.exists(tmp_deb_path):
                os.remove(tmp_deb_path)
    
    if shutil.which("certutil") and os.path.isfile("/root/.ccr/ca-bundle.crt"):
        nssdb_path = os.path.expanduser("~/.pki/nssdb")
        os.makedirs(nssdb_path, exist_ok=True)
        try:
            subprocess.run(["certutil", "-d", f"sql:{nssdb_path}", "-N", "--empty-password"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except subprocess.CalledProcessError:
            pass
        
        try:
            output = subprocess.check_output(["certutil", "-d", f"sql:{nssdb_path}", "-L"], stderr=subprocess.DEVNULL, text=True)
            if "ccr-proxy-ca" not in output:
                result = subprocess.run(["certutil", "-d", f"sql:{nssdb_path}", "-A", "-t", "C,,", "-n", "ccr-proxy-ca", "-i", "/root/.ccr/ca-bundle.crt"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                if result.returncode == 0:
                    log("Proxy-CA in Chrome-NSS-Store importiert")
        except subprocess.CalledProcessError:
            pass
    
    if os.path.isdir("node_modules") and not os.path.islink("node_modules/playwright") and not os.path.exists("node_modules/playwright"):
        if shutil.which("npm"):
            try:
                subprocess.run(["npm", "install", "--no-audit", "--no-fund", "--no-save", "playwright"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                log("Playwright (Node) installiert")
            except subprocess.CalledProcessError:
                log("WARNUNG: Playwright-npm-Install fehlgeschlagen")
    
    try:
        if subprocess.run(["git", "rev-parse", "--is-inside-work-tree"], capture_output=True, check=True).returncode == 0:
            script_dir = os.path.abspath(os.path.dirname(__file__))
            project_root = os.path.dirname(script_dir)
            credential_helper_script = os.path.join(project_root, ".claude", "git-credential-pat.sh")
            subprocess.run(["git", "config", f"credential.https://x-access-token@github.com.helper", f"!{credential_helper_script}"])
            subprocess.run(["git", "remote", "set-url", "--push", "origin", "https://x-access-token@github.com/KikiKari/Onboarding.git"])
            log("Git-Push-Route: direkt zu github.com (PAT via Credential-Helper)")
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    
    if shutil.which("dockerd") and not is_docker_running():
        log("Starte Docker-Daemon (Registry-Mirror: mirror.gcr.io) …")
        daemon_config_path = "/etc/docker/daemon.json"
        os.makedirs(os.path.dirname(daemon_config_path), exist_ok=True)
        if not os.path.exists(daemon_config_path):
            with open(daemon_config_path, "w") as f:
                f.write('{"registry-mirrors":["https://mirror.gcr.io"]}\n')
        
        subprocess.Popen(["dockerd"], stdout=open("/tmp/dockerd.log", "w"), stderr=subprocess.STDOUT)
        
        for _ in range(15):
            if is_docker_running():
                break
            time.sleep(1)
        
        if is_docker_running():
            log("Docker-Daemon laeuft")
        else:
            log("WARNUNG: Docker-Daemon nicht gestartet")
    
    log("Fertig. Versionen:")
    try:
        node_version = subprocess.check_output(["node", "--version"], text=True).strip()
        print(f"[sandbox-setup]   node {node_version}")
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    
    try:
        python_version = subprocess.check_output(["python3", "--version"], text=True).strip()
        print(f"[sandbox-setup]   {python_version}")
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    
    binaries = [
        ("ffmpeg", ["ffmpeg", "-version"]),
        ("convert", ["convert", "-version"]),
        ("gimp", ["gimp", "--version"]),
        ("blender", ["blender", "--version"])
    ]
    
    for name, cmd in binaries:
        if shutil.which(name):
            try:
                version_output = subprocess.check_output(cmd, stderr=subprocess.STDOUT, text=True)
                version_line = version_output.split('\n')[0] if version_output else ""
                print(f"[sandbox-setup]   {version_line}")
            except subprocess.CalledProcessError:
                pass

def is_docker_running():
    try:
        subprocess.run(["docker", "info"], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

if __name__ == "__main__":
    main()
