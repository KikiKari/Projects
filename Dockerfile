# Telegram Monitor — Dauerbetrieb im Container.
#
# Der Kern braucht nur die Standardbibliothek. Telethon (Methode 3, echte
# Kanalsuche) wird mitinstalliert, weil es im Container nichts kostet ausser
# Platz und der Nutzer sonst spaeter nachbauen muesste.

FROM python:3.12-slim

# Zeitzone, damit Zeitstempel im Protokoll zu den Windows-Uhrzeiten passen.
ENV TZ=Europe/Berlin \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /app

# Erst nur die Abhaengigkeiten — so bleibt die Schicht im Zwischenspeicher,
# solange sich requirements.txt nicht aendert.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY tgmon/ ./tgmon/
COPY web/ ./web/
COPY server.py cli.py ./
COPY config.example.json ./

# data/ ist ein Volume — der Ordner muss existieren, bevor es eingehaengt wird.
RUN mkdir -p /app/data/live

# Nicht als root laufen. Die Nummer 10001 ist frei gewaehlt und liegt oberhalb
# der Systemkonten.
RUN useradd --uid 10001 --create-home --shell /usr/sbin/nologin monitor \
 && chown -R monitor:monitor /app
USER monitor

EXPOSE 8765

# Im Container muss auf 0.0.0.0 gehoert werden, sonst ist der Dienst von
# ausserhalb des Containers nicht erreichbar — auch nicht ueber die
# veroeffentlichte Portweiterleitung. Nach aussen dicht macht compose,
# indem es nur an 127.0.0.1 des Rechners bindet.
CMD ["python", "server.py", "--host", "0.0.0.0", "--port", "8765", \
     "--poll-interval", "120", "--no-browser"]
