#!/usr/bin/env python3
"""Verifiziert Datenmodell und erzeugte TikTok-LIVE-Companion-Visualisierungen."""

from pathlib import Path
from xml.etree import ElementTree
import hashlib

from PIL import Image

from flow_model import EDGES, EDGE_COLORS, STAGES
from gen_tiktok_live_companion_flow import build_svg
from flow_model import as_json

ROOT = Path(__file__).resolve().parents[1]
SVG = ROOT / "docs" / "diagrams" / "tiktok-live-companion-architecture.svg"
GIF = ROOT / "docs" / "diagrams" / "tiktok-live-companion-architecture.gif"
MOBILE = ROOT / "docs" / "mobile" / "mobile-0.7.0-concept.png"
PUBLIC = ROOT / "site" / "public" / "visualizations"
EXPECTED_MOBILE_SHA256 = "d37560c4c23b1fd3fac7d0c02eea9add78a08f80b7d47e34551fda35e3db869f"

ids = [stage[0] for stage in STAGES]
assert len(ids) == len(set(ids)) == 13, "Knoten-IDs müssen eindeutig sein"
for source, target, _label, role in EDGES:
    assert source in ids and target in ids, f"Unbekannte Kante: {source} -> {target}"
    assert role in EDGE_COLORS, f"Unbekannte Kantenrolle: {role}"
assert len(EDGES) == 12

generated = build_svg()
assert generated == build_svg(), "SVG-Ausgabe ist nicht deterministisch"
assert SVG.read_text(encoding="utf-8") == generated, "SVG ist nicht mit dem Generator synchron"
ElementTree.fromstring(generated)
for forbidden in ("MCP Client", "Perplexity API", "MCP-OAuth-Proxy"):
    assert forbidden not in generated, f"Fremdprojektinhalt im SVG: {forbidden}"
for required in ("TikTok LIVE", "AudD", "ShazamKit", "Token-Dienst"):
    assert required in generated, f"Projektknoten fehlt im SVG: {required}"

with Image.open(GIF) as image:
    assert image.format == "GIF"
    assert image.n_frames == 36
    assert image.info.get("loop") == 0
    assert image.size == (1100, 760)

assert (PUBLIC / SVG.name).read_bytes() == SVG.read_bytes(), "Öffentliches SVG ist nicht synchron"
assert (PUBLIC / GIF.name).read_bytes() == GIF.read_bytes(), "Öffentliches GIF ist nicht synchron"
assert (PUBLIC / "tiktok-live-companion-flow-model.json").read_text(encoding="utf-8") == as_json()

mobile_hash = hashlib.sha256(MOBILE.read_bytes()).hexdigest()
assert mobile_hash == EXPECTED_MOBILE_SHA256, "Mobile V7-Konzept entspricht nicht dem finalen Anhang"

print("PASS: 13 Projektknoten, 12 Kanten, deterministisches SVG, 36-Frame-GIF und finaler V7-Mobile-Anhang.")
