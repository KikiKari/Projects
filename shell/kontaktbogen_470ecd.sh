#!/bin/bash
# abstraction-provenance: {"artifact_sha256": "33bba78ddcdd3a256fea92a34f3a7fc939b36ab8606e8534273016be5b17f489", "source_sha256": "470ecd5aad55c517d9e61935d3422a32740607ef531514fee63990c26ee64839", "target_language": "shell"}
# kontaktbogen.css — portiert nach shell
# Quelle: css, Projects@abstractions:css/kontaktbogen.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

set -euo pipefail

# Funktion zum Erstellen der CSS-Datei
create_css() {
    local output_file="$1"
    
    cat > "$output_file" << 'EOF'
:root {
  --bg: #FAF8F4;
  --ink: #1B1A17;
  --muted: #6E6A61;
  --line: #E5E1D8;
  --accent: #A8542F;
  --accent-2: #2E7D7B;
  --surface: #fff;
}

* {
  box-sizing: border-box;
}

body {
  margin: 0;
  font-family: 'Hanken Grotesk', system-ui, sans-serif;
  background: var(--bg);
  color: var(--ink);
  line-height: 1.5;
}

header {
  padding: 2.5rem 2rem 1rem;
  border-bottom: 1px solid var(--line);
  background: var(--surface);
  position: sticky;
  top: 0;
  z-index: 10;
}

header h1 {
  margin: 0 0 .5rem;
  font-family: 'Newsreader', Georgia, serif;
  font-weight: 400;
  font-size: 2.25rem;
}

header p {
  margin: .25rem 0;
  color: var(--muted);
  max-width: 80ch;
}

.legend {
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;
  margin-top: .75rem;
  font-size: .8125rem;
}

.pill {
  padding: .15rem .6rem;
  border-radius: 999px;
  border: 1px solid var(--line);
  background: #fff;
}

.pill.pflicht {
  border-color: var(--accent);
  color: var(--accent);
  font-weight: 600;
}

.pill.auswahl {
  border-color: var(--accent-2);
  color: var(--accent-2);
  font-weight: 600;
}

main {
  padding: 2rem;
  max-width: 1400px;
  margin: 0 auto;
}

section {
  margin: 2.5rem 0;
}

section h2 {
  font-family: 'Newsreader', serif;
  font-weight: 400;
  font-size: 1.5rem;
  margin: 0 0 .25rem;
  display: flex;
  align-items: center;
  gap: .75rem;
}

section .sub {
  color: var(--muted);
  font-size: .875rem;
  margin: 0 0 1.25rem;
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(240px, 1fr));
  gap: 1rem;
}

.card {
  background: var(--surface);
  border: 1px solid var(--line);
  border-radius: 10px;
  overflow: hidden;
  display: flex;
  flex-direction: column;
}

.card .imgwrap {
  aspect-ratio: 1;
  background: #f1eee7;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.card img {
  width: 100%;
  height: 100%;
  object-fit: contain;
  background: #fff;
}

.card .meta {
  padding: .6rem .75rem .75rem;
  font-size: .78125rem;
}

.card .name {
  font-family: 'JetBrains Mono', monospace;
  font-size: .6875rem;
  color: var(--muted);
  word-break: break-all;
  line-height: 1.3;
  margin-bottom: .35rem;
}

.card .dims {
  color: var(--muted);
  font-size: .6875rem;
  margin-bottom: .35rem;
}

.card .prompt {
  color: var(--ink);
  font-size: .75rem;
  line-height: 1.35;
  font-style: italic;
  border-top: 1px solid var(--line);
  padding-top: .4rem;
  margin-top: .35rem;
  max-height: 5.5em;
  overflow: hidden;
}

.tag {
  display: inline-block;
  padding: .1rem .45rem;
  border-radius: 999px;
  font-size: .6875rem;
  background: #F1EEE7;
  color: var(--muted);
  margin-right: .25rem;
}

.tag.p {
  background: #F1E5DD;
  color: var(--accent);
}

.tag.a {
  background: #DEEDEC;
  color: var(--accent-2);
}
EOF
}

# Hauptprogramm
main() {
    if [ $# -ne 1 ]; then
        echo "Verwendung: $0 <ausgabedatei>" >&2
        exit 1
    fi
    
    local output_file="$1"
    create_css "$output_file"
}

main "$@"
