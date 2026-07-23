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
58d68c8a14ee698228dd93eae8a2f4a3ac178c9983b49adb7ce301d0646406fe  tiktok-live-companion-extension-0.7.2.zip
46d243b3ab3e2617b13dfaa4f7d801af1824c21a280c4ccd547ea813dbc7790b  tiktok-live-companion-plugin-0.7.2.zip
c474066ec55cf539df1d8457c45118d1841a2b5f5fbc886cccb74dc339155aaf  tiktok-live-companion-service-0.7.2.zip
3d1f96d856c65e8bf3dd5cce4224a54e7c5fbfcf3468826766d5321c78ab6c0c  tiktok-live-companion-setup-0.7.2-unsigned-dev.exe
```

## Änderungen

0.7.2 entfernt die Qualitätsbox und sechs Erklärungstexte, stabilisiert native Untertitel durch DOM-Zusammenführung und WebSocket-Vorrang, stellt Lautstärke und Pegelschutz als 0–100 dar und ersetzt die fehleranfällige Sidepanel-Aufnahme durch einen Background-Broker. Native Messaging automatisiert die interne Dienstauthentifizierung und hält den AudD-Token außerhalb von Erweiterungsspeicher, Logs und Debugexporten.
