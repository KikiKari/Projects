// abstraction-provenance: {"artifact_sha256": "55790d3b330c74ce7405014076f1b2a6ebbe30f208a447e33e105a26ba8ce123", "source_sha256": "c1bffd970108bca04ccb5b3a9aee8861acc4c11c8c4c461ea0c573b20c5e2f21", "target_language": "c"}
// index_4051ed.css — portiert nach c
// Quelle: css, Projects@abstractions:css/index_4051ed.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

#include <stdio.h>
#include <stdlib.h>

void write_css_file(const char* filename) {
    FILE* file = fopen(filename, "w");
    if (!file) {
        perror("Failed to open file");
        return;
    }

    fprintf(file, "/* abstraction-provenance: {\"artifact_sha256\": \"c0c2aa7750474bc55c705ff744495daa7aef344568dc1eadca3165b431837a79\", \"source_sha256\": \"4051edeb8cf3a53e4fdc417f40a86a4e9f16f24bcbc4b7334babe6d8f7500c24\", \"target_language\": \"css\"} */\n");
    fprintf(file, "/* index.html — portiert nach css */\n");
    fprintf(file, "/* Quelle: html, Projects@Telegram-Monitor:web/index.html */\n");
    fprintf(file, "/* Erzeugt: 2026-11-26 durch ABSTRACTIONS_MANAGER.py */\n\n");

    fprintf(file, ":root{\n");
    fprintf(file, "  --bg:#f6f7f9; --card:#fff; --line:#e3e6ea; --text:#16191d; --muted:#6b7280;\n");
    fprintf(file, "  --accent:#2481cc; --accent-soft:#e8f2fb; --discord:#5865f2; --discord-soft:#eceefe;\n");
    fprintf(file, "  --ok:#15803d; --warn:#b45309; --err:#b91c1c;\n");
    fprintf(file, "  color-scheme: light;\n");
    fprintf(file, "}\n");

    fprintf(file, "*{box-sizing:border-box}\n");
    
    fprintf(file, "body{margin:0;background:var(--bg);color:var(--text);\n");
    fprintf(file, "     font:15px/1.5 -apple-system,BlinkMacSystemFont,\"Segoe UI\",Roboto,sans-serif}\n");

    fprintf(file, "header{background:var(--card);border-bottom:1px solid var(--line);padding:14px 20px;\n");
    fprintf(file, "       display:flex;align-items:center;gap:14px;flex-wrap:wrap;position:sticky;top:0;z-index:5}\n");

    fprintf(file, "header h1{font-size:17px;margin:0;font-weight:650}\n");

    fprintf(file, ".pill{font-size:11px;padding:2px 8px;border-radius:99px;background:var(--accent-soft);\n");
    fprintf(file, "      color:var(--accent);font-weight:600;white-space:nowrap}\n");

    fprintf(file, ".pill.off{background:#f1f2f4;color:var(--muted)}\n");

    fprintf(file, ".pill.dc{background:var(--discord-soft);color:var(--discord)}\n");

    fprintf(file, "nav{display:flex;gap:4px;padding:0 20px;background:var(--card);border-bottom:1px solid var(--line)}\n");

    fprintf(file, "nav button{border:0;background:none;padding:11px 14px;font:inherit;font-weight:500;\n");
    fprintf(file, "           color:var(--muted);cursor:pointer;border-bottom:2px solid transparent}\n");

    fprintf(file, "nav button.active{color:var(--accent);border-bottom-color:var(--accent)}\n");

    fprintf(file, "main{padding:20px;max-width:1080px;margin:0 auto}\n");

    fprintf(file, ".panel{display:none} .panel.active{display:block}\n");

    fprintf(file, ".row{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:14px}\n");

    fprintf(file, "input,select{padding:9px 11px;border:1px solid var(--line);border-radius:8px;font:inherit;\n");
    fprintf(file, "             background:var(--card);min-width:180px}\n");

    fprintf(file, "input:focus,select:focus{outline:2px solid var(--accent-soft);border-color:var(--accent)}\n");

    fprintf(file, "button.go{background:var(--accent);color:#fff;border:0;border-radius:8px;padding:9px 16px;\n");
    fprintf(file, "          font:inherit;font-weight:600;cursor:pointer}\n");

    fprintf(file, "button.go.sec{background:var(--card);color:var(--text);border:1px solid var(--line)}\n");

    fprintf(file, "button.go.dc{background:var(--discord)}\n");

    fprintf(file, "button.go:disabled{opacity:.5;cursor:default}\n");

    fprintf(file, ".card{background:var(--card);border:1px solid var(--line);border-radius:12px;\n");
    fprintf(file, "      padding:14px 16px;margin-bottom:10px}\n");

    fprintf(file, ".card h3{margin:0 0 2px;font-size:15px;display:flex;align-items:center;gap:8px;flex-wrap:wrap}\n");

    fprintf(file, ".card .meta{color:var(--muted);font-size:13px}\n");

    fprintf(file, ".card .desc{margin-top:7px;font-size:13.5px;white-space:pre-wrap}\n");

    fprintf(file, ".avatar{width:34px;height:34px;border-radius:50%%;object-fit:cover;background:#eceff3;flex:none}\n");

    fprintf(file, ".head{display:flex;gap:11px;align-items:flex-start}\n");

    fprintf(file, ".score{font-variant-numeric:tabular-nums;font-size:12px;color:var(--muted);\n");
    fprintf(file, "       border:1px solid var(--line);border-radius:6px;padding:1px 6px}\n");

    fprintf(file, ".tag{font-size:11px;padding:2px 7px;border-radius:5px;background:#f1f2f4;color:var(--muted);font-weight:600}\n");

    fprintf(file, ".tag.ok{background:#e7f6ec;color:var(--ok)} .tag.no{background:#fdeceb;color:var(--err)}\n");

    fprintf(file, ".post{border-left:3px solid var(--accent-soft);padding:6px 0 6px 11px;margin:9px 0;font-size:13.5px}\n");

    fprintf(file, ".post .when{color:var(--muted);font-size:12px}\n");

    fprintf(file, ".post .txt{white-space:pre-wrap;margin-top:2px}\n");

    fprintf(file, "a{color:var(--accent);text-decoration:none} a:hover{text-decoration:underline}\n");

    fprintf(file, ".empty{color:var(--muted);padding:22px;text-align:center;border:1px dashed var(--line);border-radius:12px}\n");

    fprintf(file, ".err{background:#fdeceb;border:1px solid #f5c6c2;color:var(--err);padding:10px 13px;\n");
    fprintf(file, "     border-radius:8px;margin-bottom:12px;font-size:13.5px}\n");

    fprintf(file, ".spin{color:var(--muted);padding:16px 0}\n");

    fprintf(file, "table{width:100%%;border-collapse:collapse;font-size:13.5px}\n");

    fprintf(file, "th,td{text-align:left;padding:8px 10px;border-bottom:1px solid var(--line);vertical-align:top}\n");

    fprintf(file, "th{color:var(--muted);font-weight:600;font-size:12px;text-transform:uppercase;letter-spacing:.03em}\n");

    fprintf(file, "code{background:#f1f2f4;padding:1px 5px;border-radius:4px;font-size:12.5px}\n");

    fprintf(file, ".hint{color:var(--muted);font-size:13px;margin:-4px 0 14px}\n");

    fprintf(file, ".stream{max-height:460px;overflow:auto;border:1px solid var(--line);border-radius:10px;\n");
    fprintf(file, "        padding:6px 12px;margin-top:10px;background:var(--card)}\n");

    fprintf(file, ".post.fresh{border-left-color:var(--ok);background:#f3fbf5}\n");

    fprintf(file, ".post.fresh .when::after{content:\" NEU\";color:var(--ok);font-weight:700}\n");

    fprintf(file, ".dot{width:8px;height:8px;border-radius:50%%;background:var(--ok);display:inline-block;\n");
    fprintf(file, "     margin-right:6px;animation:pulse 2s infinite}\n");

    fprintf(file, "@keyframes pulse{0%%,100%%{opacity:1}50%%{opacity:.35}}\n");

    fprintf(file, ".idle{background:var(--muted)!important;animation:none}\n");

    fprintf(file, ".tt-live{background:#fe2c55;color:#fff;font-weight:700;font-size:11px;\n");
    fprintf(file, "         padding:2px 9px;border-radius:99px}\n");

    fprintf(file, ".tt-off{background:#f1f2f4;color:var(--muted);font-weight:700;font-size:11px;\n");
    fprintf(file, "        padding:2px 9px;border-radius:99px}\n");

    fprintf(file, ".tt-player{position:relative;width:100%%;max-width:340px;aspect-ratio:9/16;background:#000;\n");
    fprintf(file, "           border-radius:10px;overflow:hidden;margin-top:10px;border:1px solid var(--line)}\n");

    fprintf(file, ".tt-player iframe{position:absolute;inset:0;width:100%%;height:100%%;border:0}\n");

    fprintf(file, ".ev{display:flex;gap:10px;padding:7px 0;border-bottom:1px solid var(--line);font-size:13.5px}\n");

    fprintf(file, ".ev:last-child{border-bottom:0}\n");

    fprintf(file, ".ev .k{font-weight:650;white-space:nowrap}\n");

    fprintf(file, ".ev .k.start{color:#fe2c55} .ev .k.end{color:var(--muted)}\n");

    fclose(file);
}

int main(int argc, char* argv[]) {
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <output_filename>\n", argv[0]);
        return 1;
    }

    write_css_file(argv[1]);
    return 0;
}
