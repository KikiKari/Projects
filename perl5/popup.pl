#!/usr/bin/perl
# popup.html — portiert nach perl5
# Quelle: html, Projects@Telegram-Monitor:plugin/extension/popup.html
# Erzeugt: 2026-08-09 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Parameter: Ausgabedatei
my $output_file = $ARGV[0] // die "Verwendung: $0 <ausgabedatei>\n";

# HTML-Dokument erzeugen
my $html = <<'HTML_HEAD';
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<title>TikTok Live Companion</title>
<style>
  :root{
    --bg:#0f1115; --card:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;
    --accent:#fe2c55; --ok:#22c55e;
    color-scheme: dark;
  }
  @media (prefers-color-scheme: light){
    :root{ --bg:#fff; --card:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#6b7280; }
  }
  *{box-sizing:border-box}
  body{margin:0;width:420px;max-height:600px;overflow:auto;background:var(--bg);color:var(--text);
       font:14px/1.45 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
  .wrap{padding:12px}
  header{display:flex;gap:8px;align-items:center;margin-bottom:10px}
  h1{font-size:14px;margin:0;font-weight:650;flex:1}
  .badge{font-size:11px;font-weight:700;padding:3px 9px;border-radius:99px;
         background:#2a2f3a;color:var(--muted);display:inline-flex;align-items:center;gap:5px}
  .badge.live{background:var(--accent);color:#fff}
  .badge .dot{width:6px;height:6px;border-radius:50%;background:currentColor}
  .badge.live .dot{animation:pulse 1.6s infinite}
  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.25}}
  .row{display:flex;gap:6px;flex-wrap:wrap;align-items:center;margin-bottom:8px}
  input,select,button{font:inherit;border-radius:7px;border:1px solid var(--line);
                      background:var(--card);color:var(--text);padding:6px 9px}
  button{cursor:pointer;font-weight:600}
  button.primary{background:var(--accent);border-color:var(--accent);color:#fff}
  .player{position:relative;width:100%;aspect-ratio:9/16;max-height:360px;background:#000;
          border-radius:10px;overflow:hidden;border:1px solid var(--line);margin:8px 0}
  .player iframe{position:absolute;inset:0;width:100%;height:100%;border:0}
  .placeholder{position:absolute;inset:0;display:flex;flex-direction:column;gap:6px;
               align-items:center;justify-content:center;color:var(--muted);
               text-align:center;padding:16px;font-size:13px}
  .card{background:var(--card);border:1px solid var(--line);border-radius:10px;
        padding:10px 12px;margin-bottom:8px}
  h2{font-size:11px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);
     margin:0 0 6px;font-weight:650}
  .meta{color:var(--muted);font-size:12.5px}
  .strong{color:var(--text);font-weight:600}
  .stream{display:flex;gap:8px;padding:5px 0;border-bottom:1px solid var(--line);font-size:12.5px}
  .stream:last-child{border-bottom:0}
  .stream .when{color:var(--muted);white-space:nowrap;font-variant-numeric:tabular-nums}
  .stream .t{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
  .stream.now{color:var(--accent);font-weight:650}
  .err{background:#3a1d22;border:1px solid #5c2a33;color:#ffb4c0;padding:8px 10px;
       border-radius:8px;font-size:12.5px;margin-bottom:8px}
  @media (prefers-color-scheme: light){ .err{background:#fdeceb;border-color:#f5c6c2;color:#b91c1c} }
  .note{font-size:11.5px;color:var(--muted);line-height:1.4;margin-top:8px}
  a{color:var(--accent)}
</style>
</head>
<body>
<div class="wrap">
  <header>
    <h1>TikTok Live Companion</h1>
    <span class="badge" id="badge"><span class="dot"></span><span id="badgeText">—</span></span>
  </header>

  <div class="row">
    <input id="user" placeholder="@name" style="flex:1;min-width:120px">
    <button class="primary" id="go">Anzeigen</button>
    <button id="force" title="Player ohne Statusabfrage laden">Player</button>
  </div>
  <div class="row">
    <select id="every" style="flex:1">
HTML_HEAD

# Select-Optionen
$html .= "      <option value=\"1\">Prüfung jede Minute</option>\n";
$html .= "      <option value=\"2\" selected>alle 2 Minuten</option>\n";
$html .= "      <option value=\"5\">alle 5 Minuten</option>\n";
$html .= "      <option value=\"0\">nur manuell</option>\n";

$html .= <<'HTML_FOOT';
    </select>
    <label class="meta"><input type="checkbox" id="notify" checked> benachrichtigen</label>
  </div>

  <div id="error"></div>

  <div class="player" id="player">
    <div class="placeholder" id="placeholder">
      <div style="font-size:28px">📺</div>
      <div id="phText">Konto eingeben und „Anzeigen“ drücken.</div>
    </div>
  </div>

  <div class="card">
    <h2>Status</h2>
    <div id="status" class="meta">—</div>
  </div>

  <div class="card">
    <h2>Letzte Sendungen</h2>
    <div id="streams" class="meta">—</div>
  </div>

  <p class="note">
    Eingebettet wird der offizielle TikTok-Live-Player — <b>keine Anmeldung,
    keine Geschenk- oder Kauf-Oberfläche</b>. Der Status kommt aus öffentlichen
    Quellen; nichts davon umgeht eine Zugangskontrolle.
  </p>
</div>
<script src="tiktok-companion.js"></script>
<script src="popup.js"></script>
</body>
</html>
HTML_FOOT

# In Datei schreiben
open my $fh, '>', $output_file or die "Kann $output_file nicht öffnen: $!";
print $fh $html;
close $fh;

print "HTML-Datei wurde erfolgreich erstellt: $output_file\n";
