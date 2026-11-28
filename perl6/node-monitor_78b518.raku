#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "7680e85d43afa0cb8e4712ccc2047070a6e1d34d4fdc5af46f277945b2020001", "source_sha256": "78b518f6f68bf0f05a573239d113470b3f5a9440be7cff5f80bc8576462525c3", "target_language": "perl6"}
# node-monitor.css — portiert nach perl6
# Quelle: css, Projects@abstractions:css/node-monitor.css
# Erzeugt: 2026-11-28 durch ABSTRACTIONS_MANAGER.py

sub MAIN($output-file) {
    my $css-content = q:to/END_CSS/;
    :root {
      --bg: #0d1117;
      --surface: #161b22;
      --border: #30363d;
      --text: #e6edf3;
      --green: #3fb950;
      --red: #f85149;
      --accent: #58a6ff;
    }

    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }

    body {
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, sans-serif;
      padding: 1.5rem;
    }

    h1 {
      color: var(--accent);
      margin-bottom: 1rem;
      font-size: 1.2rem;
    }

    canvas {
      display: block;
      border: 1px solid var(--border);
      border-radius: 8px;
      background: var(--surface);
    }

    #log {
      margin-top: 1rem;
      height: 140px;
      overflow-y: auto;
      background: var(--surface);
      border: 1px solid var(--border);
      border-radius: 8px;
      padding: .75rem;
      font-size: .78rem;
      font-family: monospace;
      color: #8b949e;
    }

    #log .err {
      color: var(--red);
    }

    #log .ok {
      color: var(--green);
    }
    END_CSS

    spurt($output-file, $css-content);
}
