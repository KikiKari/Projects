# Dokumentation — Skill „Program-Derivation" (v2.0)

Vollständige Anwender- und Pflegedokumentation für den Skill **program-derivation** (Formale Programmableitung / Formal Program Derivation).

- **Autor:** karimkiki
- **Version:** 2.0
- **Sprachen:** Deutsch / Englisch (Ausgabe folgt der Sprache des Nutzers)
- **Scope:** Space „Program-Derivation" (zusätzlich als User-Skill vorhanden)
- **Status:** validiert (`agentskills validate` → Valid skill)

---

## 1. Zweck / Purpose

Der Skill führt eine **formale Programmableitung** durch: von der Architektur-Ermittlung eines bestehenden oder neuen Systems über Abstraktionsschichten-Design und Metriken bis hin zu einer vollständigen **Modernisierungs-Roadmap**.

Er deckt zwei Aufgabenbereiche ab:

1. **Ist-Analyse** (Phasen 1–3): Architektur, Schnittstellen, Vendor Lock-in, SoC, Kopplung/Kohäsion, Leaky Abstractions, sowie Metriken (CC, LCOM4, Instabilitäts-Index).
2. **Modernisierung** (Phase 4, neu in v2.0): sechs aufeinander aufbauende Stufen von Refactoring bis Green-Field Rewrite.

---

## 2. Wann der Skill geladen wird / When It Loads

Trigger (Auswahl, de + en):
- „Führe eine Architekturanalyse durch" / „Perform a program derivation / architecture analysis"
- „Welche Abstraktionsschichten fehlen?" / „What interfaces are missing?"
- „Berechne die zyklomatische Komplexität" / „Analyze coupling and cohesion"
- „Analysiere den Vendor Lock-in"
- „Erstelle eine Modernisierungs-Roadmap / Refactoring-Plan" / „Create a modernization roadmap"
- „Plane Performance-Tuning / Effizienzsteigerung" / „Plan performance tuning"
- „Analysiere die technischen Schulden / Debt Reduction" / „Assess technical debt"
- „Erstelle die System- und Komponentendokumentation"
- „Replatforming / Lift-and-Reshape planen" / „Replatforming vs. green-field rewrite"
- „Green-Field Rewrite / Reengineering ableiten"

Bei mehreren ähnlichen Skills gilt die Scope-Priorität: User > Space > Org > Built-in.

---

## 3. Paketstruktur / Package Layout

```
program-derivation/
├── SKILL.md                              # Kern-Anweisung (Phasen 1–4, Ausgabeformat, Trigger)
├── README.md                            # diese Dokumentation
└── references/
    ├── boundary-checklist.md            # Grenzschichten-Checkliste (Phase 1.1)
    ├── interface-templates.md           # Interface-Vorlagen (Phase 2)
    ├── metrics-examples.md              # CC/LCOM/I-Index Berechnungsbeispiele (Phase 3)
    ├── refactoring-catalog.md           # NEU: Refactoring-Muster & Debt-Klassifikation (Phase 4.1 + 4.3)
    ├── performance-checklist.md         # NEU: Performance-/Effizienz-Checkliste (Phase 4.2)
    └── modernization-playbook.md        # NEU: Replatforming vs. Green-Field Rewrite (Phase 4.5 + 4.6)
```

Referenzdateien werden **bei Bedarf** vom Agenten gelesen — sie halten die SKILL.md schlank und liefern Detailtiefe nur, wenn die jeweilige Phase ausgeführt wird.

---

## 4. Ablauf / Workflow

Die Analyse läuft in vier Phasen. Ausgabesprache = Sprache des Nutzers.

### Phase 1 — Architektur-Ermittlung
| Schritt | Inhalt | Hilfsdatei |
|---|---|---|
| 1.1 Grenzschichten-Check | alle externen Schnittstellen tabellieren | `boundary-checklist.md` |
| 1.2 Austauschbarkeits-Check | Skala 1 (hardgecoded) … 5 (provider-agnostisch) | — |
| 1.3 Komplexitäts-Check | Zeilen/Funktionen, Async-Strukturen, kritische Pfade | — |
| 1.4 Vendor Lock-in | HOCH / MITTEL / NIEDRIG | — |
| 1.5 Separation of Concerns | SoC-Verletzungen | — |
| 1.6 Kopplung & Kohäsion | Ca, Ce, I = Ce/(Ca+Ce), Kohäsionstyp | `metrics-examples.md` |
| 1.7 Leaky Abstractions | konkrete Lecks identifizieren | — |

### Phase 2 — Abstraktionsschichten-Design
- 2.1 Wrapper/Facade-Ermittlung, 2.2 strategische Entkopplungspunkte (3–5 priorisiert), 2.3 vollständige Interface-Definitionen (TypeScript/Python ABC/Java).
- Hilfsdatei: `interface-templates.md` (Provider-, Repository-, Aggregator-, Config-, Audio-Engine-, Warning-Provider-Pattern).

### Phase 3 — Metriken
- 3.1 Zyklomatische Komplexität (CC = Entscheidungspunkte + 1), 3.2 LCOM4, 3.3 Zusammenfassungstabelle.
- Hilfsdatei: `metrics-examples.md` (Rechenbeispiele CC 1 / 4 / 16, LCOM4 1 / 7, I-Index).

### Phase 4 — Modernisierungs-Roadmap (neu in v2.0)
Sechs Stufen als **Gates** — jede Stufe wird erst empfohlen, wenn die Eingangskriterien der vorherigen erfüllt sind. Pro Stufe immer: Eingangskriterium · Maßnahmen · Exit-Kriterium · Risiko.

| Stufe | Name | Verhalten | Hilfsdatei |
|---|---|---|---|
| 4.1 | Refactoring (verhaltenserhaltend) | erhält | `refactoring-catalog.md` |
| 4.2 | Optimierung & Performance Tuning | erhält | `performance-checklist.md` |
| 4.3 | Refinement & Debt Reduction | erhält | `refactoring-catalog.md` |
| 4.4 | System- & Komponentendokumentation | erhält | — (C4/ADR) |
| 4.5 | Replatforming / Lift-and-Reshape | ändert Plattform | `modernization-playbook.md` |
| 4.6 | Green-Field Rewrite / Reengineering | Neubau | `modernization-playbook.md` |
| 4.7 | Roadmap-Zusammenfassung | — | — |

**Grundsatz:** Stufe 1–4 reduzieren Risiko bei erhaltenem Verhalten; Stufe 5–6 verändern Plattform/Implementierung und setzen eine stabilisierte, dokumentierte Basis (Stufe 4) bzw. eine wirtschaftliche Begründung (Stufe 3) voraus.

---

## 5. Phasenverknüpfungen / Cross-References

Der Skill ist als zusammenhängende Ableitung konzipiert — Phase 4 baut explizit auf den Befunden der Phasen 1–3 auf:

- **4.1 Refactoring** adressiert Hotspots aus **1.5–1.7** (SoC, Leaky Abstractions) und **3.1–3.2** (CC > 10, LCOM4 > 3).
- **4.3 Debt Reduction** liefert die Entscheidungsgrundlage für **4.5 vs. 4.6** (Tilgung vs. Neubau).
- **4.4 Dokumentation** nutzt die Interfaces aus **Phase 2** und die Ca/Ce-Werte aus **1.6**.
- **4.5 Replatforming** verlagert die in **1.4** als HOCH bewerteten Vendor-Lock-in-Punkte hinter die **Phase-2-Interfaces**.
- **4.6 Green-Field** nutzt die Phase-2-Interfaces als Soll-Verträge und die Phase-4.4-Doku als Spezifikation des Altsystems.

---

## 6. Ausgabeformat / Output Format

Jede Ableitung wird so strukturiert:
1. **Kritische Befunde** (sofortiger Handlungsbedarf) — mit Code-Beispielen
2. **Hohe Befunde** (nächster Sprint) — mit Interface-Vorschlägen
3. **Mittlere Befunde** (Backlog) — mit kurzer Begründung
4. **Positive Aspekte** — was bereits gut strukturiert ist
5. **Priorisierte Refactoring-Reihenfolge** — Tabelle mit Aufwand und Nutzen
6. **Roadmap-Zusammenfassung** (Phase 4.7) — Stufe / empfohlen? / Voraussetzung / Aufwand / Nutzen / nächster Schritt

Interfaces immer als vollständige Definition (nicht nur Name).

---

## 7. Referenzdateien im Detail / Reference Files

| Datei | Inhalt |
|---|---|
| `boundary-checklist.md` | Checkliste für REST-APIs, Datenbanken, Browser-/Native-APIs, Dateisystem, Umgebungsvariablen |
| `interface-templates.md` | Provider-, Repository-, Aggregator-, Config-Repository-, Audio-Engine-, Warning-Provider-Pattern (TypeScript) |
| `metrics-examples.md` | Rechenbeispiele für CC (1/4/16), LCOM4 (1/7), Instabilitäts-Index I |
| `refactoring-catalog.md` | Golden Rule, Refactoring-Muster nach Code-Smell, sichere Schrittfolge, Debt-Klassifikation (Fowler-Quadrant, Debt-Typen, Zins/Tilgung-Priorisierung, Übergang zu Stufe 5/6) |
| `performance-checklist.md` | Profiling, Async/Nebenläufigkeit, DB & N+1, Caching, Netzwerk/Payload, Frontend/PWA, Speicher, Kosten-Effizienz |
| `modernization-playbook.md` | 6-R-Strategien, Entscheidungsmatrix Replatform vs. Rewrite, Strangler-Fig, Green-Field-Vorgehen, Anti-Pattern |

---

## 8. Verwendung / Usage

**Im Space (bereits bereitgestellt):** Der Skill ist im Space „Program-Derivation" aktiv. In einer Konversation innerhalb des Space genügt ein Trigger (z. B. „@Program-Derivation Architekturanalyse für …") oder die Nennung des Systems/Repos.

**Beispiel-Aufruf:**
> „@Program-Derivation Erstelle eine vollständige Programmableitung inkl. Modernisierungs-Roadmap für das Repo owner/repo."

Der Agent ermittelt dann Phase 1–3 aus dem Code und leitet daraus die Phase-4-Roadmap mit konkreten, priorisierten Stufen ab.

**Als Download:** Das ZIP `program-derivation.zip` enthält alle Dateien und kann über die Skill-Verwaltung importiert werden: https://www.perplexity.ai/computer/skills

---

## 9. Pflege / Maintenance

- Skill-Verzeichnis bearbeiten → mit `agentskills validate program-derivation/` prüfen → als ZIP packen → über Skill-Verwaltung bzw. im Space speichern (gleicher Name = Update, keine Dublette).
- SKILL.md unter ~500 Zeilen halten; neue Detailtiefe in `references/` auslagern und aus SKILL.md verlinken.
- Frontmatter-Felder beschränkt auf: `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`. Zusatzdaten (z. B. `version`) gehören unter `metadata`.

---

## 10. Changelog

### v2.0
- Neue **Phase 4: Modernisierungs-Roadmap** (6 Stufen: Refactoring → Performance → Debt Reduction → Doku → Replatforming → Green-Field Rewrite) mit Gate-Logik, Exit-Kriterien und Ausgabe-Tabellen.
- Drei neue Referenzdateien: `refactoring-catalog.md`, `performance-checklist.md`, `modernization-playbook.md`.
- Erweiterte Trigger-Phrasen (de + en) und aktualisierte Referenz-Liste.
- Versionsangabe auf 2.0 erhöht.

### v1.0
- Phasen 1–3 (Architektur-Ermittlung, Abstraktionsschichten-Design, Metriken) mit den Referenzen boundary-checklist, interface-templates, metrics-examples.
