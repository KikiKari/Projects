/**
 * Vision-Check — Cloudflare Worker CORS-Proxy
 * Leitet Browser-Requests an api.anthropic.com weiter.
 *
 * Deploy:
 *   npx wrangler deploy worker.js --name vision-check-proxy
 *
 * Kostenlos: 100.000 Requests/Tag (Cloudflare Free Tier)
 * Die URL des deployten Workers in Vision-Check Einstellungen → "Claude CORS-Proxy URL" eintragen.
 */

const ANTHROPIC_API = 'https://api.anthropic.com';

// Erlaubte Origins (auf deine Domains anpassen)
const ALLOWED_ORIGINS = [
  'https://vision-check-pink.vercel.app',
  'https://www.perplexity.ai',
  'http://localhost:3000',
  'http://localhost:5173',
  // Für lokale Entwicklung alle Origins erlauben:
  // '*'
];

export default {
  async fetch(request, env, ctx) {
    const origin = request.headers.get('Origin') || '';

    // OPTIONS Preflight
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        status: 204,
        headers: corsHeaders(origin),
      });
    }

    // Nur POST erlauben
    if (request.method !== 'POST') {
      return new Response('Method not allowed', { status: 405 });
    }

    // Origin prüfen
    if (!isAllowedOrigin(origin)) {
      return new Response('Forbidden', { status: 403 });
    }

    // URL aufbauen: Worker-Pfad → Anthropic-Pfad
    // Aufruf: POST https://worker.url/v1/messages
    // → Weiterleitung: POST https://api.anthropic.com/v1/messages
    const url = new URL(request.url);
    const targetURL = `${ANTHROPIC_API}${url.pathname}${url.search}`;

    // Original-Headers durchleiten, Host anpassen
    const headers = new Headers(request.headers);
    headers.set('Host', 'api.anthropic.com');
    // Origin-Header entfernen (Anthropic API braucht ihn nicht)
    headers.delete('Origin');
    headers.delete('Referer');

    // Body durchleiten
    const body = await request.arrayBuffer();

    let anthropicResponse;
    try {
      anthropicResponse = await fetch(targetURL, {
        method: 'POST',
        headers,
        body,
      });
    } catch (err) {
      return new Response(
        JSON.stringify({ error: { type: 'proxy_error', message: err.message } }),
        { status: 502, headers: { 'Content-Type': 'application/json', ...corsHeaders(origin) } }
      );
    }

    // Anthropic-Antwort mit CORS-Headers zurückgeben
    const responseHeaders = new Headers(anthropicResponse.headers);
    const cors = corsHeaders(origin);
    for (const [key, value] of Object.entries(cors)) {
      responseHeaders.set(key, value);
    }
    // Content-Type sicherstellen
    if (!responseHeaders.has('Content-Type')) {
      responseHeaders.set('Content-Type', 'application/json');
    }

    return new Response(anthropicResponse.body, {
      status: anthropicResponse.status,
      statusText: anthropicResponse.statusText,
      headers: responseHeaders,
    });
  },
};

function isAllowedOrigin(origin) {
  if (ALLOWED_ORIGINS.includes('*')) return true;
  return ALLOWED_ORIGINS.some(allowed => origin === allowed || origin.endsWith('.vercel.app'));
}

function corsHeaders(origin) {
  const allowedOrigin = isAllowedOrigin(origin) ? origin : ALLOWED_ORIGINS[0];
  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, x-api-key, anthropic-version, anthropic-beta',
    'Access-Control-Max-Age': '86400',
  };
}
