# CC / LCOM Berechnungsbeispiele / Calculation Examples

## Zyklomatische Komplexität (CC)

### Beispiel 1 — Einfache Funktion (CC = 1)
```typescript
function greet(name: string): string {
  return `Hello, ${name}`;
}
// Entscheidungspunkte: 0 → CC = 1
```

### Beispiel 2 — Moderate Funktion (CC = 4)
```typescript
function classify(speed: number): string {
  if (speed < 0.5) return 'stationary';      // +1
  if (speed < 2.5) return 'walking';         // +1
  if (speed < 8.5) return 'cycling';         // +1
  return 'vehicle';
}
// Entscheidungspunkte: 3 → CC = 4
```

### Beispiel 3 — Kritische Funktion (CC = 16)
```typescript
async function handleCheck(req, res) {        // +1 (Basis)
  try {
    if (!lat || !lng) return res.status(400); // +1
    if (typeof label !== 'string') return;    // +1
    if (label.length > 200) return;           // +1
    if (isNaN(lat) || isNaN(lng)) return;     // +2 (&&)
    if (lat < -90 || lat > 90) return;        // +2 (||)
    // ... fire-and-forget IIFE
    try {
      if (photos.length > 0) {               // +1
        const hasOpenAI = !!(key || env);    // +1 (||)
        const hasClaude = !!(key || env);    // +1 (||)
        if (!hasOpenAI && !hasClaude) ...    // +2 (&&)
        if (r.status === 'fulfilled') ...    // +1
      }
    } catch (e) { ... }                      // +1
  } catch (e) { ... }                        // +1
}
// CC ≈ 16 → Kritisch, sofort aufteilen
```

## LCOM4 Berechnung

### LCOM4 = 1 (kohärent)
```
Klasse SonarAudio:
  - Methoden: ping(), scan(), startContinuous(), stopContinuous()
  - Alle teilen: this.ctx, this.intervalId, this.enabled
  → Eine verbundene Gruppe → LCOM4 = 1 ✓
```

### LCOM4 = 7 (unkohärent — aufteilen)
```
Modul routes.ts:
  Gruppe 1: analyzeWithGPT4o, analyzeWithClaude, analyzeWithMoondream
  Gruppe 2: callWeatherComputer
  Gruppe 3: parseWeatherResponse
  Gruppe 4: getStoredConfig, storeConfig
  Gruppe 5: listLocations, addLocation, deleteLocation
  Gruppe 6: haversineM, classifyMovement, calcReturnWindow
  Gruppe 7: inBoundingBox + NINA/DWD Warnungs-Handler
  → 7 unverbundene Gruppen → LCOM4 = 7 → in 7 Module aufteilen
```

## Instabilitäts-Index I

```
I = Ce / (Ca + Ce)

Modul A: Ca=3, Ce=1 → I = 1/(3+1) = 0.25 → stabil (viele abhängig davon)
Modul B: Ca=1, Ce=8 → I = 8/(1+8) = 0.89 → instabil (hängt von vielen ab)
Modul C: Ca=0, Ce=5 → I = 5/(0+5) = 1.00 → maximal instabil (Einstiegspunkt, normal)
```

**Ziel:** Stabile Module (I nahe 0) sollten abstrakt sein (Interfaces).
Instabile Module (I nahe 1) können konkret sein (Implementierungen).
