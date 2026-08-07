# Lokaler Regen-Check, PWA
# Statische Auslieferung — kein Build, nur Dateien und ein schlanker Webserver.
FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="weather-check"
LABEL org.opencontainers.image.description="Lokaler Regen-Check, PWA"
LABEL org.opencontainers.image.source="https://github.com/KikiKari/Projects"
LABEL org.opencontainers.image.licenses="MIT"

COPY Weather-Check/ /usr/share/nginx/html/

# Sicherheitskopfzeilen — dieselben wie in vercel.json, damit lokal und
# gehostet dasselbe Verhalten gilt.
RUN printf '%s\n' \
  'add_header X-Content-Type-Options "nosniff" always;' \
  'add_header Referrer-Policy "strict-origin-when-cross-origin" always;' \
  'add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;' \
  > /etc/nginx/conf.d/kopfzeilen.conf \
 && sed -i '/location \/ {/r /etc/nginx/conf.d/kopfzeilen.conf' /etc/nginx/conf.d/default.conf

EXPOSE 80
HEALTHCHECK --interval=60s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- http://127.0.0.1/ >/dev/null 2>&1 || exit 1
