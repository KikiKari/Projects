#!/usr/bin/env python3
"""Rendert die Architektur eines Projekts als isometrische 3D-Ansicht.

Liest die Schichtbeschreibung aus einer JSON-Datei (Vorgabe
``docs/architektur.json``) und erzeugt daraus zwei Dateien:

  * ein rotierendes animiertes GIF (Kamera faehrt einmal um die Szene)
  * ein PNG-Standbild in klassischer isometrischer Stellung

Dieselbe JSON-Datei speist auch ``public/3d.html``. Eine Beschreibung, drei
Darstellungen — damit Standbild, GIF und begehbare Ansicht nicht auseinanderlaufen.

Reine Orthogonalprojektion mit Maler-Algorithmus — kein Renderer, keine GPU,
nur Pillow und NumPy. Aufruf:

    python tools/render_3d.py [spec.json] [ausgabeordner]
"""
import json
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

BREITE, HOEHE = 1000, 700
SKALA = 9.6
ELEVATION = math.radians(30.0)   # klassische Iso-Neigung
FRAMES = 36
HELL = (247, 248, 250)

FONT_DIR = Path("/usr/share/fonts/truetype")


def _font(groesse, fett=False):
    name = "DejaVuSans-Bold.ttf" if fett else "DejaVuSans.ttf"
    pfad = FONT_DIR / "dejavu" / name
    try:
        return ImageFont.truetype(str(pfad), groesse)
    except OSError:
        return ImageFont.load_default()


def _abdunkeln(farbe, faktor):
    return tuple(max(0, min(255, int(k * faktor))) for k in farbe)


class Quader:
    """Ein beschrifteter Block in der Szene."""

    def __init__(self, mitte, groesse, farbe, label=""):
        self.mitte = np.array(mitte, dtype=float)
        self.groesse = np.array(groesse, dtype=float)
        self.farbe = farbe
        self.label = label

    def ecken(self):
        hx, hy, hz = self.groesse / 2.0
        return np.array([
            [-hx, -hy, -hz], [hx, -hy, -hz], [hx, -hy, hz], [-hx, -hy, hz],
            [-hx, hy, -hz], [hx, hy, -hz], [hx, hy, hz], [-hx, hy, hz],
        ]) + self.mitte

    FLAECHEN = [
        ((4, 5, 6, 7), (0, 1, 0), 1.00),    # oben
        ((0, 1, 2, 3), (0, -1, 0), 0.55),   # unten
        ((3, 2, 6, 7), (0, 0, 1), 0.80),    # vorne
        ((0, 1, 5, 4), (0, 0, -1), 0.62),   # hinten
        ((1, 2, 6, 5), (1, 0, 0), 0.70),    # rechts
        ((0, 3, 7, 4), (-1, 0, 0), 0.70),   # links
    ]


def kamera(azimut, elevation=ELEVATION):
    """Liefert die drei Achsen der Kamera als Orthonormalbasis."""
    d = np.array([math.cos(elevation) * math.sin(azimut),
                  math.sin(elevation),
                  math.cos(elevation) * math.cos(azimut)])
    rechts = np.cross(np.array([0.0, 1.0, 0.0]), d)
    rechts /= np.linalg.norm(rechts)
    oben = np.cross(d, rechts)
    return rechts, oben, d


def projizieren(punkte, basis):
    rechts, oben, d = basis
    x = punkte @ rechts * SKALA + BREITE / 2 + 70
    y = -(punkte @ oben) * SKALA + HOEHE / 2 + 20
    return np.stack([x, y], axis=-1), punkte @ d


def zeichne(szene, azimut, titel="", legende=None):
    bild = Image.new("RGB", (BREITE, HOEHE), HELL)
    zeichner = ImageDraw.Draw(bild, "RGBA")
    basis = kamera(azimut)
    _, _, d = basis

    # Boden: dezentes Raster, damit die Drehung sichtbar bleibt
    for i in range(-20, 21, 4):
        for a, b in (((i, -21, -20), (i, -21, 20)), ((-20, -21, i), (20, -21, i))):
            pts, _ = projizieren(np.array([a, b], dtype=float), basis)
            zeichner.line([tuple(pts[0]), tuple(pts[1])], fill=(226, 230, 236), width=1)

    # Maler-Algorithmus: hinten zuerst. Beschriftungen werden gesammelt und
    # erst ganz am Schluss gezeichnet — sonst verdeckt die Platte der naechsten
    # Schicht die Labels der Bausteine darunter.
    beschriftungen = []
    for quader in sorted(szene, key=lambda q: float(np.dot(q.mitte, d))):
        ecken = quader.ecken()
        pts2d, _ = projizieren(ecken, basis)
        flaechen = []
        for idx, normale, schatten in Quader.FLAECHEN:
            n = np.array(normale, dtype=float)
            if float(np.dot(n, d)) <= 0.02:
                continue
            tiefe = float(np.mean([np.dot(ecken[i], d) for i in idx]))
            flaechen.append((tiefe, idx, schatten))
        for _, idx, schatten in sorted(flaechen):
            poly = [tuple(pts2d[i]) for i in idx]
            zeichner.polygon(poly, fill=_abdunkeln(quader.farbe, schatten),
                             outline=_abdunkeln(quader.farbe, schatten * 0.62))
        if quader.label:
            oben_mitte = np.mean([ecken[i] for i in (4, 5, 6, 7)], axis=0)
            pts, _ = projizieren(oben_mitte[None, :], basis)
            px, py = float(pts[0][0]), float(pts[0][1])
            beschriftungen.append((px, py, quader.label))

    _beschrifte(zeichner, beschriftungen)


    if titel:
        zeichner.text((28, 22), titel, font=_font(23, fett=True), fill=(22, 25, 29))
    if legende:
        y = 66
        zeichner.text((28, y - 22), "Schichten, von unten nach oben",
                      font=_font(12, fett=True), fill=(95, 103, 115))
        for name, farbe in legende:
            zeichner.rectangle([28, y + 2, 42, y + 16], fill=farbe)
            zeichner.text((50, y), name, font=_font(13), fill=(45, 50, 58))
            y += 24
    return bild


def _beschrifte(zeichner, eintraege, schrift=14):
    """Setzt Beschriftungen kollisionsfrei und zieht eine Fuehrungslinie zum Block.

    Ohne diesen Schritt ueberdecken sich die Schilder benachbarter Bausteine in
    der Isometrie regelmaessig — zwei Bloecke, die im Raum weit auseinanderliegen,
    landen projiziert nebeneinander.
    """
    f = _font(schrift, fett=True)
    belegt = []          # bereits gesetzte Rechtecke
    # von oben nach unten setzen: die oberste Schicht bekommt ihren Wunschplatz
    for anker_x, anker_y, text in sorted(eintraege, key=lambda e: e[1]):
        l, t, r, b = zeichner.textbbox((0, 0), text, font=f)
        w, h = r - l, b - t
        bx, by = w / 2 + 7, h / 2 + 5

        platz = None
        # abwechselnd nach oben und unten ausweichen, in kleinen Schritten
        for schritt in range(0, 26):
            for richtung in ((-1, 1) if schritt else (0,)):
                y = anker_y + richtung * schritt * 7
                kasten = (anker_x - bx, y - by, anker_x + bx, y + by)
                if all(kasten[2] < o[0] or kasten[0] > o[2] or
                       kasten[3] < o[1] or kasten[1] > o[3] for o in belegt):
                    platz = (y, kasten)
                    break
            if platz:
                break
        if not platz:                       # gibt es praktisch nie
            platz = (anker_y, (anker_x - bx, anker_y - by, anker_x + bx, anker_y + by))
        y, kasten = platz
        belegt.append(kasten)

        if abs(y - anker_y) > 3:            # Fuehrungslinie nur, wenn versetzt
            zeichner.line([(anker_x, anker_y), (anker_x, y)],
                          fill=(150, 157, 168), width=1)
            zeichner.ellipse([anker_x - 2, anker_y - 2, anker_x + 2, anker_y + 2],
                             fill=(150, 157, 168))
        zeichner.rectangle(kasten, fill=(255, 255, 255, 236), outline=(206, 212, 221))
        zeichner.text((anker_x - w / 2, y - h / 2 - t), text, font=f, fill=(22, 25, 29))



def schicht(y, farbe, blocks, bw=7.4, bd=4.4, hoehe=1.6, luft=2.0):
    """Eine Schicht: Grundplatte, darauf die Bausteine in einem 2-reihigen Raster.

    Das Raster statt einer einzelnen Reihe ist kein Schoenheitsgrund: eine lange
    Reihe laeuft in der Isometrie diagonal aus dem Bild und wird von der Platte
    der naechsthoeheren Schicht verdeckt.
    """
    spalten = max(1, (len(blocks) + 1) // 2)
    reihen = 1 if len(blocks) <= 1 else 2
    gx = spalten * bw + (spalten - 1) * luft
    gz = reihen * bd + (reihen - 1) * luft
    platte = Quader((0.0, y - 1.6, 0.0), (gx + 2.6, 0.5, gz + 2.6),
                    _abdunkeln(farbe, 0.5))
    out = [platte]
    for i, label in enumerate(blocks):
        sp, re = i % spalten, i // spalten
        x = -gx / 2 + bw / 2 + sp * (bw + luft)
        z = -gz / 2 + bd / 2 + re * (bd + luft)
        out.append(Quader((x, y, z), (bw, hoehe, bd), farbe, label))
    return out


# ------------------------------------------------------------------ Spec ----

ABSTAND = 12.6   # senkrechter Abstand der Schichten
START_Y = -17.0  # Hoehe der untersten Schicht


def _hex(wert):
    """#rrggbb -> (r, g, b). Die Spec nutzt Hex, damit sie auch das HTML speisen kann."""
    if not isinstance(wert, str):
        return tuple(wert)
    h = wert.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def lade(pfad):
    """Liest die Schichtbeschreibung: titel, schichten[{name, farbe, blocks}]."""
    spec = json.loads(Path(pfad).read_text(encoding="utf-8"))
    szene, legende = [], []
    for i, s in enumerate(spec["schichten"]):
        farbe = _hex(s["farbe"])
        # Bloecke duerfen Text oder Objekt sein — die interaktive Ansicht braucht
        # mehr Angaben als das Standbild, beide lesen dieselbe Datei.
        namen = [b if isinstance(b, str) else b["name"] for b in s["blocks"]]
        szene += schicht(START_Y + i * ABSTAND, farbe, namen)
        legende.append((s["name"], farbe))
    return szene, spec["titel"], list(reversed(legende))


def main():
    spec = Path(sys.argv[1] if len(sys.argv) > 1 else "docs/architektur.json")
    ziel = Path(sys.argv[2] if len(sys.argv) > 2 else "docs/assets")
    if not spec.exists():
        print("Spec nicht gefunden:", spec)
        return 1
    ziel.mkdir(parents=True, exist_ok=True)
    szene, titel, legende = lade(spec)

    standbild = zeichne(szene, math.radians(45.0), titel, legende)
    standbild.save(ziel / "architektur-iso.png", optimize=True)

    frames = [zeichne(szene, 2 * math.pi * i / FRAMES, titel, legende)
              .convert("P", palette=Image.ADAPTIVE, colors=96)
              for i in range(FRAMES)]
    frames[0].save(ziel / "architektur-rotation.gif", save_all=True,
                   append_images=frames[1:], duration=90, loop=0, optimize=True)
    print("geschrieben:", ziel / "architektur-iso.png", "|",
          ziel / "architektur-rotation.gif")
    return 0


if __name__ == "__main__":
    sys.exit(main())
