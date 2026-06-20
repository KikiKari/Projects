# Interface-Vorlagen / Interface Templates

## Provider-Pattern (austauschbarer Dienst)

```typescript
// Für: KI-APIs, Warnungs-Dienste, Geocoding, etc.
export interface IProvider<TInput, TOutput> {
  readonly providerName: string;
  isAvailable(config?: Record<string, string>): boolean;
  execute(input: TInput, config?: Record<string, string>): Promise<TOutput>;
}
```

## Repository-Pattern (Datenspeicher)

```typescript
export interface IRepository<T, TInsert> {
  findById(id: number): T | undefined;
  findAll(): T[];
  create(data: TInsert): T;
  update(id: number, patch: Partial<T>): T | undefined;
  delete(id: number): boolean;
}
```

## Aggregator-Pattern (mehrere Provider bündeln)

```typescript
export class ProviderAggregator<TInput, TOutput> {
  constructor(private providers: IProvider<TInput, TOutput>[]) {}

  async executeAll(input: TInput, config?: Record<string, string>): Promise<TOutput[]> {
    const results = await Promise.allSettled(
      this.providers
        .filter(p => p.isAvailable(config))
        .map(p => p.execute(input, config))
    );
    return results
      .filter((r): r is PromiseFulfilledResult<TOutput> => r.status === 'fulfilled')
      .map(r => r.value);
  }
}
```

## Config-Repository-Pattern

```typescript
export interface IConfigRepository<T> {
  load(): T | null;
  save(config: T): void;
  clear(): void;
}
// Implementierungen: SQLiteConfigRepository, EnvConfigRepository, InMemoryConfigRepository
```

## Audio-Engine-Pattern

```typescript
export interface IAudioEngine {
  init(): Promise<void>;
  setEnabled(on: boolean): void;
  setVolume(vol: number): void; // 0–1
  notify(type: 'scan' | 'ready' | 'warning' | 'clear', urgency?: number): void;
  startContinuous(score: number): void;
  stopContinuous(): void;
  readonly isEnabled: boolean;
}
```

## Warning-Provider-Pattern

```typescript
export interface IWarningProvider {
  readonly sourceName: string;
  getWarnings(lat: number, lng: number, radiusKm?: number): Promise<Warning[]>;
}

export interface Warning {
  id: string;
  type: string;
  severity: 'Minor' | 'Moderate' | 'Severe' | 'Extreme' | 'Unknown';
  headline: string;
  description: string;
  validFrom: string | null;
  validTo: string | null;
  source: string;
}
```
