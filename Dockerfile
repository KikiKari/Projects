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
# Der Manager schreibt sein Protokoll nach
# /home/openclaw/.openclaw/workspace/logs. Dieser Pfad stammt aus der
# OpenClaw-Umgebung und existiert im Abbild nicht — ohne ihn scheitert
# schon der Logger-Aufbau, und mit restart: unless-stopped laeuft der
# Container in eine Neustartschleife. Also anlegen und uebereignen.
RUN adduser -D -H -u 10001 lauf \
 && mkdir -p /home/openclaw/.openclaw/workspace/logs \
 && chown -R lauf:lauf /app /home/openclaw
USER lauf

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 TZ=Europe/Berlin

# Der Manager ist ein Stapellauf, kein Dienst: er arbeitet seine Prioritaeten
# ab, meldet "Abgeschlossen" und beendet sich. Mit restart: unless-stopped
# wird daraus eine Neustartschleife mit wachsender Wartezeit. Der Container
# bleibt deshalb bereit; der Lauf wird angestossen, wenn er gebraucht wird:
#
#   docker exec abstractions-manager python abstractions/ABSTRACTIONS_MANAGER.py
#
# Fuer einen regelmaessigen Lauf eignet sich die Aufgabenplanung von Windows
# oder ein Zeitplan-Dienst, der genau diesen Befehl aufruft.
CMD ["sleep", "infinity"]
