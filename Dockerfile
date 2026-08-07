# Bidirektionaler Abgleich ClawHub und Git
# Reine Standardbibliothek — kein pip-Schritt noetig, das Abbild bleibt klein.
FROM python:3.12-alpine

LABEL org.opencontainers.image.title="clawhub-sync"
LABEL org.opencontainers.image.description="Bidirektionaler Abgleich ClawHub und Git"
LABEL org.opencontainers.image.source="https://github.com/KikiKari/Projects"
LABEL org.opencontainers.image.licenses="MIT"

WORKDIR /app
COPY . /app

# Ein Beobachter braucht keine Root-Rechte.
RUN adduser -D -H -u 10001 lauf && chown -R lauf:lauf /app
USER lauf

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 TZ=Europe/Berlin

# sync_agent.py importiert das Modul sync_clawhub_git, das in diesem Branch
# nicht liegt — der Lauf bricht sofort mit ModuleNotFoundError ab, und mit
# restart: unless-stopped wird daraus eine Neustartschleife. Solange das
# Modul fehlt, bleibt der Container bereit statt zu kreisen:
#
#   docker exec clawhub-sync python clawhub/Skills/sync_agent.py --dry-run
#
# Sobald sync_clawhub_git.py neben sync_agent.py liegt, kann hier wieder
# der direkte Aufruf stehen.
CMD ["sleep", "infinity"]
