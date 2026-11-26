#!/usr/bin/perl
# abstraction-provenance: {"artifact_sha256": "094ca26eb934386ca6e2262f33e32393d247133cedfb37ddf60b3489c9b8e7dd", "source_sha256": "fce23ec10c43acef00ba36b3975889539f87b908bd4cfce77616443d2b5f569e", "target_language": "perl5"}
# icon-controls.css — portiert nach perl5
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
# auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
# Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;

# Prüfen, ob ein Dateiname übergeben wurde
if (@ARGV != 1) {
    die "Verwendung: $0 <ausgabedatei>\n";
}

my $ausgabedatei = $ARGV[0];

# Öffnen der Ausgabedatei zum Schreiben
open(my $fh, '>', $ausgabedatei) or die "Kann Datei '$ausgabedatei' nicht öffnen: $!";

# Definition der Icon-Stile mit zugehörigen Pfaden
my @stile = qw(plastisch glass linear);

# Generierung der CSS-Regeln für jeden Stil
for my $stil (@stile) {
    print $fh "html[data-icon-style=\"$stil\"] {";
    print $fh "--icon-auto-chat-refresh-counter:url(\"icons/$stil/auto-chat-refresh-counter.png\");";
    print $fh "--icon-browser:url(\"icons/$stil/browser.png\");";
    print $fh "--icon-captions:url(\"icons/$stil/captions.png\");";
    print $fh "--icon-chat-counter:url(\"icons/$stil/chat-counter.png\");";
    print $fh "--icon-fullscreen:url(\"icons/$stil/fullscreen.png\");";
    print $fh "--icon-mute:url(\"icons/$stil/mute.png\");";
    print $fh "--icon-off:url(\"icons/$stil/off.png\");";
    print $fh "--icon-on:url(\"icons/$stil/on.png\");";
    print $fh "--icon-pip:url(\"icons/$stil/pip.png\");";
    print $fh "--icon-play:url(\"icons/$stil/play.png\");";
    print $fh "--icon-player:url(\"icons/$stil/player.png\");";
    print $fh "--icon-protection-slider:url(\"icons/$stil/protection-slider.png\");";
    print $fh "--icon-recommendation-counter:url(\"icons/$stil/recommendation-counter.png\");";
    print $fh "--icon-report:url(\"icons/$stil/report.png\");";
    print $fh "--icon-reset:url(\"icons/$stil/reset.png\");";
    print $fh "--icon-settings:url(\"icons/$stil/settings.png\");";
    print $fh "--icon-status:url(\"icons/$stil/status.png\");";
    print $fh "--icon-stop:url(\"icons/$stil/stop.png\");";
    print $fh "--icon-unmute:url(\"icons/$stil/unmute.png\");";
    print $fh "--icon-volume-slider:url(\"icons/$stil/volume-slider.png\");";
    print $fh "}\n";
}

# Gemeinsame CSS-Regeln für alle Stile
print $fh <<'CSS';
button[data-control-icon]::before,
.control-icon::before {
  content: "";
  display: inline-block;
  width: 32px;
  height: 32px;
  flex: 0 0 32px;
  background: var(--control-icon) center/contain no-repeat;
  vertical-align: middle;
  margin-inline-end: 0;
  pointer-events: none;
}

button[data-control-icon] {
  min-height: 44px;
  min-width: 44px;
  font-size: 0;
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

button[data-control-icon][hidden] {
  display: none;
}

input[type="checkbox"] {
  appearance: none;
  -webkit-appearance: none;
  width: 44px;
  height: 44px;
  min-width: 44px;
  border: 0;
  background: var(--icon-off) center/40px no-repeat;
  cursor: pointer;
  vertical-align: middle;
}

input[type="checkbox"]:checked {
  background-image: var(--icon-on);
}

input[type="checkbox"]:focus-visible,
button[data-control-icon]:focus-visible {
  outline: 2px solid #1769df;
  outline-offset: 2px;
}

input[type="checkbox"]:disabled {
  opacity: .45;
  cursor: default;
}

.control-icon {
  display: inline-flex;
  align-items: center;
}

input[type="range"] {
  min-height: 32px;
}

.icon-style-setting {
  display: flex;
  align-items: center;
  gap: 8px;
}

[data-control-icon="auto-chat-refresh-counter"] {
  --control-icon: var(--icon-auto-chat-refresh-counter);
}

[data-control-icon="browser"] {
  --control-icon: var(--icon-browser);
}

[data-control-icon="captions"] {
  --control-icon: var(--icon-captions);
}

[data-control-icon="chat-counter"] {
  --control-icon: var(--icon-chat-counter);
}

[data-control-icon="fullscreen"] {
  --control-icon: var(--icon-fullscreen);
}

[data-control-icon="mute"] {
  --control-icon: var(--icon-mute);
}

[data-control-icon="off"] {
  --control-icon: var(--icon-off);
}

[data-control-icon="on"] {
  --control-icon: var(--icon-on);
}

[data-control-icon="pip"] {
  --control-icon: var(--icon-pip);
}

[data-control-icon="play"] {
  --control-icon: var(--icon-play);
}

[data-control-icon="player"] {
  --control-icon: var(--icon-player);
}

[data-control-icon="protection-slider"] {
  --control-icon: var(--icon-protection-slider);
}

[data-control-icon="recommendation-counter"] {
  --control-icon: var(--icon-recommendation-counter);
}

[data-control-icon="report"] {
  --control-icon: var(--icon-report);
}

[data-control-icon="reset"] {
  --control-icon: var(--icon-reset);
}

[data-control-icon="settings"] {
  --control-icon: var(--icon-settings);
}

[data-control-icon="status"] {
  --control-icon: var(--icon-status);
}

[data-control-icon="stop"] {
  --control-icon: var(--icon-stop);
}

[data-control-icon="unmute"] {
  --control-icon: var(--icon-unmute);
}

[data-control-icon="volume-slider"] {
  --control-icon: var(--icon-volume-slider);
}
CSS

close($fh);

print "CSS-Datei erfolgreich erstellt: $ausgabedatei\n";
