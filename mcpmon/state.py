"""Die fuenf Zustaende eines MCP-Servers und der jeweils naechste Schritt.

Fast jede Frage nach einem MCP-Server ist in Wahrheit eine Zustandsfrage.
Wer den Zustand feststellt, hat die Antwort meist schon.
"""
from dataclasses import dataclass, field

OPEN = "1-offen"
CONNECTED_WITH_TOOLS = "2-verbunden-mit-tools"
CONNECTED_NO_TOOLS = "3-verbunden-ohne-tools"
INSTALLED_UNAUTHED = "4-installiert-unangemeldet"
ABSENT = "5-nicht-vorhanden"

ZUSTAENDE = {
    OPEN: (
        "Offen",
        "Tools vorhanden, nie etwas angemeldet",
        "Direkt benutzen.",
    ),
    CONNECTED_WITH_TOOLS: (
        "Verbunden, mit Tools",
        "Konnektor mit Haekchen, Tools vorhanden",
        "Direkt benutzen.",
    ),
    CONNECTED_NO_TOOLS: (
        "Verbunden, ohne Tools",
        "Konnektor mit Haekchen, aber keine Tools",
        "Pruefen, ob der Konnektor ueberhaupt Tools liefert; danach die erteilten "
        "Scopes pruefen. Die Tool-Liste ist scope-gefiltert.",
    ),
    INSTALLED_UNAUTHED: (
        "Installiert, unangemeldet",
        "Server gelistet, Tools fehlen, Meldung 'benoetigt Authentifizierung'",
        "Anmelden. Braucht eine interaktive Sitzung — in einer nicht-interaktiven "
        "Sitzung startet kein OAuth-Flow.",
    ),
    ABSENT: (
        "Nicht vorhanden",
        "nichts",
        "Discovery laufen lassen, dann als Konnektor eintragen.",
    ),
}


@dataclass
class Befund:
    """Ergebnis einer Zustandsbestimmung."""

    zustand: str
    schritt: str
    begruendung: list = field(default_factory=list)
    warnungen: list = field(default_factory=list)

    @property
    def titel(self):
        return ZUSTAENDE[self.zustand][0]

    def as_dict(self):
        return {
            "zustand": self.zustand,
            "titel": self.titel,
            "schritt": self.schritt,
            "begruendung": self.begruendung,
            "warnungen": self.warnungen,
        }


def bestimme(hat_tools, ist_gelistet=False, hat_haekchen=False,
             meldet_auth_noetig=False, auch_als_plugin=False,
             je_angemeldet=False):
    """Bildet die beobachteten Signale auf einen der fuenf Zustaende ab.

    Reihenfolge der Signale ist bewusst: Tools sind das verlaesslichste Signal,
    weil Tool-Listen scope-gefiltert sind — was da ist, ist auch nutzbar.
    """
    warnungen = []
    if auch_als_plugin:
        warnungen.append(
            "Der Name laeuft auch als plugin:… — das ist ein zweiter, separat "
            "anzumeldender Server, nicht derselbe wie der Konnektor. "
            "Konnektoren haengen am Konto (Anpassen -> Konnektoren), "
            "Plugins bringen eigene MCP-Server mit."
        )

    if hat_tools:
        if je_angemeldet or hat_haekchen:
            z = CONNECTED_WITH_TOOLS
            grund = ["Tools vorhanden", "Konnektor verbunden"]
        else:
            z = OPEN
            grund = ["Tools vorhanden", "nie etwas angemeldet"]
    elif meldet_auth_noetig:
        z = INSTALLED_UNAUTHED
        grund = ["Server gelistet", "keine Tools", "meldet 'benoetigt Authentifizierung'"]
    elif hat_haekchen or (ist_gelistet and not meldet_auth_noetig):
        z = CONNECTED_NO_TOOLS
        grund = ["Konnektor gelistet/verbunden", "aber keine Tools"]
        warnungen.append(
            "Zustand 3 wird oft als Fehler missverstanden. Ein Konnektor kann "
            "verbunden sein und trotzdem keine Tools mitbringen, weil er gar "
            "keine liefert — die GitHub-Integration ist so ein Fall. "
            "Lies die Beschreibung des Konnektors, bevor du einen Fehler vermutest."
        )
    else:
        z = ABSENT
        grund = ["weder Tools noch Eintrag in der Konnektoren-Liste"]

    return Befund(zustand=z, schritt=ZUSTAENDE[z][2],
                  begruendung=grund, warnungen=warnungen)


FEHLERBILDER = [
    ("Verbunden, aber keine Tools",
     "Konnektor liefert keine Tools, oder Scope fehlt"),
    ("Name doppelt: verbunden und 'benoetigt Auth'",
     "Konnektor und Plugin-Server verwechselt"),
    ("invalid_scope",
     "Mehr angefragt, als der Client registriert hat"),
    ("Server haengt dauerhaft in 'connecting'",
     "Endpunkt falsch, Netz blockiert, oder Server unten"),
    ("401 nach Wochen problemlosen Betriebs",
     "Refresh-Token abgelaufen oder widerrufen — neu anmelden"),
    ("Manuell eingetragener Server bleibt stumm",
     "MSIX-Pfadfalle, oder App nicht neu gestartet"),
    ("Tools nach Update verschwunden",
     "Server neu verbunden, Scopes neu erteilen"),
]
