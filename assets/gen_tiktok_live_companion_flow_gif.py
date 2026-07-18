#!/usr/bin/env python3
"""Erzeugt ein rotierendes Projekt-GIF aus dem gemeinsamen Architekturmodell.

Technische Vorlage: OpenClaw assets/gen_mcp_flow_gif.py. Anders als die
Vorlage rendert dieses Skript ohne CairoSVG direkt mit Pillow und verwendet
ausschließlich das TikTok-LIVE-Companion-Modell aus flow_model.py.
"""

from pathlib import Path
import math
import sys

from PIL import Image, ImageDraw, ImageFont

from flow_model import EDGE_COLORS, EDGES, PALETTE, STAGES

WIDTH, HEIGHT = 1100, 760
FRAMES = 36
FRAME_MS = 85
SCALE = 40
C = math.cos(math.radians(30))
S = 0.5
BACKGROUND = "#0f1729"
CENTER_X, CENTER_Y = WIDTH // 2, 350
PX = sum(stage[1] for stage in STAGES) / len(STAGES)
PY = sum(stage[2] for stage in STAGES) / len(STAGES)
FACES = [(4, 5, 6, 7), (1, 2, 6, 5), (2, 3, 7, 6)]


def font(size, bold=False):
    names = ["segoeuib.ttf" if bold else "segoeui.ttf", "arialbd.ttf" if bold else "arial.ttf"]
    for name in names:
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            pass
    return ImageFont.load_default()


TITLE_FONT = font(23, True)
SUBTITLE_FONT = font(13)
LABEL_FONT = font(13, True)
SMALL_FONT = font(11)


def rotate(x, y, angle):
    c, s = math.cos(angle), math.sin(angle)
    dx, dy = x - PX, y - PY
    return PX + dx * c - dy * s, PY + dx * s + dy * c


def project(x, y, z=0.0):
    sx = (x - y) * C * SCALE
    sy = ((x + y) * S - z) * SCALE
    return CENTER_X + sx, CENTER_Y + sy


def corners(cx, cy, half, height, angle):
    world = [
        (cx - half, cy - half, 0), (cx + half, cy - half, 0),
        (cx + half, cy + half, 0), (cx - half, cy + half, 0),
        (cx - half, cy - half, height), (cx + half, cy - half, height),
        (cx + half, cy + half, height), (cx - half, cy + half, height),
    ]
    rotated = [(*rotate(x, y, angle), z) for x, y, z in world]
    return rotated, [project(x, y, z) for x, y, z in rotated]


def arrow(draw, start, end, color, dashed=False):
    x1, y1 = start
    x2, y2 = end
    x1 += 0.18 * (x2 - x1); y1 += 0.18 * (y2 - y1)
    x2 = x1 + 0.72 * (x2 - x1); y2 = y1 + 0.72 * (y2 - y1)
    if dashed:
        pieces = 8
        for i in range(0, pieces, 2):
            a, b = i / pieces, min(1, (i + 1) / pieces)
            draw.line((x1 + a * (x2 - x1), y1 + a * (y2 - y1), x1 + b * (x2 - x1), y1 + b * (y2 - y1)), fill=color, width=3)
    else:
        draw.line((x1, y1, x2, y2), fill=color, width=3)
    angle = math.atan2(y2 - y1, x2 - x1)
    size = 9
    points = [
        (x2, y2),
        (x2 - size * math.cos(angle - 0.55), y2 - size * math.sin(angle - 0.55)),
        (x2 - size * math.cos(angle + 0.55), y2 - size * math.sin(angle + 0.55)),
    ]
    draw.polygon(points, fill=color)


def render_frame(angle):
    image = Image.new("RGB", (WIDTH, HEIGHT), BACKGROUND)
    draw = ImageDraw.Draw(image)
    draw.text((30, 24), "TikTok LIVE Companion 0.7.0 — Plattformarchitektur", font=TITLE_FONT, fill="#f8fafc")
    draw.text((30, 57), "Tiefe trennt Browser, iOS und Android/HyperOS · Audio ausschließlich nach Nutzeraktion", font=SUBTITLE_FONT, fill="#a7b4c7")

    faces, labels, tops = [], [], {}
    for sid, cx, cy, half, height, palette, label, sublabel, _lane in STAGES:
        world, screen = corners(cx, cy, half, height, angle)
        depth = sum(p[0] + p[1] + p[2] for p in world) / len(world)
        colors = PALETTE[palette]
        for face_index, indices in enumerate(FACES):
            face_depth = sum(world[i][0] + world[i][1] + world[i][2] for i in indices) / 4
            faces.append((face_depth, [screen[i] for i in indices], colors[face_index]))
        rx, ry = rotate(cx, cy, angle)
        top = project(rx, ry, height + 0.08)
        tops[sid] = top
        labels.append((depth, top, label, sublabel))

    for _depth, points, fill in sorted(faces, key=lambda item: item[0]):
        draw.polygon(points, fill=fill, outline="#111b31")

    for source, target, _label, role in EDGES:
        arrow(draw, tops[source], tops[target], EDGE_COLORS[role], dashed=role == "token")

    for _depth, (x, y), label, sublabel in sorted(labels, key=lambda item: item[0]):
        box = draw.textbbox((0, 0), label, font=LABEL_FONT)
        draw.text((x - (box[2] - box[0]) / 2, y - 18), label, font=LABEL_FONT, fill="#ffffff", stroke_width=2, stroke_fill="#111827")
        box2 = draw.textbbox((0, 0), sublabel, font=SMALL_FONT)
        draw.text((x - (box2[2] - box2[0]) / 2, y - 2), sublabel, font=SMALL_FONT, fill="#e2e8f0", stroke_width=2, stroke_fill="#111827")

    legend = [("#25c5d2", "passive Beobachtung"), ("#ff557a", "Audio nur nach Klick"), ("#e9a12d", "ES256-Token")]
    x = 32
    for color, text in legend:
        draw.line((x, HEIGHT - 38, x + 30, HEIGHT - 38), fill=color, width=4)
        draw.text((x + 39, HEIGHT - 46), text, font=SMALL_FONT, fill="#cbd5e1")
        x += 190
    return image


if __name__ == "__main__":
    project_root = Path(__file__).resolve().parents[1]
    output = project_root / "docs" / "diagrams" / "tiktok-live-companion-architecture.gif"
    output.parent.mkdir(parents=True, exist_ok=True)
    if len(sys.argv) > 1 and sys.argv[1] == "test":
        test_output = project_root / "docs" / "diagrams" / "tiktok-live-companion-architecture-test.png"
        render_frame(math.radians(32)).save(test_output)
        print(f"Testframe geschrieben: {test_output}")
    else:
        frames = [render_frame(2 * math.pi * index / FRAMES) for index in range(FRAMES)]
        palette = frames[0].quantize(colors=192, method=Image.Quantize.MEDIANCUT)
        quantized = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
        quantized[0].save(output, save_all=True, append_images=quantized[1:], duration=FRAME_MS, loop=0, optimize=True, disposal=2)
        print(f"GIF geschrieben: {output} ({FRAMES} Frames, {output.stat().st_size / 1024:.0f} KB)")
