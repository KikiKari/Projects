#!/usr/bin/env python3
"""Erzeugt das projektspezifische 2.5D-SVG für TikTok LIVE Companion 0.7.0.

Technische Vorlage: OpenClaw assets/gen_mcp_flow.py. Datenmodell, Texte,
Farbcodierung, Kanten und Ausgabepfad sind projektspezifisch.
"""

from html import escape
from pathlib import Path
import math

from flow_model import EDGE_COLORS, EDGES, LANE_LABELS, PALETTE, STAGES

C = math.cos(math.radians(30))
S = 0.5
SCALE = 48


def iso(x, y, z=0.0):
    return (x - y) * C * SCALE, ((x + y) * S - z) * SCALE


def box_polys(cx, cy, hw, h, colors):
    corners = [
        iso(cx - hw, cy - hw, 0), iso(cx + hw, cy - hw, 0),
        iso(cx + hw, cy + hw, 0), iso(cx - hw, cy + hw, 0),
        iso(cx - hw, cy - hw, h), iso(cx + hw, cy - hw, h),
        iso(cx + hw, cy + hw, h), iso(cx - hw, cy + hw, h),
    ]
    light, mid, dark = colors
    faces = [
        ((4, 5, 6, 7), light),
        ((1, 2, 6, 5), mid),
        ((2, 3, 7, 6), dark),
    ]
    result = []
    for indices, fill in faces:
        points = " ".join(f"{corners[i][0]:.1f},{corners[i][1]:.1f}" for i in indices)
        result.append(f'<polygon points="{points}" fill="{fill}" stroke="#121b31" stroke-width="1"/>')
    return result, iso(cx, cy, h)


def shorten(a, b, start=0.18, end=0.78):
    return (
        a[0] + start * (b[0] - a[0]), a[1] + start * (b[1] - a[1]),
        a[0] + end * (b[0] - a[0]), a[1] + end * (b[1] - a[1]),
    )


def build_svg():
    positions = {stage[0]: (stage[1], stage[2], stage[4]) for stage in STAGES}
    boxes, labels = [], []
    for sid, cx, cy, hw, h, palette, label, sublabel, _lane in sorted(STAGES, key=lambda s: s[1] + s[2]):
        polys, (lx, ly) = box_polys(cx, cy, hw, h, PALETTE[palette])
        boxes.extend(polys)
        labels.append(
            f'<text x="{lx:.1f}" y="{ly-4:.1f}" text-anchor="middle" font-family="Segoe UI,Arial,sans-serif" '
            f'font-size="12" font-weight="700" fill="#fff">{escape(label)}</text>'
        )
        labels.append(
            f'<text x="{lx:.1f}" y="{ly+10:.1f}" text-anchor="middle" font-family="Segoe UI,Arial,sans-serif" '
            f'font-size="8.5" fill="#eef2f7">{escape(sublabel)}</text>'
        )

    arrows = []
    for source, target, label, role in EDGES:
        sx, sy, sh = positions[source]
        tx, ty, th = positions[target]
        a, b = iso(sx, sy, sh + 0.08), iso(tx, ty, th + 0.08)
        x1, y1, x2, y2 = shorten(a, b)
        color = EDGE_COLORS[role]
        dash = ' stroke-dasharray="7 5"' if role == "token" else ""
        arrows.append(
            f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="{color}" '
            f'stroke-width="2.4"{dash} marker-end="url(#{role})"/>'
        )
        mx, my = (x1 + x2) / 2, (y1 + y2) / 2
        arrows.append(
            f'<text x="{mx:.1f}" y="{my-5:.1f}" text-anchor="middle" font-family="Segoe UI,Arial,sans-serif" '
            f'font-size="7.5" fill="{color}" style="paint-order:stroke;stroke:#0f1729;stroke-width:3px">{escape(label)}</text>'
        )

    pts = []
    for _sid, cx, cy, hw, h, *_ in STAGES:
        for dx in (-hw, hw):
            for dy in (-hw, hw):
                pts.extend([iso(cx + dx, cy + dy, 0), iso(cx + dx, cy + dy, h)])
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    pad_x, pad_top, pad_bottom = 54, 92, 54
    minx, maxx = min(xs) - pad_x, max(xs) + pad_x
    miny, maxy = min(ys) - pad_top, max(ys) + pad_bottom
    width, height = maxx - minx, maxy - miny

    markers = "".join(
        f'<marker id="{role}" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto">'
        f'<path d="M0,0 L10,5 L0,10 z" fill="{color}"/></marker>'
        for role, color in EDGE_COLORS.items()
    )
    legend_y = miny + 57
    legend = [
        f'<text x="{minx+24:.1f}" y="{miny+27:.1f}" font-family="Segoe UI,Arial,sans-serif" font-size="17" font-weight="800" fill="#f8fafc">TikTok LIVE Companion 0.7.0 — Plattformarchitektur</text>',
        f'<text x="{minx+24:.1f}" y="{miny+46:.1f}" font-family="Segoe UI,Arial,sans-serif" font-size="10" fill="#98a7bd">Tiefe trennt Browser, iOS und Android/HyperOS · schematisch, nicht maßstabsgetreu</text>',
    ]
    cursor = minx + 24
    for role, text in (("observation", "passive Beobachtung"), ("audio", "Audio nur nach Klick"), ("token", "kurzlebiges ES256-Token")):
        color = EDGE_COLORS[role]
        dash = ' stroke-dasharray="6 4"' if role == "token" else ""
        legend.append(f'<line x1="{cursor:.1f}" y1="{legend_y:.1f}" x2="{cursor+28:.1f}" y2="{legend_y:.1f}" stroke="{color}" stroke-width="3"{dash}/>' )
        legend.append(f'<text x="{cursor+35:.1f}" y="{legend_y+3:.1f}" font-family="Segoe UI,Arial,sans-serif" font-size="9" fill="#cbd5e1">{text}</text>')
        cursor += 155

    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{minx:.1f} {miny:.1f} {width:.1f} {height:.1f}" '
        f'width="{width:.0f}" height="{height:.0f}" role="img" aria-labelledby="title desc">\n'
        f'<title id="title">TikTok LIVE Companion Plattformarchitektur</title>\n'
        f'<desc id="desc">Browser verwendet AudD. iOS und Android HyperOS verwenden ShazamKit. Audio startet nur nach Nutzeraktion; Android erhält ein kurzlebiges Token.</desc>\n'
        f'<defs>{markers}</defs>\n'
        f'<rect x="{minx:.1f}" y="{miny:.1f}" width="{width:.1f}" height="{height:.1f}" rx="16" fill="#0f1729"/>\n'
        + "\n".join(legend + boxes + arrows + labels)
        + "\n</svg>\n"
    )


if __name__ == "__main__":
    project = Path(__file__).resolve().parents[1]
    output = project / "docs" / "diagrams" / "tiktok-live-companion-architecture.svg"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(build_svg(), encoding="utf-8")
    print(f"SVG geschrieben: {output} ({len(STAGES)} Knoten, {len(EDGES)} Kanten)")
