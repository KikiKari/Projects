// abstraction-provenance: {"artifact_sha256": "0f284e805b12a072ba5a3b01396c3dea804b7e0b3bacfe3ab117e620e445931a", "source_sha256": "f9571a381240f9d09733d99d5efdbd1df3ed653107eadfccbced6324e1b78049", "target_language": "go"}
// index_6925e5.css — portiert nach go
// Quelle: css, Projects@abstractions:css/index_6925e5.css
// Erzeugt: 2026-11-27 durch ABSTRACTIONS_MANAGER.py

package main

import (
	"fmt"
	"os"
)

func main() {
	if len(os.Args) != 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s <output-file>\n", os.Args[0])
		os.Exit(1)
	}

	filename := os.Args[1]
	
	cssContent := `:root{
  --bg:#fff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#5f6773;
  --ac:#6d5bd0; --ac-soft:#efecfb;
  --ok:#15803d; --ok-soft:#e7f6ec; --warn:#b45309; --warn-soft:#fdf3e3;
  color-scheme: light;
}
@media (prefers-color-scheme: dark){
  :root{ --bg:#0f1115; --soft:#171a21; --line:#262b36; --text:#f2f4f8; --muted:#9aa3b2;
         --ac-soft:#1e1a33; --ok-soft:#12261a; --warn-soft:#2c2110; color-scheme: dark; }
}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--text);
     font:16px/1.6 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
.wrap{max-width:840px;margin:0 auto;padding:0 20px 72px}
header{padding:64px 0 36px;border-bottom:1px solid var(--line)}
h1{font-size:34px;line-height:1.2;margin:0 0 12px;letter-spacing:-.02em}
.lede{font-size:18px;color:var(--muted);margin:0 0 20px;max-width:62ch}
h2{font-size:13px;margin:48px 0 14px;text-transform:uppercase;letter-spacing:.06em;
   color:var(--muted);font-weight:650}
h3{font-size:17px;margin:24px 0 6px}
p{margin:0 0 14px;max-width:70ch}
.badges{display:flex;gap:7px;flex-wrap:wrap;margin-bottom:20px}
.badge{font-size:12px;font-weight:650;padding:4px 11px;border-radius:99px;
       background:var(--soft);color:var(--muted);border:1px solid var(--line)}
.badge.on{background:var(--ok-soft);color:var(--ok);border-color:transparent}
table{border-collapse:collapse;width:100%;font-size:14.5px;margin:0 0 14px}
th,td{text-align:left;padding:9px 10px;border-bottom:1px solid var(--line);vertical-align:top}
th{font-size:12px;text-transform:uppercase;letter-spacing:.04em;color:var(--muted)}
code{background:var(--soft);padding:2px 7px;border-radius:5px;font-size:13.5px;
     font-family:ui-monospace,SFMono-Regular,Menlo,monospace;word-break:break-word}
pre{background:var(--soft);border:1px solid var(--line);border-radius:10px;
    padding:13px 15px;overflow-x:auto;margin:0 0 14px}
pre code{background:none;padding:0}
.card{border:1px solid var(--line);border-radius:12px;padding:18px 20px;background:var(--bg)}
.note{background:var(--warn-soft);border:1px solid transparent;border-radius:10px;
      padding:14px 16px;margin:0 0 16px;font-size:14.5px}
.note b{color:var(--warn)}
fieldset{border:1px solid var(--line);border-radius:10px;padding:14px 16px;margin:0 0 14px}
legend{font-size:12px;text-transform:uppercase;letter-spacing:.05em;color:var(--muted);padding:0 6px}
label.q{display:flex;gap:10px;align-items:flex-start;padding:7px 0;font-size:15px;cursor:pointer}
label.q input{margin-top:4px;flex:none}
label.q span small{display:block;color:var(--muted);font-size:13px}
#ergebnis{margin-top:6px}
.verdict{border:1px solid var(--line);border-left:4px solid var(--ac);
         border-radius:10px;padding:16px 18px;background:var(--soft)}
.verdict h3{margin:0 0 6px;font-size:18px}
.verdict .step{font-weight:650;margin:10px 0 0}
.verdict .w{margin-top:12px;padding:11px 13px;background:var(--warn-soft);
            border-radius:8px;font-size:14px}
.probe{display:flex;gap:8px;flex-wrap:wrap;margin-bottom:12px}
.probe input{flex:1 1 240px;padding:10px 12px;border:1px solid var(--line);
             border-radius:9px;background:var(--bg);color:var(--text);font-size:15px}
.btn{font-weight:650;font-size:15px;padding:10px 18px;border-radius:9px;
     border:1px solid var(--ac);background:var(--ac);color:#fff;cursor:pointer}
.btn.ghost{background:var(--bg);color:var(--text);border-color:var(--line)}
footer{margin-top:56px;padding-top:22px;border-top:1px solid var(--line);
       color:var(--muted);font-size:14px}
a{color:var(--ac)}`
	
	err := os.WriteFile(filename, []byte(cssContent), 0644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error writing to file: %v\n", err)
		os.Exit(1)
	}
}
