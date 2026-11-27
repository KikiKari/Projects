#!/usr/bin/env raku
# abstraction-provenance: {"artifact_sha256": "8b6a65f50c9816371f5b1086b5533bc637c4a9792a3b36ea523f3d18cb68dffd", "source_sha256": "f95cba00197f4650dddde02431fe14a0ca1baea932052e66b16f5778582e944f", "target_language": "perl6"}
# status-overview.css — portiert nach perl6
# Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview.css
# Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

# This script generates the status-overview.css file
# Usage: raku status-overview.raku > status-overview.css

sub MAIN($output-file? = 'status-overview.css') {
    my $css-content = generate-css();
    
    if $output-file {
        spurt $output-file, $css-content;
        say "CSS file written to $output-file";
    } else {
        print $css-content;
    }
}

sub generate-css() {
    return q:to/END/;
*{box-sizing:border-box}html,body{margin:0;min-height:100%;background:#101015;color:#fff;font:14px system-ui,sans-serif}body{display:flex;flex-direction:column;height:100vh}header{display:flex;gap:1em;align-items:baseline;padding:0 12px}h1{font-size:17px;margin:8px 0}header p{font-size:12px;color:#bbb;margin:0}main{flex:1;min-height:0;display:grid;grid-template-columns:repeat(3,minmax(0,1fr));grid-template-rows:repeat(3,minmax(0,1fr));gap:4px;padding:0}.tile{min-width:0;min-height:0;display:flex;flex-direction:column;background:#202026;border:1px solid #393940}.tile h2{font-size:13px;margin:3px 8px}.tile video{min-height:0;width:100%;flex:1;object-fit:contain;background:#000}.tile p{font-size:11px;margin:3px 8px;color:#ddd}

main.grid2{grid-template-columns:repeat(2,minmax(0,1fr));grid-template-rows:repeat(2,minmax(0,1fr))}.tile[hidden]{display:none}
END
}
