# Modernisierungs-Playbook: Replatforming vs. Green-Field / Modernization Playbook

Gehört zu **Phase 4.5 (Replatforming / Lift-and-Reshape)** und **Phase 4.6 (Green-Field Rewrite / Reengineering)**.

---

## 1. Die 6 R der Anwendungsmodernisierung / The 6 R's

Ordne jede Komponente einer Strategie zu:

| Strategie | Bedeutung | Aufwand | Wann |
|---|---|---|---|
| **Retain** | Lassen wie es ist | keiner | läuft stabil, kein Änderungsdruck |
| **Rehost** (Lift-and-Shift) | 1:1 auf neue Infra, kein Code | sehr gering | nur Infra-Wechsel, Zeitdruck |
| **Replatform** (Lift-and-Reshape) | moderate Anpassung, Kernlogik bleibt | gering–mittel | **Phase 4.5** |
| **Refactor/Rearchitect** | Struktur tief umbauen, gleiche Sprache | mittel–hoch | Debt zu hoch für Replatform |
| **Rebuild** (Green-Field) | komplette Neuentwicklung | hoch | **Phase 4.6** |
| **Replace** | durch Standardprodukt/SaaS ersetzen | variabel | Eigenbau bringt keinen Vorteil |

---

## 2. Entscheidungsmatrix: Replatform vs. Rewrite

Bewerte jede Achse 1–5; hohe Summe rechts → eher Green-Field.

| Kriterium | spricht für **Replatform (4.5)** | spricht für **Rewrite (4.6)** |
|---|---|---|
| Debt-Höhe (aus Phase 4.3) | tilgbar | Tilgung ≈ Neubau |
| Kerngeschäftslogik | korrekt, wertvoll | fehlerhaft/überholt |
| Zielarchitektur | ähnlich heutiger | grundlegend anders |
| Test-/Doku-Lage | brauchbar | praktisch keine |
| Risikotoleranz | niedrig | höher (Parallelbetrieb möglich) |
| Team-Kenntnis des Alt-Stacks | hoch | gering / EOL-Tech |
| Zeit-/Budgetdruck | hoch | moderat |

> **Faustregel:** Rewrite nur, wenn (a) Phase 4.3 zeigt, dass Tilgung unwirtschaftlich ist, **und** (b) die Phase-4-Doku existiert, damit kein implizites Wissen verloren geht. „Second-System-Effekt" und unterschätzte versteckte Anforderungen sind die häufigsten Rewrite-Fallen.

---

## 3. Replatforming / Lift-and-Reshape (Phase 4.5)

### 3.1 Typische Reshapes
- Runtime-/Framework-Upgrade (z. B. Node-LTS, Major-Framework-Sprung).
- Containerisierung (Dockerfile, 12-Factor-Konformität).
- Eigenbetrieb → Managed Service (DB, Queue, Auth, Object-Storage).
- Vendor-Lock-in-Punkte (Phase 1.4 = HOCH) hinter die Phase-2-Interfaces verlagern und Provider tauschen.
- Konfiguration externalisieren (ENV/Secrets-Manager statt hardgecodet).

### 3.2 Strangler-Fig-Migration (empfohlen, kein Big-Bang)
1. **Fassade** vor das Altsystem setzen (Reverse-Proxy/API-Gateway).
2. Eine Komponente neu/umgezogen implementieren.
3. Traffic für diese Route schrittweise auf neu umlenken (Canary).
4. Verifizieren, alte Implementierung entfernen.
5. Wiederholen bis Altsystem leer ist.

### 3.3 Sicherheits-/Qualitätsnetz
- [ ] Rollback-Pfad pro Schritt definiert?
- [ ] Funktionsumfang unverändert (Regressionstests)?
- [ ] Observability (Logs/Metriken/Traces) auf neuer Plattform vorhanden?
- [ ] Daten-Migration getestet (idempotent, reversibel)?

---

## 4. Green-Field Rewrite / Reengineering (Phase 4.6)

### 4.1 Voraussetzungen (Gate)
- Phase-4-Doku als **Spezifikation** des Altsystems vorhanden.
- Phase-2-Interfaces als **Soll-Architektur-Verträge** definiert.
- Wirtschaftliche Begründung aus Phase 4.3.

### 4.2 Vorgehen
1. **Soll-Architektur (Zielbild)** entwerfen — saubere Schichten, alle Vendor-Punkte hinter Interfaces.
2. **Vertikale Slices** statt Schicht-für-Schicht: ein vollständiges Feature end-to-end zuerst.
3. **Parallelbetrieb / Dual-Run:** Neusystem schattenweise mit Produktions-Traffic füttern (Shadow Traffic), Ergebnisse mit Altsystem vergleichen → Paritätsnachweis.
4. **Daten-Migration:** Strategie (Big-Bang vs. inkrementell/CDC), Validierung, Reconciliation.
5. **Cutover:** Feature-Flags / Canary, definierter Rollback.
6. **Decommission:** Altsystem erst abschalten, wenn Parität nachgewiesen und Stabilisierungsphase überstanden.

### 4.3 Anti-Pattern vermeiden
- Big-Bang-Cutover ohne Parallelbetrieb.
- Scope Creep („wenn wir schon neu bauen, dann auch gleich …").
- Verlust impliziter Geschäftsregeln, weil das Altsystem nie dokumentiert wurde (→ deshalb ist Phase 4.4 Pflicht-Gate).

---

## 5. Ausgabe-Tabellen (für Phase 4.5/4.6)

**Replatforming:**
| Komponente | heutige Plattform | Zielplattform | R-Strategie | Migrationsmuster | Rollback | Risiko |
|---|---|---|---|---|---|---|

**Green-Field:**
| Slice/Feature | Soll-Architektur-Vertrag (Interface) | Migrationsschritt | Paritätsnachweis | Cutover-Strategie | Risiko |
|---|---|---|---|---|---|
