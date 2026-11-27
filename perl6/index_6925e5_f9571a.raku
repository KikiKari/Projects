#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "e51fd64f2d5efdae481e8a74a7739e4b2cc9855e1bb45dfd6a9219e704b29768", "source_sha256": "f9571a381240f9d09733d99d5efdbd1df3ed653107eadfccbced6324e1b78049", "target_language": "perl6"}
# index_6925e5.css — portiert nach perl6
# Quelle: css, Projects@abstractions:css/index_6925e5.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

use v6;

sub MAIN($output-file) {
    my $css-content = generate-css();
    spurt($output-file, $css-content);
}

sub generate-css() {
    my @rules;

    # Root variables
    push @rules, q[:root{
  --bg:#fff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;
  --ac:#6d5bd0; --ac-soft:#efecfb;
  --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;
  color-scheme: light;
}];

    # Dark mode media query
    push @rules, q[@media (prefers-color-scheme: dark){
  :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;
         --ac-soft:#1e1a33; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }
}];

    # Universal selector
    push @rules, q[*{box-sizing:border-box}];

    # Body styles
    push @rules, q[body{margin:0;background:var(--bg);color:var(--text);
     font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}];

    # Wrap container
    push @rules, q[.wrap{max-width:840px;margin:0 auto;padding:0 20px 72px}];

    # Header section
    push @rules, q[header{padding:64px 0 36px;border-bottom:1px solid var(--line)}];

    # Headings
    push @rules, q[h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}];
    push @rules, q[.lede{font-size:18px;color:var(--muted);margin:0 0 20px;max-width:62ch}];
    push @rules, q[h2{font-size:13px;margin:48px 0 14px;text-transform:uppercase;letter-spacing:.06em;
   color:var(--muted);font-weight:650}];
    push @rules, q[h3{font-size:17px;margin:24px 0 6px}];

    # Paragraphs
    push @rules, q[p{margin:0 0 14px;max-width:70ch}];

    # Badges
    push @rules, q[.badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:20px}];
    push @rules, q[.badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;
       background:var(--soft);color:var(--muted);border:1px solid var(--line)}];
    push @rules, q[.badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}];

    # Tables
    push @rules, q[table{border-collapse:collapse;width:100%;font-size:14.5px;margin:0 0 14px}];
    push @rules, q[th,td{text-align:left;padding:9px 10px;border-bottom:1px solid var(--line);vertical-align:top}];
    push @rules, q[th{font-size:12px;text-transform:uppercase;letter-spacing:.04em;color:var(--muted)}];

    # Code elements
    push @rules, q[code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;
     font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}];
    push @rules, q[pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;
    padding:13px 15px;overflow-x:auto;margin:0 0 14px}];
    push @rules, q[pre code{background:none;padding:0}];

    # Card component
    push @rules, q[.card{border:1px solid var(--line);border-radius:12px;padding:18px 20px;background:var(--bg)}];

    # Note component
    push @rules, q[.note{background:var(--warn-soft);border:1px solid transparent;border-radius:10px;
      padding:14px 16px;margin:0 0 16px;font-size:14.5px}];
    push @rules, q[.note b{color:var(--warn)}];

    # Form elements
    push @rules, q[fieldset{border:1px solid var(--line);border-radius:10px;padding:14px 16px;margin:0 0 14px}];
    push @rules, q[legend{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);padding:0 6px}];
    push @rules, q[label.q{display:flex;gap:10px;align-items:flex-start;padding:7px 0;font-size:15px;cursor:pointer}];
    push @rules, q[label.q input{margin-top:4px;flex:none}];
    push @rules, q[label.q span small{display:block;color:var(--muted);font-size:13px}];
    push @rules, q[#ergebnis{margin-top:6px}];

    # Verdict component
    push @rules, q[.verdict{border:1px solid var(--line);border-left:4px solid var(--ac);
         border-radius:10px;padding:16px 18px;background:var(--soft)}];
    push @rules, q[.verdict h3{margin:0 0 6px;font-size:18px}];
    push @rules, q[.verdict .step{font-weight:650;margin:10px 0 0}];
    push @rules, q[.verdict .w{margin-top:12px;padding:11px 13px;background:var(--warn-soft);
            border-radius:8px;font-size:14px}];

    # Probe component
    push @rules, q[.probe{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:12px}];
    push @rules, q[.probe input{flex:1 1 240px;padding:10px 12px;border:1px solid var(--line);
             border-radius:9px;background:var(--bg);color:var(--text);font-size:15px}];

    # Button styles
    push @rules, q[.btn{font-weight:650;font-size:15px;padding:10px 18px;border-radius:9px;
     border:1px solid var(--ac);background:var(--ac);color:#fff;cursor:pointer}];
    push @rules, q[.btn.ghost{background:var(--bg);color:var(--text);border-color:var(--line)}];

    # Footer
    push @rules, q[footer{margin-top:56px;padding-top:22px;border-top:1px solid var(--line);
       color:var(--muted);font-size:14px}];

    # Links
    push @rules, q[a{color:var(--ac)}];

    return @rules.join("\n\n");
}
