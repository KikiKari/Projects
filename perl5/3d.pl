#!/usr/bin/perl
# 3d.js — portiert nach perl5
# Quelle: javascript, Projects@abstractions:javascript/3d.js
# Erzeugt: 2026-08-18 durch ABSTRACTIONS_MANAGER.py

use strict;
use warnings;
use HTML::Entities;
use JSON::PP;

# Erzeuge das HTML-Dokument
sub create_document {
    my $html = '<!DOCTYPE html><html lang="de"><head>';
    
    # Meta-Tags
    $html .= '<meta charset="utf-8">';
    $html .= '<meta name="viewport" content="width=device-width, initial-scale=1">';
    $html .= '<title>Tagesstatus Live Public — Interaktive Architektur</title>';
    $html .= '<meta name="description" content="Acht Dienste, ein Blick: Tokens, Abruf, Kacheln — drehen, zoomen, Knoten auswählen.">';
    $html .= '<meta name="theme-color" content="#0f766e">';
    
    # Styles
    $html .= '<style>';
    $html .= ':root{';
    $html .= '--bg:#fbfaf7; --panel:#fff; --line:#e6e3dc; --text:#16191d; --muted:#5f6773;';
    $html .= '--ac:#0f766e; --buehne:#0e1420; --buehne-line:#1d2739;';
    $html .= 'color-scheme: light;';
    $html .= '}';
    $html .= '@media (prefers-color-scheme: dark){';
    $html .= ':root{ --bg:#0f1115; --panel:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;';
    $html .= 'color-scheme: dark; }';
    $html .= '}';
    $html .= '*{box-sizing:border-box}';
    $html .= 'body{margin:0;background:var(--bg);color:var(--text);';
    $html .= 'font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}';
    $html .= '.wrap{max-width:1240px;margin:0 auto;padding:34px 22px 60px}';
    $html .= '.technik{font-size:12px;font-weight:700;letter-spacing:.1em;text-transform:uppercase;';
    $html .= 'color:var(--ac);margin:0 0 10px}';
    $html .= 'h1{font-size:clamp(30px,5vw,52px);line-height:1.05;margin:0 0 14px;letter-spacing:-.03em}';
    $html .= '.lede{font-size:16.5px;color:var(--muted);max-width:62ch;margin:0 0 26px}';
    $html .= '.raster{display:grid;grid-template-columns:minmax(0,1fr) 288px;gap:18px;align-items:start}';
    $html .= '@media (max-width:880px){ .raster{grid-template-columns:1fr} }';
    $html .= '.buehne{position:relative;background:var(--buehne);border-radius:14px;overflow:hidden;';
    $html .= 'min-height:520px;aspect-ratio:16/11}';
    $html .= '.buehne canvas{display:block;width:100%;height:100%}';
    $html .= '.knoepfe{position:absolute;top:14px;right:14px;display:flex;gap:8px;z-index:2}';
    $html .= 'button{font:inherit;font-size:14px;font-weight:650;padding:9px 14px;border-radius:9px;';
    $html .= 'border:1px solid var(--line);background:var(--panel);color:var(--text);cursor:pointer}';
    $html .= 'button:hover{border-color:var(--ac)}';
    $html .= 'button[aria-pressed="true"]{background:var(--ac);border-color:var(--ac);color:#fff}';
    $html .= '.karte{background:var(--panel);border:1px solid var(--line);border-radius:14px;padding:20px}';
    $html .= '.karte h2{font-size:11px;font-weight:700;letter-spacing:.09em;text-transform:uppercase;';
    $html .= 'color:var(--muted);margin:0 0 12px}';
    $html .= '.karte h3{font-size:23px;margin:0 0 4px;letter-spacing:-.02em}';
    $html .= '.karte .sub{color:var(--muted);margin:0 0 18px;font-size:14.5px}';
    $html .= '.feld{border-top:1px solid var(--line);padding:12px 0 0;margin:0 0 12px}';
    $html .= '.feld dt{font-size:11px;font-weight:700;letter-spacing:.08em;text-transform:uppercase;';
    $html .= 'color:var(--muted);margin:0 0 3px}';
    $html .= '.feld dd{margin:0;font-weight:650}';
    $html .= '.blaettern{display:flex;gap:8px;margin-top:16px}';
    $html .= '.blaettern button{flex:1;text-align:center;line-height:1.25;padding:11px 8px}';
    $html .= '.legende{display:flex;gap:22px;flex-wrap:wrap;margin:16px 0 0;font-size:13.5px;color:var(--muted)}';
    $html .= '.legende span{display:inline-flex;align-items:center;gap:9px}';
    $html .= '.strich{width:30px;height:0;border-top-width:3px;border-top-style:solid;display:inline-block}';
    $html .= '.fuss{margin:14px 0 0;font-size:13px;color:var(--muted);max-width:80ch}';
    $html .= '.fehler{padding:40px;text-align:center;color:var(--muted)}';
    $html .= 'a{color:var(--ac)}';
    $html .= '</style>';
    
    $html .= '</head><body>';
    $html .= '<div class="wrap">';
    $html .= '<p class="technik">three.js · r128</p>';
    $html .= '<h1>Tagesstatus Live Public</h1>';
    $html .= '<p class="lede">Acht Dienste, ein Blick: Tokens, Abruf, Kacheln — drehen, zoomen, Knoten auswählen.</p>';
    $html .= '<div class="raster">';
    $html .= '<div class="buehne" id="buehne">';
    $html .= '<div class="knoepfe">';
    $html .= '<button id="btn-plus" title="Näher">+</button>';
    $html .= '<button id="btn-minus" title="Weiter weg">−</button>';
    $html .= '<button id="btn-reset">Zurücksetzen</button>';
    $html .= '<button id="btn-iso" aria-pressed="true" title="Isometrisch oder perspektivisch">Iso</button>';
    $html .= '</div>';
    $html .= '</div>';
    $html .= '<aside class="karte">';
    $html .= '<h2>Ausgewählter Knoten</h2>';
    $html .= '<h3 id="k-name">—</h3>';
    $html .= '<p class="sub" id="k-sub">Knoten anklicken oder durchblättern</p>';
    $html .= '<dl class="feld">';
    $html .= '<dt>Schicht</dt>';
    $html .= '<dd id="k-schicht">—</dd>';
    $html .= '</dl>';
    $html .= '<dl class="feld">';
    $html .= '<dt>ID</dt>';
    $html .= '<dd id="k-id">—</dd>';
    $html .= '</dl>';
    $html .= '<div class="blaettern">';
    $html .= '<button id="btn-prev">←<br>Vorheriger</button>';
    $html .= '<button id="btn-next">Nächster<br>→</button>';
    $html .= '</div>';
    $html .= '</aside>';
    $html .= '</div>';
    $html .= '<div class="legende" id="legende"></div>';
    $html .= '<p class="fuss">Schematische Dokumentationsansicht — Blockgrößen messen weder Datenmenge noch Leistung. Keine Telemetrie, keine Fernabfragen: Die Seite lädt einmalig three.js vom CDN und rechnet danach ausschließlich lokal.</p>';
    $html .= '</div>';
    $html .= '</body></html>';
    
    return $html;
}

# Hauptfunktion zur Erstellung der 3D-Szene
sub create_3d_scene {
    my ($html) = @_;
    
    my $spec = {
        "schichten" => [
            {
                "name" => "Tokens",
                "farbe" => "#5f6773",
                "blocks" => [
                    {"id" => "abfrage-beim-oeffnen", "name" => "Abfrage beim Oeffnen", "untertitel" => "kein Vorbelegen"},
                    {"id" => "localstorage", "name" => "localStorage", "untertitel" => "nur lokal"},
                    {"id" => "keine-vorbelegung", "name" => "keine Vorbelegung", "untertitel" => "leer geliefert"}
                ]
            },
            {
                "name" => "Quellen",
                "farbe" => "#2481cc",
                "blocks" => [
                    {"id" => "github", "name" => "GitHub", "untertitel" => "Repos, Kontingent"},
                    {"id" => "vercel", "name" => "Vercel", "untertitel" => "Deployments"},
                    {"id" => "docker-hub", "name" => "Docker Hub", "untertitel" => "Abbilder"},
                    {"id" => "openrouter", "name" => "OpenRouter", "untertitel" => "Guthaben"},
                    {"id" => "openai", "name" => "OpenAI", "untertitel" => "Admin-Key"},
                    {"id" => "anthropic", "name" => "Anthropic", "untertitel" => "Admin-Key"},
                    {"id" => "tailscale", "name" => "Tailscale", "untertitel" => "Geraete"},
                    {"id" => "clawhub", "name" => "ClawHub", "untertitel" => "Skills"}
                ]
            },
            {
                "name" => "Abruf",
                "farbe" => "#6d5bd0",
                "blocks" => [
                    {"id" => "fetch-je-quelle", "name" => "fetch je Quelle", "untertitel" => "direkt"},
                    {"id" => "cors-pruefung", "name" => "CORS-Pruefung", "untertitel" => "entscheidet"},
                    {"id" => "fehler-isolieren", "name" => "Fehler isolieren", "untertitel" => "je Kachel"}
                ]
            },
            {
                "name" => "Ausgabe",
                "farbe" => "#0f766e",
                "blocks" => [
                    {"id" => "kacheln", "name" => "Kacheln", "untertitel" => "ein Blick"},
                    {"id" => "verbrauch", "name" => "Verbrauch", "untertitel" => "Zahlen"},
                    {"id" => "keine-daten-hinweis", "name" => "keine Daten = Hinweis", "untertitel" => "mit Grund"}
                ]
            }
        ],
        "kanten" => [
            {"von" => "abfrage-beim-oeffnen", "nach" => "github", "art" => "fluss"},
            {"von" => "localstorage", "nach" => "vercel", "art" => "fluss"},
            {"von" => "keine-vorbelegung", "nach" => "docker-hub", "art" => "fluss"},
            {"von" => "github", "nach" => "fetch-je-quelle", "art" => "fluss"},
            {"von" => "vercel", "nach" => "cors-pruefung", "art" => "fluss"},
            {"von" => "docker-hub", "nach" => "fehler-isolieren", "art" => "fluss"},
            {"von" => "openrouter", "nach" => "fetch-je-quelle", "art" => "fluss"},
            {"von" => "openai", "nach" => "cors-pruefung", "art" => "fluss"},
            {"von" => "anthropic", "nach" => "fehler-isolieren", "art" => "fluss"},
            {"von" => "tailscale", "nach" => "fetch-je-quelle", "art" => "fluss"},
            {"von" => "clawhub", "nach" => "cors-pruefung", "art" => "fluss"},
            {"von" => "fetch-je-quelle", "nach" => "kacheln", "art" => "fluss"},
            {"von" => "cors-pruefung", "nach" => "verbrauch", "art" => "fluss"},
            {"von" => "fehler-isolieren", "nach" => "keine-daten-hinweis", "art" => "fluss"}
        ],
        "kantenarten" => [
            {"art" => "fluss", "farbe" => "#0f766e", "stil" => "voll", "text" => "Fluss von unten nach oben"}
        ]
    };
    
    # Füge Canvas-Element hinzu
    my $canvas_html = '<canvas width="800" height="600" style="display:block;width:100%;height:100%"></canvas>';
    $html =~ s/<div class="buehne" id="buehne">([^<]*)<div class="knoepfe"/<div class="buehne" id="buehne">$1$canvas_html<div class="knoepfe"/;
    
    # Erstelle Legende
    my $legend_html = '';
    for my $art (@{$spec->{kantenarten}}) {
        my $stil = $art->{stil} eq "gestrichelt" ? "dashed" : "solid";
        $legend_html .= "<span><i class=\"strich\" style=\"border-top-color:$art->{farbe};border-top-style:$stil\"></i>$art->{text}</span>";
    }
    $html =~ s/<div class="legende" id="legende"><\/div>/<div class="legende" id="legende">$legend_html<\/div>/;
    
    return $html;
}

# Hauptfunktion
sub main {
    # Prüfe, ob ein Dateiname übergeben wurde
    if (@ARGV < 1) {
        print STDERR "Verwendung: perl 3d.pl <dateiname>\n";
        exit 1;
    }
    
    my $filename = $ARGV[0];
    
    # Erstelle das Dokument
    my $html = create_document();
    
    # Erstelle die 3D-Szene
    $html = create_3d_scene($html);
    
    # Schreibe das HTML in eine Datei
    open(my $fh, '>', $filename) or die "Kann Datei $filename nicht öffnen: $!";
    print $fh $html;
    close($fh);
    
    print "HTML-Datei wurde erfolgreich erstellt: $filename\n";
}

main() unless caller;
