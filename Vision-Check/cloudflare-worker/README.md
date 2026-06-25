# Vision-Check — Cloudflare Worker CORS-Proxy

Leitet Browser-Anfragen an `api.anthropic.com` weiter (Browser blockiert direkte Calls wegen CORS).

## Deploy (einmalig, ~2 Minuten)

```bash
# 1. Wrangler installieren (falls nicht vorhanden)
npm install -g wrangler

# 2. Einloggen
wrangler login

# 3. Deployen
wrangler deploy worker.js --name vision-check-proxy
```

Nach dem Deploy erscheint die URL:
```
https://vision-check-proxy.<dein-account>.workers.dev
```

## In Vision-Check eintragen

Einstellungen öffnen → Tab **Basis Vision-APIs** → Feld **Claude CORS-Proxy URL** → Worker-URL einfügen.

## Sicherheit

- Nur `POST /v1/messages` wird durchgeleitet
- Origins werden geprüft (in `ALLOWED_ORIGINS` anpassen)
- Kein API-Key im Worker gespeichert — der Key kommt vom Browser im `x-api-key` Header
- Cloudflare Free Tier: 100.000 Requests/Tag kostenlos

## Kosten

| Tier | Requests/Tag | Preis |
|---|---|---|
| Free | 100.000 | $0 |
| Paid | unbegrenzt | $0.50 / 1 Mio. |
