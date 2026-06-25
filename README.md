# Program-Derivation

> Formale Programmableitung / Formal Program Derivation — ein Agent Skill für Architekturanalyse, Abstraktionsschichten-Design, Software-Metriken und eine vollständige Modernisierungs-Roadmap.

[![Skill validiert](https://img.shields.io/badge/agentskills-valid-brightgreen)](https://agentskills.io) ![Version](https://img.shields.io/badge/version-2.0-blue) ![Sprachen](https://img.shields.io/badge/sprachen-de%20%2F%20en-lightgrey) ![Lizenz](https://img.shields.io/badge/license-MIT-green)

Dieser Branch enthält den Agent Skill **`program-derivation`**. Der Skill führt eine strukturierte, formale Ableitung von Software-Architekturen durch — von der Ist-Analyse bestehender Systeme bis zur abgeleiteten Modernisierungs-Roadmap.

---

## Inhalt / Contents

```
Program-Derivation/
├── SKILL.md                         # Kern-Anweisung (Phasen 1–4, Ausgabeformat, Trigger)
├── README.md                       # ausführliche Skill-Dokumentation
└── references/
    ├── boundary-checklist.md       # Grenzschichten-Checkliste (Phase 1.1)
    ├── interface-templates.md      # Interface-Vorlagen (Phase 2)
    ├── metrics-examples.md         # CC/LCOM/I-Index Berechnungsbeispiele (Phase 3)
    ├── refactoring-catalog.md      # Refactoring-Muster & Debt-Klassifikation (Phase 4.1 + 4.3)
    ├── performance-checklist.md    # Performance-/Effizienz-Checkliste (Phase 4.2)
    └── modernization-playbook.md   # Replatforming vs. Green-Field Rewrite (Phase 4.5 + 4.6)
```

---

## Was der Skill leistet / What It Does

Der Skill arbeitet in **vier Phasen**. Die Ausgabesprache folgt der Sprache des Nutzers (de/en).

| Phase | Fokus | Kernergebnis |
|---|---|---|
| **1 — Architektur-Ermittlung** | Grenzschichten, Austauschbarkeit, Komplexität, Vendor Lock-in, SoC, Kopplung/Kohäsion, Leaky Abstractions | Ist-Architektur mit Befund-Tabellen |
| **2 — Abstraktionsschichten-Design** | Wrapper/Facades, strategische Entkopplungspunkte | vollständige Interface-Definitionen (TS/Python/Java) |
| **3 — Metriken** | Zyklomatische Komplexität (CC), LCOM4, Instabilitäts-Index (I) | quantitative Qualitätsbewertung |
| **4 — Modernisierungs-Roadmap** | 6 aufeinander aufbauende Stufen | priorisierte Umbau-/Neubau-Strategie |

### Phase 4 — die 6-stufige Roadmap

```
Stufe 1            Stufe 2              Stufe 3                Stufe 4         Stufe 5              Stufe 6
Refactoring   ->   Performance /   ->   Refinement /      ->   System- &   ->  Replatforming /  ->  Green-Field
(struktur-         Optimierung          Debt Reduction         Komponenten-    Lift-and-Reshape     Rewrite /
 erhaltend)        (Effizienz)          (Schuldenabbau)        Doku            (Plattformwechsel)   Reengineering
```

Jede Stufe ist ein **Gate**: Sie wird erst empfohlen, wenn die Eingangskriterien der vorherigen Stufe erfüllt sind. Stufe 1–4 erhalten das Verhalten und senken das Risiko; Stufe 5–6 verändern Plattform bzw. Implementierung und setzen eine stabilisierte, dokumentierte Basis voraus.

---

## Verwendung / Usage

### Als Agent Skill in Perplexity
Der Skill ist im Space „Program-Derivation" hinterlegt. In einer Konversation genügt ein Trigger:

```
@Program-Derivation Erstelle eine vollständige Programmableitung
inkl. Modernisierungs-Roadmap für das Repo owner/repo.
```

Der Agent ermittelt Phase 1–3 aus dem Code und leitet daraus die Phase-4-Roadmap mit konkreten, priorisierten Stufen ab.

### Trigger-Beispiele (de / en)
- „Führe eine Architekturanalyse durch" / „Perform a program derivation / architecture analysis"
- „Welche Abstraktionsschichten fehlen?" / „What interfaces are missing?"
- „Berechne die zyklomatische Komplexität" / „Analyze coupling and cohesion"
- „Erstelle eine Modernisierungs-Roadmap / Refactoring-Plan" / „Create a modernization roadmap"
- „Plane Performance-Tuning / Effizienzsteigerung" / „Plan performance tuning"
- „Analysiere die technischen Schulden / Debt Reduction" / „Assess technical debt"
- „Replatforming / Lift-and-Reshape planen" / „Replatforming vs. green-field rewrite"

### Manuelle Installation aus diesem Repo
1. Ordner `Program-Derivation/` als ZIP packen.
2. Über die [Skill-Verwaltung](https://www.perplexity.ai/computer/skills) importieren.
3. Mit `agentskills validate Program-Derivation/` prüfen (Ergebnis: `Valid skill`).

---

## Ausgabeformat / Output Format

Jede Ableitung wird einheitlich strukturiert:
1. Kritische Befunde (sofortiger Handlungsbedarf) — mit Code-Beispielen
2. Hohe Befunde (nächster Sprint) — mit Interface-Vorschlägen
3. Mittlere Befunde (Backlog) — mit Begründung
4. Positive Aspekte — was bereits gut strukturiert ist
5. Priorisierte Refactoring-Reihenfolge (Tabelle: Aufwand/Nutzen)
6. Roadmap-Zusammenfassung (Phase 4.7)

Eine ausführliche Beschreibung jeder Phase, der Phasenverknüpfungen und der Referenzdateien steht in [`Program-Derivation/README.md`](Program-Derivation/README.md).

---

## Metadaten / Metadata

| Feld | Wert |
|---|---|
| Skill-Name | `program-derivation` |
| Version | 2.0 |
| Sprachen | Deutsch / Englisch |
| Autor | karimkiki |
| Lizenz | MIT (siehe [LICENSE](LICENSE)) |

---

## Changelog

- **v2.0** — Neue Phase 4 (6-stufige Modernisierungs-Roadmap), drei neue Referenzdateien (`refactoring-catalog.md`, `performance-checklist.md`, `modernization-playbook.md`), erweiterte Trigger, ausführliche Dokumentation.
- **v1.0** — Phasen 1–3 (Architektur-Ermittlung, Abstraktionsschichten-Design, Metriken).
