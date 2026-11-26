// abstraction-provenance: {"artifact_sha256": "78d4f11e51f223192f5492239d2514ce5c74275f89965e1fcc774cba70448cd7", "source_sha256": "fce23ec10c43acef00ba36b3975889539f87b908bd4cfce77616443d2b5f569e", "target_language": "c"}
// icon-controls.css — portiert nach c
// Quelle: css, Projects@TikTok-Live-Companion:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-Android:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@TikTok-Live-Companion-iOS:plugin-source/browser-extension/icon-controls.css
// auch in: Projects@vercel/install-and-configure-vercel-s-8vf8rt:plugin-source/browser-extension/icon-controls.css
// Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// Function to write the CSS content to a file
void write_css_content(FILE *file, const char *style_name) {
    fprintf(file, "html[data-icon-style=\"%s\"] {", style_name);
    fprintf(file, "--icon-auto-chat-refresh-counter:url(\"icons/%s/auto-chat-refresh-counter.png\");", style_name);
    fprintf(file, "--icon-browser:url(\"icons/%s/browser.png\");", style_name);
    fprintf(file, "--icon-captions:url(\"icons/%s/captions.png\");", style_name);
    fprintf(file, "--icon-chat-counter:url(\"icons/%s/chat-counter.png\");", style_name);
    fprintf(file, "--icon-fullscreen:url(\"icons/%s/fullscreen.png\");", style_name);
    fprintf(file, "--icon-mute:url(\"icons/%s/mute.png\");", style_name);
    fprintf(file, "--icon-off:url(\"icons/%s/off.png\");", style_name);
    fprintf(file, "--icon-on:url(\"icons/%s/on.png\");", style_name);
    fprintf(file, "--icon-pip:url(\"icons/%s/pip.png\");", style_name);
    fprintf(file, "--icon-play:url(\"icons/%s/play.png\");", style_name);
    fprintf(file, "--icon-player:url(\"icons/%s/player.png\");", style_name);
    fprintf(file, "--icon-protection-slider:url(\"icons/%s/protection-slider.png\");", style_name);
    fprintf(file, "--icon-recommendation-counter:url(\"icons/%s/recommendation-counter.png\");", style_name);
    fprintf(file, "--icon-report:url(\"icons/%s/report.png\");", style_name);
    fprintf(file, "--icon-reset:url(\"icons/%s/reset.png\");", style_name);
    fprintf(file, "--icon-settings:url(\"icons/%s/settings.png\");", style_name);
    fprintf(file, "--icon-status:url(\"icons/%s/status.png\");", style_name);
    fprintf(file, "--icon-stop:url(\"icons/%s/stop.png\");", style_name);
    fprintf(file, "--icon-unmute:url(\"icons/%s/unmute.png\");", style_name);
    fprintf(file, "--icon-volume-slider:url(\"icons/%s/volume-slider.png\");", style_name);
    fprintf(file, "}\n");
}

int main(int argc, char *argv[]) {
    // Check if filename argument is provided
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_filename>\n", argv[0]);
        return 1;
    }

    // Open file for writing
    FILE *file = fopen(argv[1], "w");
    if (!file) {
        perror("Error opening file");
        return 1;
    }

    // Write the CSS content for each style
    write_css_content(file, "plastisch");
    write_css_content(file, "glass");
    write_css_content(file, "linear");

    // Write common CSS rules
    fprintf(file, "button[data-control-icon]::before,.control-icon::before { content:\"\"; display:inline-block; width:32px; height:32px; flex:0 0 32px; background:var(--control-icon) center/contain no-repeat; vertical-align:middle; margin-inline-end:0; pointer-events:none; }\n");
    fprintf(file, "button[data-control-icon] { min-height:44px; min-width:44px; font-size:0; display:inline-flex; align-items:center; justify-content:center; }\n");
    fprintf(file, "button[data-control-icon][hidden] { display:none; }\n");
    fprintf(file, "input[type=\"checkbox\"] { appearance:none; -webkit-appearance:none; width:44px; height:44px; min-width:44px; border:0; background:var(--icon-off) center/40px no-repeat; cursor:pointer; vertical-align:middle; }\n");
    fprintf(file, "input[type=\"checkbox\"]:checked { background-image:var(--icon-on); }\n");
    fprintf(file, "input[type=\"checkbox\"]:focus-visible,button[data-control-icon]:focus-visible { outline:2px solid #1769df; outline-offset:2px; }\n");
    fprintf(file, "input[type=\"checkbox\"]:disabled { opacity:.45; cursor:default; }\n");
    fprintf(file, ".control-icon { display:inline-flex; align-items:center; }\n");
    fprintf(file, "input[type=\"range\"] { min-height:32px; }\n");
    fprintf(file, ".icon-style-setting { display:flex; align-items:center; gap:8px; }\n\n");

    // Write control icon definitions
    const char* icons[] = {
        "auto-chat-refresh-counter", "browser", "captions", "chat-counter",
        "fullscreen", "mute", "off", "on", "pip", "play", "player",
        "protection-slider", "recommendation-counter", "report", "reset",
        "settings", "status", "stop", "unmute", "volume-slider"
    };
    
    for (int i = 0; i < 20; i++) {
        fprintf(file, "[data-control-icon=\"%s\"] { --control-icon:var(--icon-%s); }\n", 
                icons[i], icons[i]);
    }

    // Close file
    fclose(file);
    
    return 0;
}
