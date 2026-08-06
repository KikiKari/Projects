"""Textausgabe der Befunde — bewusst schmucklos, damit sie in jedes Terminal passt."""
from . import state


def _linie(z="-", n=64):
    return z * n


def zustandstabelle():
    zeilen = ["Die fuenf Zustaende", _linie("=")]
    for key, (titel, erkennbar, schritt) in state.ZUSTAENDE.items():
        zeilen += [f"[{key}] {titel}",
                   f"    erkennbar an : {erkennbar}",
                   f"    naechster Schritt: {schritt}", ""]
    return "\n".join(zeilen)


def fehlerbilder():
    zeilen = ["Fehlerbilder", _linie("=")]
    for bild, ursache in state.FEHLERBILDER:
        zeilen.append(f"  {bild}\n      -> {ursache}")
    return "\n".join(zeilen)


def befund(b):
    zeilen = [f"Zustand {b.zustand}: {b.titel}", _linie()]
    zeilen.append("Begruendung: " + "; ".join(b.begruendung))
    zeilen.append("Naechster Schritt: " + b.schritt)
    for w in b.warnungen:
        zeilen.append("\n! " + w)
    return "\n".join(zeilen)


def discovery(res):
    zeilen = [f"Discovery fuer {res['domain']}", _linie("=")]
    for p in res["proben"]:
        st = p["status"] or "---"
        extra = p["fehler"] or p["content_type"] or ""
        zeilen.append(f"  {st:>4}  {p['art']:<11} {p['url']}")
        if extra:
            zeilen.append(f"        {extra}")
    zeilen += ["", f"Urteil: {res['urteil']}", res["deutung"]]
    return "\n".join(zeilen)


def konfig(res):
    zeilen = ["claude_desktop_config.json", _linie("=")]
    for g in res["gefunden"]:
        mark = "vorhanden" if g["existiert"] else "fehlt"
        zeilen.append(f"  [{mark:>9}] {g['art']}")
        zeilen.append(f"              {g['pfad']}")
        if g["server"]:
            zeilen.append("              mcpServers: " + ", ".join(g["server"]))
        if g["fehler"]:
            zeilen.append("              " + g["fehler"])
    for w in res["warnungen"]:
        zeilen.append("\n! " + w)
    return "\n".join(zeilen)
