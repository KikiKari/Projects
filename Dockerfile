# Portiert OpenClaw-Scripts in zehn Zielsprachen
# Reine Standardbibliothek — kein pip-Schritt noetig, das Abbild bleibt klein.
FROM python:3.12-alpine

LABEL org.opencontainers.image.title="abstractions-manager"
LABEL org.opencontainers.image.description="Portiert OpenClaw-Scripts in zehn Zielsprachen"
LABEL org.opencontainers.image.source="https://github.com/KikiKari/Projects"
LABEL org.opencontainers.image.licenses="MIT"

WORKDIR /app
COPY . /app

# Ein Beobachter braucht keine Root-Rechte.
RUN adduser -D -H -u 10001 lauf && chown -R lauf:lauf /app
USER lauf

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 TZ=Europe/Berlin

CMD ["sh", "-c", "python abstractions/ABSTRACTIONS_MANAGER.py"]
