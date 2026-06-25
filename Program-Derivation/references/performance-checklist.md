# Performance- & Effizienz-Checkliste / Performance Checklist

Gehört zu **Phase 4.2 (Optimierung & Performance Tuning)**.

---

## 0. Grundprinzipien / Principles

> **Messen vor Optimieren.** Optimierung ohne Profiling ist Raten.

- **Amdahl:** Optimiere zuerst den Pfad mit dem größten Anteil an der Gesamtlaufzeit. 90 % Beschleunigung eines 2 %-Pfads bringt fast nichts.
- **Budget definieren:** p50/p95-Latenz, Time-to-Interactive, RAM, Kosten/Request — Zielwert vor Beginn festlegen.
- **Eine Änderung, eine Messung.** Sonst weiß man nicht, was gewirkt hat.

---

## 1. Profiling & Messung
- [ ] Repräsentatives Lastprofil vorhanden (realistische Daten/Concurrency)?
- [ ] Server: CPU-/Flamegraph, Event-Loop-Lag gemessen?
- [ ] Frontend: Lighthouse, Web Vitals (LCP, INP, CLS), Bundle-Analyzer?
- [ ] DB: langsame Queries geloggt (EXPLAIN ANALYZE)?
- [ ] Baseline-Zahlen dokumentiert (für Vorher/Nachher-Tabelle)?

## 2. Async & Nebenläufigkeit (häufigster Node-Hotspot)
- [ ] Unabhängige `await`s parallelisiert (`Promise.all` / `Promise.allSettled`) statt sequentiell?
- [ ] Keine `await` in Schleifen, wo Batch möglich ist?
- [ ] Fire-and-forget-Tasks in echte Queue/Worker verschoben (statt Request zu blockieren)?
- [ ] CPU-lastige Arbeit aus dem Event-Loop in Worker-Threads/Subprozesse ausgelagert?
- [ ] Timeouts + AbortSignal für externe Calls gesetzt?

## 3. Datenbank & Datenzugriff
- [ ] N+1-Queries eliminiert (Join / Batch / DataLoader)?
- [ ] Indizes auf Filter-/Join-Spalten vorhanden?
- [ ] Nur benötigte Spalten selektiert (kein `SELECT *`)?
- [ ] Connection-Pooling aktiv, nur **eine** Verbindung pro DB-Datei (s. boundary-checklist)?
- [ ] Paginierung statt Vollabruf großer Tabellen?
- [ ] Prepared Statements wiederverwendet?

## 4. Caching
- [ ] Wiederholte teure Berechnungen memoisiert?
- [ ] HTTP-Caching/ETags für statische/halbstatische Responses?
- [ ] Cache-Invalidierung definiert (kein Stale-Data-Risiko)?
- [ ] CDN für Assets?

## 5. Netzwerk & Payload
- [ ] Responses komprimiert (gzip/brotli)?
- [ ] Payloads minimal (keine ungenutzten Felder)?
- [ ] Externe API-Calls gebündelt/dedupliziert?
- [ ] Streaming statt Vollpuffer bei großen Antworten?

## 6. Frontend / PWA
- [ ] Code-Splitting & Lazy-Loading von Routen/Komponenten?
- [ ] Tree-Shaking aktiv, ungenutzte Deps entfernt?
- [ ] Bilder optimiert (WebP/AVIF, responsive, lazy)?
- [ ] Service-Worker-Caching-Strategie passend (cache-first vs. network-first)?
- [ ] Render-Blocking-Ressourcen minimiert (kritisches CSS inline)?
- [ ] Re-Renders reduziert (Memoization, stabile Keys)?

## 7. Speicher & Ressourcen
- [ ] Keine Memory-Leaks (Listener/Intervalle/Subscriptions aufgeräumt)?
- [ ] Große Objekte nicht unnötig im Speicher gehalten?
- [ ] Streams geschlossen, Dateihandles freigegeben?

## 8. Kosten-Effizienz (Cloud / LLM)
- [ ] LLM/Vision-Calls nur wenn nötig, mit Cache/Batching?
- [ ] Günstigeres Modell wo Qualität reicht?
- [ ] Autoscaling/Right-Sizing der Instanzen?
- [ ] Kosten pro Request gemessen und budgetiert?

---

## Ausgabe-Tabelle (Phase 4.2)
| Hotpath | Metrik vorher | Maßnahme | Metrik nachher | Δ | Messquelle |
|---|---|---|---|---|---|
| ... | p95 = 1200 ms | Promise.all statt sequentiell | p95 = 320 ms | −73 % | Trace |

**Abschluss:** Optimierung beenden, sobald das definierte Budget erreicht ist — nicht weiter mikrooptimieren (vorzeitige Optimierung ist selbst eine Schuld).
