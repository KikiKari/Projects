# TikTok-LIVE-Monitor als Datenprovider
# Reine Standardbibliothek — kein pip-Schritt noetig, das Abbild bleibt klein.
FROM python:3.12-alpine

LABEL org.opencontainers.image.title="tt-live"
LABEL org.opencontainers.image.description="TikTok-LIVE-Monitor als Datenprovider"
LABEL org.opencontainers.image.source="https://github.com/KikiKari/Projects"
LABEL org.opencontainers.image.licenses="MIT"

WORKDIR /app
COPY . /app

# Ein Beobachter braucht keine Root-Rechte.
RUN adduser -D -H -u 10001 lauf && chown -R lauf:lauf /app
USER lauf

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 TZ=Europe/Berlin

# tt-live ist ein Kommandozeilen-Werkzeug, kein Dienst. Ein CMD, das sich
# sofort beendet, laeuft mit restart: unless-stopped in eine Endlosschleife.
# Der Container bleibt deshalb bereit und wird per docker exec benutzt:
#
#   docker exec tt-live python tiktok-monitor/tt_live.py check @name
#   docker exec tt-live python tiktok-monitor/tt_live.py daemon @name --dauer 3h
CMD ["sleep", "infinity"]
