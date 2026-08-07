# Portiert den Quellcode aller drei Repositories in sechs Zielsprachen
# Reine Standardbibliothek — kein pip-Schritt noetig, das Abbild bleibt klein.
FROM python:3.12-alpine

LABEL org.opencontainers.image.title="abstractions-manager"
LABEL org.opencontainers.image.description="Portiert den Quellcode dreier Repositories in sechs Zielsprachen"
LABEL org.opencontainers.image.source="https://github.com/KikiKari/Projects"
LABEL org.opencontainers.image.licenses="MIT"

WORKDIR /app
COPY . /app

# Ein Beobachter braucht keine Root-Rechte.
# Der Manager schreibt sein Protokoll nach
# /home/openclaw/.openclaw/workspace/logs. Dieser Pfad stammt aus der
# OpenClaw-Umgebung und existiert im Abbild nicht — ohne ihn scheitert
# schon der Logger-Aufbau, und mit restart: unless-stopped laeuft der
# Container in eine Neustartschleife. Also anlegen und uebereignen.
RUN apk add --no-cache git \
 && adduser -D -H -u 10001 lauf \
 && mkdir -p /home/openclaw/.openclaw/workspace/logs \
 && chown -R lauf:lauf /app /home/openclaw
USER lauf

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 TZ=Europe/Berlin

# Der Container haelt den veroeffentlichten Bestand aktuell: alle zwoelf
# Stunden wird Projects@abstractions nachgezogen. Das Portieren selbst laeuft
# in GitHub Actions (.github/workflows/abstraktionen.yml), weil dort der
# Modellschluessel liegt und der Lauf unabhaengig von diesem Rechner ist.
CMD ["sh", "abstractions/abgleich.sh"]
