# Downloads und Release 0.7.2

## Browser-Kernpaket

- `tiktok-live-companion-extension-0.7.2.zip` – entpackbare Edge-/Chrome-Erweiterung
- `tiktok-live-companion-plugin-0.7.2.zip` – Codex-Plugin mit Browser-, Dienst- und Installerquellen
- `tiktok-live-companion-service-0.7.2.zip` – manueller lokaler Windows-Dienst
- `tiktok-live-companion-setup-0.7.2-unsigned-dev.exe` – benutzerbezogener Windows-Installer mit fester Node-Laufzeit und Chrome-/Edge-Native-Messaging; nicht codesigniert
- `tiktok-live-companion-0.7.2-SHA256.txt` – Integritätswerte

Android und iOS bleiben unverändert auf 0.7.0 und sind nicht Bestandteil dieses Browser-Kernpakets.

## SHA-256

```text
6c35fc60ff8842479a8fe5e2eb165f69cb97ae6e54753816f89b78abc64f66ea  tiktok-live-companion-extension-0.7.2.zip
398dfd9b03962171f31409c611eff5d7cd2a9d99f49cb0255fc05aa0fbfe906e  tiktok-live-companion-plugin-0.7.2.zip
c474066ec55cf539df1d8457c45118d1841a2b5f5fbc886cccb74dc339155aaf  tiktok-live-companion-service-0.7.2.zip
3d1f96d856c65e8bf3dd5cce4224a54e7c5fbfcf3468826766d5321c78ab6c0c  tiktok-live-companion-setup-0.7.2-unsigned-dev.exe
```

## Änderungen

0.7.2 entfernt die Qualitätsbox und sechs Erklärungstexte, stabilisiert native Untertitel durch DOM-Zusammenführung und WebSocket-Vorrang, stellt Lautstärke und Pegelschutz als 0–100 dar und ersetzt die fehleranfällige Sidepanel-Aufnahme durch einen Background-Broker. Native Messaging automatisiert die interne Dienstauthentifizierung und hält den AudD-Token außerhalb von Erweiterungsspeicher, Logs und Debugexporten.
