// abstraction-provenance: {"artifact_sha256": "04c3169964c4a10e303486d454fe076bca08333a2b75cc7f73345595214eb898", "source_sha256": "9be2a45ff3b835da1be1793cc88c8cb54d6a2456cf2ccc358c8243df836440e3", "target_language": "cpp"}
// status-overview-panel.css — portiert nach cpp
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/status-overview-panel.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <iostream>
#include <fstream>
#include <string>

int main(int argc, char* argv[]) {
    if (argc != 2) {
        std::cerr << "Usage: " << argv[0] << " <output-file>" << std::endl;
        return 1;
    }

    std::ofstream file(argv[1]);
    if (!file.is_open()) {
        std::cerr << "Error: Could not open file " << argv[1] << std::endl;
        return 1;
    }

    file << ".overview-row { display:grid; grid-template-columns:24px minmax(0,1fr) 11px 22px auto; gap:7px; align-items:center; margin:6px 0; }\n";
    file << ".overview-row input { min-width:0; width:100%; }\n";
    file << ".overview-state { width:11px; height:11px; border-radius:50%; background:#888; }\n";
    file << ".overview-state.online { background:var(--good); box-shadow:0 0 0 3px color-mix(in srgb, var(--good) 15%, transparent); }\n";
    file << ".overview-state.offline { background:var(--bad); box-shadow:0 0 0 3px color-mix(in srgb, var(--bad) 15%, transparent); }\n";
    file << ".overview-state.checking, .overview-state.error { background:var(--warn); }\n";
    file << ".overview-count { font-size:11px; text-align:center; font-variant-numeric:tabular-nums; }\n";
    file << ".overview-actions { display:grid; grid-template-columns:44px repeat(2,minmax(0,1fr)); gap:6px; align-items:stretch; }\n";
    file << ".overview-actions button { min-width:0; padding:8px 2px; font-size:11px; white-space:nowrap; }\n\n";
    
    file << "#overview-rows { display:flex; flex-direction:column; }\n";
    file << ".monitor-settings > label:not(.option-row) { display:block; margin:12px 0; }\n";
    file << ".monitor-settings .option-row input { appearance:auto; width:13px; height:13px; min-width:13px; background:none; }\n";
    file << ".overview-link { padding:8px 0; border-bottom:1px solid #bbb; overflow-wrap:anywhere; }\n";
    file << ".overview-link p { margin:4px 0; }\n\n";
    
    file << ".overview-row .overview-retry { width:24px; min-width:24px; height:26px; min-height:26px; padding:0; background-image:var(--icon-reset); background-size:20px; background-position:center; background-repeat:no-repeat; }\n\n";
    
    file << ".top-setting input { appearance:auto; -webkit-appearance:checkbox; width:13px; height:13px; min-width:13px; background:none; }\n\n";
    
    file << ".overview-visually-hidden { position:absolute; width:1px; height:1px; padding:0; margin:-1px; overflow:hidden; clip:rect(0,0,0,0); white-space:nowrap; border:0; }\n";
    file << ".overview-row[hidden] { display:none; }\n";

    file.close();
    return 0;
}
