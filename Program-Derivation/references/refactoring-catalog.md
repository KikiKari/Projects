# Refactoring-Katalog & Debt-Klassifikation / Refactoring Catalog & Debt Classification

Gehört zu **Phase 4.1 (Refactoring)** und **Phase 4.3 (Debt Reduction)**.

---

## 1. Grundregel / Golden Rule

> Refactoring = Struktur ändern, Verhalten **nicht**. Ohne Sicherheitsnetz (Tests) kein Refactoring.

Wenn keine Tests existieren: zuerst **Charakterisierungstests** (Characterization Tests) schreiben, die das aktuelle Verhalten festschreiben (auch wenn es „falsch" ist), dann refactoren.

---

## 2. Refactoring-Muster nach Symptom / Patterns by Smell

| Code-Smell (Symptom) | Empfohlenes Refactoring | Wirkung auf Metrik |
|---|---|---|
| Lange Funktion, CC > 10 | **Extract Function**, **Decompose Conditional** | CC ↓ pro Funktion |
| Verschachtelte `if/else`-Ketten | **Replace Nested Conditional with Guard Clauses** | CC ↓, Lesbarkeit ↑ |
| `switch`/`if` auf Typ-Feld | **Replace Conditional with Polymorphism** / Strategy | CC ↓, OCP ↑ |
| Modul mit LCOM4 > 3 | **Extract Class** / **Split Module** | LCOM4 → 1 pro Teil |
| Duplizierte Logik (abweichende Konstanten) | **Extract Function** + zentrale Konstante | SoC-Verletzung ↓ |
| Business-Logik in Routing/Controller | **Extract Service Layer** | SoC ↑, Ca/Ce sauberer |
| Hardgecodete Provider-URL/Model | **Introduce Interface** (Provider-Pattern, s. interface-templates.md) | Vendor Lock-in ↓ |
| Leaky Abstraction (DB-Typ im Interface) | **Introduce DTO / Mapper** | Kopplung ↓ |
| Lange Parameterliste | **Introduce Parameter Object** | Lesbarkeit ↑ |
| Fire-and-forget IIFE mit Fehlerschlucken | **Extract + explizites Error-Handling / Queue** | Robustheit ↑ |
| Feature Envy (greift ständig auf fremdes Objekt zu) | **Move Function** | Kohäsion ↑ |
| Magic Numbers/Strings | **Replace Magic Literal with Constant** | Wartbarkeit ↑ |

---

## 3. Sichere Refactoring-Schrittfolge / Safe Sequence

1. Baseline messen (CC, LCOM4, Tests grün, ggf. Output-Snapshot).
2. **Eine** Transformation anwenden (klein, atomar).
3. Tests laufen lassen → grün?
4. Commit. Wiederholen.
5. Nach jedem Hotspot: Metrik gegen Baseline vergleichen, in Phase-4.1-Tabelle eintragen.

Niemals mehrere Refactorings + Verhaltensänderung in einem Commit mischen.

---

## 4. Debt-Klassifikation / Technical Debt Classification (Phase 4.3)

### 4.1 Fowler-Quadrant
Klassifiziere jeden Debt-Posten:

|  | **Besonnen (prudent)** | **Leichtsinnig (reckless)** |
|---|---|---|
| **Vorsätzlich (deliberate)** | „Wir liefern jetzt, räumen später auf" (bewusst, dokumentiert) | „Keine Zeit für Design" |
| **Unbeabsichtigt (inadvertent)** | „Jetzt wissen wir, wie es richtig geht" | „Was ist Schichtenarchitektur?" |

→ **Leichtsinnige** Schulden zuerst tilgen; **besonnen-vorsätzliche** bewusst terminieren.

### 4.2 Debt-Typen
- **Code Debt** — Smells, Duplikate, hohe CC.
- **Design/Architektur Debt** — SoC-Verletzungen, fehlende Interfaces, Vendor Lock-in.
- **Test Debt** — fehlende/instabile Tests, geringe Abdeckung kritischer Pfade.
- **Doku Debt** — fehlende ADRs, veraltete Schnittstellenbeschreibung.
- **Infra/Dependency Debt** — veraltete Runtimes, ungepatchte CVEs, EOL-Bibliotheken.

### 4.3 Priorisierung: Zins/Tilgung-Verhältnis
- **Zins (Interest):** laufende Mehrkosten pro Zeiteinheit (langsamere Features, Bugs, Sicherheitsrisiko).
- **Tilgung (Principal):** einmaliger Aufwand zur Behebung.
- **Priorität = Zins / Tilgung.** Hoher Zins + niedrige Tilgung = sofort tilgen.

### 4.4 Debt-Inventar-Tabelle (Vorlage)
| Posten | Typ | Fowler-Quadrant | Zins | Tilgung | Zins/Tilgung | Entscheidung |
|---|---|---|---|---|---|---|
| ... | Code/Design/Test/Doku/Infra | ... | hoch/mittel/niedrig | S/M/L | ... | tilgen/terminieren/akzeptieren |

### 4.5 Übergang zu Stufe 5/6
Summiere die Tilgungsaufwände der **akzeptanzunfähigen** Posten. Wenn diese Summe an einen Neubau-Aufwand heranreicht **und** die Architektur grundlegend abweicht → Empfehlung Richtung **Phase 4.6 (Green-Field)** statt weiterer Tilgung. Andernfalls inkrementelle Tilgung + **Phase 4.5 (Replatforming)**.
