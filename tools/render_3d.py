#!/usr/bin/env python3
"""Rendert die Architektur eines Projekts als isometrische 3D-Ansicht.

Erzeugt zwei Dateien:
  * ein rotierendes animiertes GIF (Kamera faehrt einmal um die Szene)
  * ein PNG-Standbild in klassischer isometrischer Stellung

Reine Orthogonalprojektion mit Maler-Algorithmus — kein Renderer, keine GPU,
nur Pillow und NumPy. Aufruf:

    python tools/render_3d.py <projekt> <ausgabeordner>
"""
import math
import sys
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFont

BREITE, HOEHE = 900, 620
SKALA = 10.5
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

    f = _font(14, fett=True)
    for px, py, text in beschriftungen:
        l, t, r, b = zeichner.textbbox((0, 0), text, font=f)
        w, h = r - l, b - t
        zeichner.rectangle([px - w / 2 - 6, py - h / 2 - 4,
                            px + w / 2 + 6, py + h / 2 + 4],
                           fill=(255, 255, 255, 232), outline=(214, 219, 226))
        zeichner.text((px - w / 2, py - h / 2 - t), text, font=f, fill=(22, 25, 29))

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


def schicht(y, farbe, blocks, bw=7.0, bd=3.8, hoehe=1.6, luft=1.2):
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


# ---------------------------------------------------------------- Szenen ----

VIOLETT = (109, 91, 208)
BLAU = (36, 129, 204)
GRUEN = (21, 128, 61)
GRAU = (95, 103, 115)
ROT = (254, 44, 85)
ORANGE = (180, 83, 9)

SZENEN = {
    "mcp-server-monitor": {
        "titel": "MCP-Server-Monitor — Schichten",
        "schichten": [
            (-17.0, GRAU, "Quellen", ["mcp.DOMAIN", "docs/mcp", ".well-known", "config.json"]),
            (-5.6, BLAU, "Sonde", ["discovery.py", "config.py"]),
            (5.6, VIOLETT, "Klassifikation", ["state.py"]),
            (17.0, GRUEN, "Ausgabe", ["report.py", "server.py", "index.html"]),
        ],
    },
    "telegram-monitor": {
        "titel": "Telegram Monitor — Schichten",
        "schichten": [
            (-17.0, GRAU, "Plattformen", ["t.me", "Bot-API", "MTProto", "Discord", "TikTok"]),
            (-5.6, BLAU, "Adapter", ["telegram_web", "telegram_bot", "mtproto", "tiktok_live"]),
            (5.6, VIOLETT, "Kern", ["registry", "store", "live", "models"]),
            (17.0, ROT, "Ausgabe", ["notify", "cli.py", "server.py", "web/ PWA"]),
        ],
    },
}


def baue(name):
    spec = SZENEN[name]
    szene, legende = [], []
    for y, farbe, schichtname, blocks in spec["schichten"]:
        szene += schicht(y, farbe, blocks)
        legende.append((schichtname, farbe))
    return szene, spec["titel"], list(reversed(legende))


def main():
    if len(sys.argv) < 3:
        print(__doc__)
        return 1
    name, ziel = sys.argv[1], Path(sys.argv[2])
    ziel.mkdir(parents=True, exist_ok=True)
    szene, titel, legende = baue(name)

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
