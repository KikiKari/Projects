# Diagnose fremder MCP-Server, lokale Weboberflaeche
# Reine Standardbibliothek — kein pip-Schritt noetig, das Abbild bleibt klein.
FROM python:3.12-alpine

LABEL org.opencontainers.image.title="mcp-server-monitor"
LABEL org.opencontainers.image.description="Diagnose fremder MCP-Server, lokale Weboberflaeche"
LABEL org.opencontainers.image.source="https://github.com/KikiKari/Projects"
LABEL org.opencontainers.image.licenses="MIT"

WORKDIR /app
COPY . /app

# Ein Beobachter braucht keine Root-Rechte.
RUN adduser -D -H -u 10001 lauf && chown -R lauf:lauf /app
USER lauf

ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 TZ=Europe/Berlin

EXPOSE 8787
HEALTHCHECK --interval=60s --timeout=10s --start-period=20s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://127.0.0.1:8787/api/states', timeout=5).status==200 else 1)"

CMD ["sh", "-c", "python server.py"]
