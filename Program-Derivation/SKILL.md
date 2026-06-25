---
name: program-derivation
description: "Formale Programmableitung / Formal Program Derivation: Architektur-Ermittlung, Abstraktionsschichten, Metriken (CC, LCOM, Kopplung, Kohäsion, Vendor Lock-in, SoC, Leaky Abstractions). Lade diesen Skill wenn der Nutzer eine Architekturanalyse, Programmableitung, formale Ableitung, Abstraktionsschichten, Interface-Design, Komplexitätsmessung, Refactoring-Planung oder Software-Qualitätsbewertung anfordert. / Load this skill when the user requests architecture analysis, program derivation, formal derivation, abstraction layers, interface design, complexity measurement, refactoring planning or software quality assessment."
metadata:
  author: karimkiki
  version: '2.0'
  languages: de/en
---

# Programmableitung / Program Derivation

## Wann dieser Skill geladen werden soll / When to Load

**Deutsch:** Lade diesen Skill bei:
- Architekturanalyse eines bestehenden oder neuen Systems
- Formale Programmableitung / Program Derivation
- Abstraktionsschichten-Design (Interfaces, Wrappers, Facades)
- Komplexitätsmessung (CC, LCOM, Kopplung, Kohäsion)
- Vendor Lock-in Analyse
- Refactoring-Planung und Entkopplungspunkte
- Software-Qualitätsbewertung

**English:** Load this skill for:
- Architecture analysis of existing or new systems
- Formal program derivation
- Abstraction layer design (Interfaces, Wrappers, Facades)
- Complexity measurement (CC, LCOM, Coupling, Cohesion)
- Vendor Lock-in analysis
- Refactoring planning and decoupling points
- Software quality assessment

---

## Arbeitsanweisung / Work Instructions

Führe die Analyse in drei Phasen durch. Sprache der Ausgabe: Sprache des Nutzers (de/en).

---

## Phase 1: Architektur-Ermittlung / Architecture Discovery

### 1.1 Grenzschichten-Check / Boundary Analysis
Identifiziere alle Schnittstellen zu externen Systemen.

**Ausgabe-Tabelle / Output table:**
| Schnittstelle | Typ | Protokoll | Authentifizierung | Fehlerbehandlung |
|---|---|---|---|---|
| ... | REST-API / DB / Browser-API / FS | HTTPS/JSON / SQLite / In-Process | Bearer / Key / keine | ja (Retry) / teilweise / nein |

### 1.2 Austauschbarkeits-Check / Replaceability Check
Bewerte jede externe Abhängigkeit: Ist sie austauschbar ohne Core-Code-Änderungen?

**Skala:** 1 = hardgecoded, kein Interface | 3 = Interface vorhanden, aber spezifische Typen | 5 = vollständig abstrakt, Provider-agnostisch

### 1.3 Komplexitäts-Check / Complexity Check
- Zeilenzahl und Funktionsanzahl pro Modul
- Geschachtelte Async-Strukturen / fire-and-forget Patterns
- Kritische Pfade identifizieren

### 1.4 Vendor Lock-in Analyse
Bewertung: **HOCH** (hardgecoded URL + Model + Response-Parsing) | **MITTEL** (teilweise abstrahiert) | **NIEDRIG** (Web-Standard oder austauschbar)

### 1.5 Separation of Concerns (SoC)
Identifiziere Verletzungen: Business-Logik in Routing-Schicht, duplizierte Logik mit abweichenden Konstanten, Datenbankzugriff ohne Interface-Nutzung.

### 1.6 Kopplung & Kohäsion / Coupling & Cohesion
- **Ca** (Afferente Kopplung): Wie viele Module hängen von diesem ab?
- **Ce** (Efferente Kopplung): Von wie vielen Modulen hängt dieses ab?
- **I** (Instabilitäts-Index): `I = Ce / (Ca + Ce)` — 0 = stabil, 1 = instabil
- **Kohäsionstyp:** Funktional (hoch) → Logisch → Sequentiell → Kommunikativ → Prozedural → Zeitlich → Koinzidentell (niedrig)

### 1.7 Leckende Abstraktionen / Leaky Abstractions
Identifiziere konkrete Fälle:
- ORM-/DB-spezifische Typen im Interface
- Raw HTTP-Status-Codes oder Exception-Typen in der UI
- Unstrukturierte LLM-Rohantworten in DB-Spalten
- Plattform-spezifische APIs direkt in Business-Hooks
- Zwei Verbindungen auf dieselbe Ressource (Architekturleck)

---

## Phase 2: Abstraktionsschichten-Design / Abstraction Layer Design

### 2.1 Wrapper & Facade-Ermittlung
Welche Wrappers/Facades fehlen? Für jeden Vorschlag:
- Name und Zweck
- TypeScript/Python/Java Interface-Definition
- Konkrete Implementierungen die das Interface erfüllen sollen

### 2.2 Strategische Entkopplungspunkte / Strategic Decoupling Points
Priorisiere die 3–5 wichtigsten Stellen nach:
- Häufigkeit der erwarteten Änderung (hoch = höhere Priorität)
- Anzahl betroffener Module (viele = höhere Priorität)
- Vendor Lock-in Stärke

### 2.3 Interface-Definitionen / Interface Definitions
Erstelle vollständige Interface-Definitionen in der Zielsprache (TypeScript / Python ABC / Java Interface). Muster:

```typescript
// Beispiel: Austauschbarer Vision-Provider
export interface IVisionProvider {
  readonly providerName: string;
  isAvailable(config: ApiKeyConfig): boolean;
  analyze(inputs: AnalysisInput[], prompt: string, config: ApiKeyConfig): Promise<AnalysisResult>;
}
// Konkrete Implementierungen: OpenAIProvider, AnthropicProvider, FallbackProvider
```

---

## Phase 3: Metriken / Metrics

### 3.1 Zyklomatische Komplexität / Cyclomatic Complexity (CC)
`CC = Entscheidungspunkte + 1`

Zähle als Entscheidungspunkt: `if`, `else if`, `for`, `while`, `do-while`, `case`, `catch`, `&&`, `||`, ternärer Operator, `??`.

**Bewertung:**
| CC | Testbarkeit |
|---|---|
| 1–4 | Sehr gut — einfach unit-testbar |
| 5–7 | Gut — testbar mit wenigen Cases |
| 8–10 | Mittel — refactoring empfohlen |
| 11–15 | Schlecht — aufteilen |
| >15 | **Kritisch** — sofortiger Refactoring-Bedarf |

### 3.2 LCOM (Lack of Cohesion of Methods)
`LCOM4`: Anzahl der unverbundenen Komponentengruppen in einer Klasse/Modul.

- **LCOM4 = 1**: Kohärent — alle Methoden teilen Zustand/Daten
- **LCOM4 = 2–3**: Kandidat für Aufspaltung
- **LCOM4 > 3**: **Aufspaltung dringend empfohlen**

### 3.3 Zusammenfassung / Summary Table

| Modul | CC (max) | LCOM4 | I-Index | SoC-Verletzungen | Priorität |
|---|---|---|---|---|---|
| ... | ... | ... | ... | ... | Hoch/Mittel/Niedrig |

---

## Phase 4: Modernisierungs-Roadmap / Modernization Roadmap

Nachdem Ist-Zustand (Phase 1–3) ermittelt ist, leite die Modernisierung in **sechs aufeinander aufbauenden Stufen** ab. Jede Stufe ist ein Tor (Gate): Eine Stufe wird erst empfohlen, wenn die Eingangskriterien der vorherigen erfüllt sind. Gib pro Stufe immer an: **Eingangskriterium · konkrete Maßnahmen · Erfolgskennzahl (Exit-Kriterium) · Risiko**.

```
Stufe 1            Stufe 2              Stufe 3                Stufe 4         Stufe 5              Stufe 6
Refactoring   ->   Performance /   ->   Refinement /      ->   System- &   ->  Replatforming /  ->  Green-Field
(struktur-         Optimierung          Debt Reduction         Komponenten-    Lift-and-Reshape     Rewrite /
 erhaltend)        (Effizienz)          (Schuldenabbau)        Doku            (Plattformwechsel)   Reengineering
```

> **Grundsatz:** Stufe 1–4 erhalten das Verhalten und reduzieren Risiko. Stufe 5–6 verändern Plattform bzw. Implementierung — sie sind nur sinnvoll, wenn die Codebasis vorher stabilisiert und dokumentiert wurde, oder wenn die Debt so hoch ist, dass ein Rewrite günstiger als weitere Pflege ist (Begründung über Stufe 3 liefern).

### 4.1 Stufe 1 — Refactoring (verhaltenserhaltend)
Strukturverbesserung **ohne** Verhaltensänderung. Voraussetzung: Charakterisierungstests / Sicherheitsnetz vorhanden.
- Wende Refactorings aus `references/refactoring-catalog.md` auf die in Phase 1.5–1.7 + 3.1–3.2 markierten Hotspots an.
- Reihenfolge: erst Funktionen mit **CC > 10** aufteilen, dann Module mit **LCOM4 > 3** zerlegen, dann SoC-Verletzungen entflechten.
- **Exit-Kriterium:** keine Funktion mit CC > 10, kein Modul mit LCOM4 > 3, Tests grün, Verhalten unverändert (Diff-Test gegen Baseline).

**Ausgabe-Tabelle:**
| Hotspot (Datei:Funktion) | Refactoring-Muster | CC vorher → nachher | Aufwand (S/M/L) | Risiko |
|---|---|---|---|---|
| ... | Extract Function / Replace Conditional with Polymorphism / ... | 16 → 4 | M | niedrig |

### 4.2 Stufe 2 — Optimierung & Performance Tuning (Effizienzsteigerung)
Messen → optimieren → erneut messen. **Niemals ohne Profiling optimieren.**
- Folge `references/performance-checklist.md` (Hotpaths, Async/await-Serialisierung, N+1, Caching, Bundle-Size, DB-Indizes, Payload-Größe).
- Priorisiere nach **Amdahl**: optimiere den Pfad mit dem größten Laufzeitanteil zuerst.
- **Exit-Kriterium:** definiertes Budget erreicht (z. B. p95-Latenz, TTI, Speicher, Kosten/Request) und durch Messung belegt.

**Ausgabe-Tabelle:**
| Hotpath | Metrik vorher | Maßnahme | Metrik nachher | Quelle der Messung |
|---|---|---|---|---|
| ... | p95 = 1200 ms | parallele Promise.all statt sequentiell | p95 = 320 ms | Trace / Benchmark |

### 4.3 Stufe 3 — Refinement & Debt Reduction (Schuldenabbau)
Technische Schulden sichtbar machen, klassifizieren und gezielt tilgen.
- Erstelle ein **Debt-Inventar** (siehe `references/refactoring-catalog.md` → Abschnitt Debt-Klassifikation): Typ, Ursache, Zins (laufende Kosten), Tilgungsaufwand.
- Klassifiziere nach **Fowler-Quadrant** (vorsätzlich/unbeabsichtigt × besonnen/leichtsinnig) und priorisiere nach **Zins/Tilgung-Verhältnis**.
- **Wichtig:** Diese Stufe liefert die *Entscheidungsgrundlage* für Stufe 5 vs. 6. Wenn die kumulierte Debt-Tilgung teurer ist als ein Neubau → Empfehlung Richtung Stufe 6 (mit Zahlen begründen).
- **Exit-Kriterium:** Debt-Inventar vollständig, High-Interest-Posten getilgt oder bewusst akzeptiert (dokumentierte ADR).

**Ausgabe-Tabelle:**
| Debt-Posten | Typ | Fowler-Quadrant | Zins (Kosten/Monat) | Tilgung (Aufwand) | Entscheidung |
|---|---|---|---|---|---|
| ... | Code / Design / Test / Doku / Infra | unbeabsichtigt-besonnen | hoch | M | tilgen / akzeptieren |

### 4.4 Stufe 4 — System- & Komponentendokumentation
Den stabilisierten Zustand festhalten — Voraussetzung für jeden Plattform- oder Technologiewechsel.
- **Systemebene:** Kontextdiagramm (C4 L1), Container-Diagramm (C4 L2), Architektur-Entscheidungen als **ADRs**, Qualitätsziele.
- **Komponentenebene:** pro Komponente Zweck, öffentliche Schnittstelle (aus Phase 2 Interfaces übernehmen), Abhängigkeiten (Ca/Ce aus Phase 1.6), Datenflüsse, Fehlerverhalten.
- **Schnittstellen:** alle Grenzschichten aus Phase 1.1 als Vertrag dokumentieren (Request/Response, Auth, Fehlercodes).
- **Exit-Kriterium:** ein neuer Entwickler kann das System ohne Rückfragen verstehen; alle externen Verträge sind dokumentiert.

**Ausgabe:** Strukturierte Doku (Markdown) mit C4-Skizzen, ADR-Liste und Komponenten-Steckbriefen.

### 4.5 Stufe 5 — Replatforming / Lift-and-Reshape
Die Anwendung auf eine neue Plattform/Laufzeit heben und dabei *moderat umformen* — **ohne** Kern-Geschäftslogik neu zu schreiben.
- Folge `references/modernization-playbook.md` → Abschnitt Replatforming.
- Typische Reshapes: Runtime-/Framework-Upgrade, Containerisierung, Managed-Services statt Eigenbetrieb, Austausch der in Phase 1.4 als HOCH bewerteten Vendor-Lock-in-Punkte über die Phase-2-Interfaces.
- **Strangler-Fig** wo möglich: schrittweise Migration hinter einer Fassade, kein Big-Bang.
- **Exit-Kriterium:** läuft auf Zielplattform mit unverändertem Funktionsumfang; Rollback-Pfad existiert.

**Ausgabe-Tabelle:**
| Komponente | heutige Plattform | Zielplattform | Reshape-Typ | Migrationsmuster | Risiko |
|---|---|---|---|---|---|
| ... | Node on VM | Container/Serverless | Containerisierung | Strangler-Fig | mittel |

### 4.6 Stufe 6 — Green-Field Rewrite / Reengineering (komplette Neuentwicklung)
Neubau von Grund auf — nur empfohlen, wenn Stufe 3 dies wirtschaftlich begründet **oder** die Zielarchitektur grundlegend abweicht.
- Folge `references/modernization-playbook.md` → Abschnitt Green-Field & Entscheidungsmatrix (Rewrite vs. Replatform).
- Nutze die Phase-2-Interfaces als **Soll-Architektur-Verträge** und die Phase-4-Doku als **Spezifikation** des Altsystems (so geht kein implizites Wissen verloren).
- Definiere **Parallelbetrieb + Verifikation** (Shadow-Traffic / Dual-Run-Vergleich) und Daten-Migrationsstrategie.
- **Exit-Kriterium:** Neusystem erfüllt die dokumentierten Verträge, Parität nachgewiesen, Altsystem abschaltbar.

**Ausgabe:** Soll-Architektur (Zielbild), Migrations-/Cutover-Plan, Risiko- & Rollback-Strategie, Aufwandsschätzung gegen Stufe 5 abgewogen.

### 4.7 Roadmap-Zusammenfassung / Roadmap Summary
Schließe Phase 4 immer mit dieser Tabelle ab:

| Stufe | Empfohlen? | Voraussetzung erfüllt? | Geschätzter Aufwand | Erwarteter Nutzen | Nächster Schritt |
|---|---|---|---|---|---|
| 1 Refactoring | ja/nein | ... | S/M/L | ... | ... |
| 2 Performance | ja/nein | ... | S/M/L | ... | ... |
| 3 Debt Reduction | ja/nein | ... | S/M/L | ... | ... |
| 4 Dokumentation | ja/nein | ... | S/M/L | ... | ... |
| 5 Replatforming | ja/nein | ... | S/M/L | ... | ... |
| 6 Green-Field Rewrite | ja/nein | ... | S/M/L | ... | ... |

---

## Ausgabeformat / Output Format

Strukturiere die Ausgabe immer so:

1. **Kritische Befunde** (sofortiger Handlungsbedarf) — mit konkreten Code-Beispielen
2. **Hohe Befunde** (nächster Sprint) — mit Interface-Vorschlägen
3. **Mittlere Befunde** (Backlog) — mit kurzer Begründung
4. **Positive Aspekte** — was bereits gut strukturiert ist
5. **Priorisierte Refactoring-Reihenfolge** — Tabelle mit Aufwand und Nutzen

Für jedes Interface immer vollständige TypeScript/Python/Java-Definition, nicht nur den Namen.

---

## Referenzen / References

Detaillierte Checklisten und Beispiele:
- `references/boundary-checklist.md` — Grenzschichten-Checkliste
- `references/interface-templates.md` — Interface-Vorlagen für häufige Muster
- `references/metrics-examples.md` — CC/LCOM Berechnungsbeispiele
- `references/refactoring-catalog.md` — Refactoring-Muster & Debt-Klassifikation (Phase 4.1 + 4.3)
- `references/performance-checklist.md` — Performance-/Effizienz-Checkliste (Phase 4.2)
- `references/modernization-playbook.md` — Replatforming vs. Green-Field Rewrite (Phase 4.5 + 4.6)

---

## Beispiel-Trigger / Example Triggers

- "Führe eine Architekturanalyse durch"
- "Erstelle eine Programmableitung für [System]"
- "Welche Abstraktionsschichten fehlen?"
- "Berechne die zyklomatische Komplexität"
- "Analysiere den Vendor Lock-in"
- "Wo sind die strategischen Entkopplungspunkte?"
- "Erstelle eine Modernisierungs-Roadmap / Refactoring-Plan"
- "Plane Performance-Tuning / Effizienzsteigerung"
- "Analysiere die technischen Schulden / Debt Reduction"
- "Erstelle die System- und Komponentendokumentation"
- "Replatforming / Lift-and-Reshape planen"
- "Green-Field Rewrite / Reengineering ableiten"
- "Perform a program derivation / architecture analysis"
- "What interfaces are missing?"
- "Analyze coupling and cohesion"
- "Create a modernization roadmap / refactoring plan"
- "Plan performance tuning / optimization"
- "Assess technical debt / debt reduction"
- "Replatforming / lift-and-reshape vs. green-field rewrite"
