#!/usr/bin/env pwsh
# telegram-monitor-uebersicht.html — portiert nach powershell
# Quelle: html, Projects@Telegram-Monitor:telegram-monitor-uebersicht.html
# Erzeugt: 2026-08-19 durch ABSTRACTIONS_MANAGER.py

param(
    [Parameter(Mandatory=$true)]
    [string]$OutputPath
)

$htmlContent = @"
<!DOCTYPE html>
<html lang="de">
<head>
<meta charset="utf-8">
<title>Telegram Monitor - Live</title>
<style>
  :root{
    --bg:#ffffff; --soft:#f6f7f9; --line:#e3e6ea; --text:#16191d; --muted:#6b7280;
    --accent:#2481cc; --accent-soft:#e8f2fb; --discord:#5865f2; --discord-soft:#eceefe;
    --ok:#15803d; --ok-soft:#e7f6ec; --err:#b91c1c; --err-soft:#fdeceb;
    --warn:#b45309; --warn-soft:#fdf3e3;
    color-scheme: light;
  }
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);
       font:15px/1.55 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif}
  .wrap{max-width:940px;margin:0 auto;padding:4px 2px 40px}
  h1{font-size:20px;margin:0 0 4px}
  h2{font-size:14px;margin:26px 0 10px;text-transform:uppercase;letter-spacing:.05em;
     color:var(--muted);font-weight:650}
  .sub{color:var(--muted);font-size:13px;margin:0 0 12px}
  .bar{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin:12px 0 6px}
  select,input{font:inherit;border:1px solid var(--line);border-radius:8px;padding:7px 10px;
               background:var(--bg);color:var(--text)}
  button{font:inherit;font-weight:600;border:1px solid var(--line);background:var(--bg);
         color:var(--text);border-radius:8px;padding:7px 13px;cursor:pointer}
  button.primary{background:var(--accent);border-color:var(--accent);color:#fff}
  button:disabled{opacity:.55;cursor:default}
  .live{display:inline-flex;align-items:center;gap:7px;font-size:12.5px;color:var(--muted);
        font-weight:600}
  .dot{width:9px;height:9px;border-radius:50%;background:var(--ok);
       animation:pulse 1.8s infinite}
  .dot.paused{background:var(--muted);animation:none}
  .dot.err{background:var(--err);animation:none}
  @keyframes pulse{0%,100%{opacity:1}50%{opacity:.3}}
  .chips{display:flex;gap:6px;flex-wrap:wrap;margin:8px 0 4px}
  .chip{font-size:11.5px;padding:3px 9px;border-radius:99px;background:var(--ok-soft);
        color:var(--ok);font-weight:650}
  .chip.off{background:var(--soft);color:var(--muted)}
  .chip.mode{background:var(--accent-soft);color:var(--accent)}
  .chip.warn{background:var(--warn-soft);color:var(--warn)}
  .card{border:1px solid var(--line);border-radius:12px;padding:14px 16px;margin-bottom:10px}
  .head{display:flex;gap:11px;align-items:flex-start}
  .avatar{width:38px;height:38px;border-radius:50%;object-fit:cover;background:var(--soft);flex:none}
  .title{font-weight:650;font-size:15px;display:flex;gap:7px;align-items:center;flex-wrap:wrap}
  .meta{color:var(--muted);font-size:12.5px;margin-top:2px}
  .desc{font-size:13.5px;margin-top:7px;white-space:pre-wrap}
  .tag{font-size:11px;padding:2px 7px;border-radius:5px;background:var(--soft);
       color:var(--muted);font-weight:650}
  .tag.tg{background:var(--accent-soft);color:var(--accent)}
  .tag.dc{background:var(--discord-soft);color:var(--discord)}
  .tag.ok{background:var(--ok-soft);color:var(--ok)}
  .tag.no{background:var(--err-soft);color:var(--err)}
  .score{font-variant-numeric:tabular-nums;font-size:11.5px;color:var(--muted);
         border:1px solid var(--line);border-radius:5px;padding:1px 6px}
  .stream{max-height:430px;overflow:auto;border:1px solid var(--line);border-radius:10px;
          padding:4px 12px;margin-top:11px;background:var(--soft)}
  .post{border-left:3px solid var(--accent-soft);padding:6px 0 6px 11px;margin:9px 0;
        background:var(--bg);border-radius:0 6px 6px 0;padding-right:8px}
  .post.fresh{border-left-color:var(--ok);background:#f3fbf5}
  .when{color:var(--muted);font-size:12px}
  .txt{font-size:13.5px;white-space:pre-wrap;margin-top:3px;word-break:break-word}
  .reac{font-size:12px;color:var(--muted);margin-top:4px}
  .new-badge{background:var(--ok);color:#fff;font-size:10.5px;font-weight:700;
             padding:1px 6px;border-radius:4px;margin-left:6px}
  .empty{color:var(--muted);border:1px dashed var(--line);border-radius:10px;
         padding:16px;text-align:center;font-size:13.5px}
  .errbox{background:var(--err-soft);border:1px solid #f5c6c2;color:var(--err);
          padding:9px 12px;border-radius:8px;font-size:13px;margin-top:8px}
  .note{background:var(--soft);border:1px solid var(--line);border-radius:10px;
        padding:12px 14px;font-size:13.5px;color:var(--muted);margin-top:18px}
  .note b{color:var(--text)}
  code{background:var(--soft);padding:1px 5px;border-radius:4px;font-size:12.5px;
       font-family:ui-monospace,SFMono-Regular,Menlo,monospace}
  a{color:var(--accent);text-decoration:none} a:hover{text-decoration:underline}
  details{margin-top:20px;border:1px solid var(--line);border-radius:12px;padding:12px 14px}
  summary{cursor:pointer;font-weight:650;font-size:14px}
</style>
</head>
<body>
<div class="wrap">
  <h1>Telegram Monitor</h1>
  <p class="sub" id="stand"></p>

  <div class="bar">
    <span class="live"><span class="dot" id="dot"></span><span id="liveLabel">bereit</span></span>
    <select id="every">
      <option value="30">alle 30 s</option>
      <option value="60" selected>alle 60 s</option>
      <option value="180">alle 3 min</option>
      <option value="600">alle 10 min</option>
      <option value="0">nur manuell</option>
    </select>
    <button class="primary" id="now">Jetzt abrufen</button>
    <button id="pause">Pause</button>
    <span class="chips" id="modeChips"></span>
  </div>

  <h2>Beobachtete Kanäle</h2>
  <div class="bar" style="margin-top:0">
    <input id="addName" placeholder="@name eines öffentlichen Kanals" style="flex:1;min-width:200px">
    <button id="add">Beobachten</button>
  </div>
  <div id="live"></div>

  <h2>Suchtreffer</h2>
  <p class="sub" id="searchmeta"></p>
  <div id="search"></div>

  <h2>Zugangsmethoden</h2>
  <div class="chips" id="chips"></div>

  <details>
    <summary>Wie die Live-Abfrage funktioniert</summary>
    <p class="sub" style="margin-top:10px">
      Diese Ansicht fragt jeden beobachteten Kanal im eingestellten Turnus selbst ab.
      Zwei Wege, automatisch in dieser Reihenfolge:
    </p>
    <ol class="sub">
      <li><b>Lokales Werkzeug</b> (bevorzugt) — führt <code>cli.py --json live &lt;kanal&gt; --once</code>
        im Projektordner aus. Liefert exakte Zeitstempel, Aufrufzahlen und einen
        dauerhaften Verlauf auf der Festplatte.</li>
      <li><b>Direktabruf der Web-Vorschau</b> — liest <code>t.me/s/&lt;kanal&gt;</code> und wertet
        den Text aus. Funktioniert ohne das lokale Werkzeug, kennt aber nur die
        Uhrzeit, nicht das Datum eines Beitrags.</li>
    </ol>
    <p class="sub">Der gesammelte Verlauf bleibt in dieser Ansicht gespeichert und
      wächst mit jedem Durchlauf. Neue Beiträge werden grün markiert.
      Für Dauerbetrieb im Hintergrund: <code>python server.py --poll-interval 120</code>.</p>
    <div class="bar"><button id="reset">Verlauf in dieser Ansicht löschen</button></div>
  </details>

  <div class="note">
    <b>Reichweite:</b> Öffentliche Kanäle sind vollständig lesbar. Private Nutzerkonten
    liefern nur Name und Bio — dort bleibt der Verlauf leer, das ist eine
    Telegram-Einschränkung. Für nicht-öffentliche Kanäle wird Methode
    <code>mtproto</code> benötigt, für Discord-Nachrichten ein Bot-Token.
  </div>
</div>

<script>
const BAKED = {"generated_at": "2026-07-25T14:59:25+00:00", "search": {"query": "creator", "methods_used": ["web", "discord"], "errors": [], "count": 2, "results": [{"platform": "telegram", "kind": "channel", "id": null, "username": "creator", "title": "✨creator Lounge ✨", "description": "• Aktuelle Livestream-Updates & Ankündigungen 📣\t• Immer up to date: News & Highlights ✨\t• Authentische Einblicke: Behind-the-Scenes nur für meine Community 🎭\t\thttps://linktr.ee/creator\t\tWillkommen im inner Circle von Luisa Amour 👑", "url": "https://t.me/creator", "members": 747, "online": null, "avatar_url": "https://cdn4.telesco.pe/file/h3VNXVClJ7Cj62wfayaWRyeOFgDu-yrttFww8TBdvFCAp-YEm8P88zgFaz16qOBH5GiQc6pIfIMWcPHpsEfwbws1wtURRXdFxGVVIC2up0VKPiOAzRkhsRfN-On9QPzcSVWbiZWFhE2gknW_nSeGD6Prrfch97qNp9Rd27Zj7smgx7xX6kttCNBWps8pDiZGgWefmKi7LQPJNCO52oKNukG6iwOxKVy2fio7KSNTGNR4RGrLRbRiPSeCL0Ey2f51QJ6IiCMeHHoH-K5QS-tv2z0xShRcPkFWHCykIvWTcxWdoiq-sRFdHkelJeTtSkvpYXbMy7JEkULkydl7FJaW7w.jpg", "public": true, "readable": true, "verified": false, "source": "telegram-web", "confidence": 0.8, "fetched_at": "2026-07-25T14:59:25+00:00", "extra": {"page_extra": "747 subscribers", "counters": {"subscribers": 747, "photos": 32, "videos": 6, "links": 22}, "preview_url": "https://t.me/s/creator"}}, {"platform": "telegram", "kind": "user", "id": null, "username": "creator", "title": "Luisa", "description": "Wir alle wollen nur etwas, das bleibt, das länger da ist, als heute 💕", "url": "https://t.me/creator", "members": null, "online": null, "avatar_url": null, "public": false, "readable": false, "verified": false, "source": "telegram-web", "confidence": 0.6, "fetched_at": "2026-07-25T14:59:25+00:00", "extra": {"page_extra": "@creator", "note": "Keine oeffentliche Verlaufs-Vorschau. Entweder privates Nutzerkonto, private Gruppe oder Kanal mit deaktivierter Vorschau."}}]}, "overview": {"entries": [{"platform": "telegram", "target": "creator", "note": "Testkanal", "channel": {"platform": "telegram", "kind": "channel", "id": null, "username": "creator", "title": "✨creator Lounge ✨", "description": "• Aktuelle Livestream-Updates & Ankündigungen 📣\t• Immer up to date: News & Highlights ✨\t• Authentische Einblicke: Behind-the-Scenes nur für meine Community 🎭\t\thttps://linktr.ee/creator\t\tWillkommen im inner Circle von Luisa Amour 👑", "url": "https://t.me/creator", "members": 747, "online": null, "avatar_url": "https://cdn4.telesco.pe/file/h3VNXVClJ7Cj62wfayaWRyeOFgDu-yrttFww8TBdvFCAp-YEm8P88zgFaz16qOBH5GiQc6pIfIMWcPHpsEfwbws1wtURRXdFxGVVIC2up0VKPiOAzRkhsRfN-On9QPzcSVWbiZWFhE2gknW_nSeGD6Prrfch97qNp9Rd27Zj7smgx7xX6kttCNBWps8pDiZGgWefmKi7LQPJNCO52oKNukG6iwOxKVy2fio7KSNTGNR4RGrLRbRiPSeCL0Ey2f51QJ6IiCMeHHoH-K5QS-tv2z0xShRcPkFWHCykIvWTcxWdoiq-sRFdHkelJeTtSkvpYXbMy7JEkULkydl7FJaW7w.jpg", "public": true, "readable": true, "verified": false, "source": "telegram-web", "confidence": 1.0, "fetched_at": "2026-07-25T14:59:29+00:00", "extra": {"page_extra": "747 subscribers", "counters": {"subscribers": 747, "photos": 32, "videos": 6, "links": 22}, "preview_url": "https://t.me/s/creator"}}, "posts": [{"platform": "telegram", "channel": "creator", "id": "creator/280", "url": "https://t.me/creator/280", "date": "2025-09-26T16:12:52+00:00", "author": "", "text": "https://vm.tiktok.com/ZNHWA5cEHWgjN-TVDmY", "views": 1670, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/279", "url": "https://t.me/creator/279", "date": "2025-09-26T07:31:05+00:00", "author": "", "text": "Guten Morgen. ☀️ Wir sind auf WhatsApp bereits über 1k Follower. Daher machen wir diesen Channel am Sonntag zu. Alle nochmal rüber wechseln zu WhatsApp. Der Channel ist ebenfalls anonym.. keine Nummern, keine Namen, 100% kostenlos. \n\nRein da: 👉🏼 \n\nhttps://whatsapp.com/channel/0029VbB68PU8KMqeo5pYLB0H", "views": 1720, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/278", "url": "https://t.me/creator/278", "date": "2025-09-25T07:42:50+00:00", "author": "", "text": "https://vm.tiktok.com/ZNHWM5ng8X1ss-QC6hZ", "views": 1390, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/277", "url": "https://t.me/creator/277", "date": "2025-09-24T18:08:00+00:00", "author": "", "text": "ALLE REIN IN DEN WHATSAPP CHANNEL ODER ICH BLOCKE EUCH AUF TIKOTK 🤣 https://whatsapp.com/channel/0029VbB68PU8KMqeo5pYLB0H", "views": 1270, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/276", "url": "https://t.me/creator/276", "date": "2025-09-24T14:46:29+00:00", "author": "", "text": "https://vm.tiktok.com/ZNHW2SGKbTgoH-jefyG", "views": 965, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/275", "url": "https://t.me/creator/275", "date": "2025-09-24T12:45:48+00:00", "author": "", "text": "Geht alle in den WhatsApp Kanal! Der ist genau so anonym wie telegram. 🥰\n\nNach nem verpackten Ranglisten Start heute Nacht hatten wir echt einen mega Stream heute Mittag ihr lieben. Chillen einfach wieder in der top 20. 😎 \n\nWir sehen uns ca. 16:30 Uhr wieder. Erholt euch erstmal von den Chaoten 😂 \n\nBis gleich 🤍", "views": 868, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/274", "url": "https://t.me/creator/274", "date": "2025-09-24T11:21:04+00:00", "author": "", "text": "Alle rein da in den Chanel! 😎", "views": 793, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/273", "url": "https://t.me/creator/273", "date": "2025-09-24T11:13:01+00:00", "author": "", "text": "https://whatsapp.com/channel/0029VbB68PU8KMqeo5pYLB0H", "views": 824, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/272", "url": "https://t.me/creator/272", "date": "2025-09-24T11:12:58+00:00", "author": "", "text": "Eyyyy hab voll viele Nachrichten bekommen, dass ihr lieber den Kanal auf WhatsApp hättet .. hab jetzt einen erstellt, wenn wir da schneller auf 1k Mitglieder sind. Gehen wir zu WhatsApp! Ansonsten bleiben wir hier", "views": 797, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/271", "url": "https://t.me/creator/271", "date": "2025-09-24T08:33:10+00:00", "author": "", "text": "", "views": 792, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:37:52+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/270", "url": "https://t.me/creator/270", "date": "2025-09-24T07:50:58+00:00", "author": "", "text": "https://vm.tiktok.com/ZNHWYdPSoVABF-1lZd3", "views": 742, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/269", "url": "https://t.me/creator/269", "date": "2025-09-23T21:35:49+00:00", "author": "", "text": "https://vm.tiktok.com/ZNHWNYBQ6dGjH-fiplg", "views": 713, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/268", "url": "https://t.me/creator/268", "date": "2025-09-23T20:53:02+00:00", "author": "", "text": "😎😎😎", "views": 750, "media": [{"type": "photo", "url": "https://cdn4.telesco.pe/file/sa5ZEPwOGR5ZUkhz3gjvwZS1jPsrl3epC8L_6ND1-tHRhoFW33W8Bt6dU3p2bKue6IvBYoXtNq2rSwC9lJ9Al3eorbvfb8NtwLAlLvehGqItaLpGlZZ8HmURHqOd-p6m6O5id_Sh0Ugc3M14Cof4dZrCVc_oUZT-WMwN-VyOXsuUVRhGCzodkZXJhb6U6ojcxE9-TAG8SsGfWZ6PB3EwN9WFHSsfs_Qx6Czl5ZuadrR6lF7RWySEq_dN3mKFOr0EonYs3E1m8OEGhsm2Zy5w9BFlH0pBu-wh7IcuQ_2vgv8WCPPPUUaaUSZF75XARC9ooypSiLUD2rKhGWgnZoD7xA.jpg"}], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/267", "url": "https://t.me/creator/267", "date": "2025-09-23T19:53:03+00:00", "author": "", "text": "Mega starker Abend Stream ihr Lieben🙏🏼 krass, wie wir als Team zusammen gehalten haben und Cesur am Ende offline geschickt haben 😎 \nDanke an jeden einzelnen 🥰 aktuell sind wir auf top 5 und ich bin mir sicher, dass wir heute sogar in der Top 10 abschließen werden. 🥰 Weil ihr einfach krass seid.\n\nWir sind heute Abend gegen 23:30 Uhr wieder am Start und kämpfen uns in die neue Rangliste in einer geilen 4er konstellation 😎 \n\nGenießt den Abend und bis später 🤍", "views": 778, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/265", "url": "https://t.me/creator/265", "date": "2025-09-23T12:19:07+00:00", "author": "", "text": "", "views": 783, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/264", "url": "https://t.me/creator/264", "date": "2025-09-23T12:16:52+00:00", "author": "", "text": "Heute.. der Untergang des Dr.Markus. 🧘🏼‍♀️ die Genugtuung meines Lebens das kleine blondiere Hühnchen schlafen gelegt gu haben 😌", "views": 795, "media": [{"type": "video", "url": "https://cdn4.telesco.pe/file/179047640b.mp4?token=qY2cvk46odtiKkdZf1a6zimWXhjjsboA99_Xw1_8FJJZcLtpmSxWUiN0mEAlGRA47eJ3_tJibiAOSb_7kZdOOjhpkleIjVKXa2_Ffk-IrNve1x710_EyfiMxjyNFwf2IUbuK8ov-eDbAjPwNzR7GMR-J8nS7bWa5bfpDcTYcJHDtdIR1dYyEKcZohy_LbutEgpixrEnwazGqcuB1gsvRvIwQ_l_IxW2Y_ss-OTCg2PqI6013PDdCMCcOAzSedqzU9TzSIHmIfTEMlRjT8mgLG6mhEpQ8CYraeTvY5YdEA_8gsOp6fRaNW4Uxh8IWdOjRmhFWfeKE5TQsDc-126oehLOGDC7dCGZwcKfb4h-WtxpU8Fhz8X6YDKiNIr9IdBABzuZ8R2oCf2bDO5Kk-UcToK2EMb_g5h0UNQJ3tFBCYLikJh4cOXNFC3SKmKBuJmwkA8spov0mA492hzEurUy4TGBMg9xUF7jXBN-RZVhLlCt0Rq8EzU6dSYGOcuuz3PTTJvpsS6_0X90icnJYAu2b0SgZE18OpHP5z_plR9fX3jNXzeLqmchrk36WxFDXQiPo4U6kmecVEjYGo4Oks_rmIugt_ahK9hw-zdG1Y-hM4stijrDpgt9hPoO5_gh8QlKi3cIvGJuVsJbcIamcLTD4Adw6znLNU6qGwNIX1RCias0"}, {"type": "video", "url": "https://cdn4.telesco.pe/file/179047640b.mp4?token=qY2cvk46odtiKkdZf1a6zimWXhjjsboA99_Xw1_8FJJZcLtpmSxWUiN0mEAlGRA47eJ3_tJibiAOSb_7kZdOOjhpkleIjVKXa2_Ffk-IrNve1x710_EyfiMxjyNFwf2IUbuK8ov-eDbAjPwNzR7GMR-J8nS7bWa5bfpDcTYcJHDtdIR1dYyEKcZohy_LbutEgpixrEnwazGqcuB1gsvRvIwQ_l_IxW2Y_ss-OTCg2PqI6013PDdCMCcOAzSedqzU9TzSIHmIfTEMlRjT8mgLG6mhEpQ8CYraeTvY5YdEA_8gsOp6fRaNW4Uxh8IWdOjRmhFWfeKE5TQsDc-126oehLOGDC7dCGZwcKfb4h-WtxpU8Fhz8X6YDKiNIr9IdBABzuZ8R2oCf2bDO5Kk-UcToK2EMb_g5h0UNQJ3tFBCYLikJh4cOXNFC3SKmKBuJmwkA8spov0mA492hzEurUy4TGBMg9xUF7jXBN-RZVhLlCt0Rq8EzU6dSYGOcuuz3PTTJvpsS6_0X90icnJYAu2b0SgZE18OpHP5z_plR9fX3jNXzeLqmchrk36WxFDXQiPo4U6kmecVEjYGo4Oks_rmIugt_ahK9hw-zdG1Y-hM4stijrDpgt9hPoO5_gh8QlKi3cIvGJuVsJbcIamcLTD4Adw6znLNU6qGwNIX1RCias0"}], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/263", "url": "https://t.me/creator/263", "date": "2025-09-23T10:20:52+00:00", "author": "", "text": "", "views": 710, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/262", "url": "https://t.me/creator/262", "date": "2025-09-23T08:01:09+00:00", "author": "", "text": "Alle rein da! Gleich die Konstellation, auf die ihr 5 Tage gewartet habt 😎💥", "views": 708, "media": [{"type": "photo", "url": "https://cdn4.telesco.pe/file/g4lCVuXoqlf8i8aHZxzP9OLRT6G8zh057z2W2pWkBggk46nyqPUVyw-LpZI5ZUdNlwFJzq0NX_fE46D2U3-4dad_LJPtKKuB_XkmsQenK-0mRKHpOycgqSFW7Iu9dzS9fAgw-7L22dmaIyhRrkuD5sc-9zVFoEFL3_N2_avqdHw8uicIPJuZUalqt33BlZPrX_nMc47o8sKl5-gtILy8ugZ2y6vLhN-Z_Az3ju9Npd002stBi8hXYP6Z12TYnI94lpZC0e_K6uTltUlW00zOj5oBbUIpGG7iD8JVLCNa9UxCZhAGmXznH0K6MSiCHV3dnHKaM-APizQvOIiAOc63ng.jpg"}], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/260", "url": "https://t.me/creator/260", "date": "2025-09-23T00:15:15+00:00", "author": "", "text": "", "views": 686, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/259", "url": "https://t.me/creator/259", "date": "2025-09-23T00:11:20+00:00", "author": "", "text": "Leute, ich kann gar nicht in Worte fassen, wie unfassbar stolz ich gerade auf das ganze Team bin! 🙏🏼🤍 \n\nUnfassbar starker Ranglistenstart, starkes Teamwork, starker Zusammenhalt! Cesur und Nik schlagen gelegt.. 😎 und jeder weiß, dass wir auch die letzte Runde eigentlich gewonnen haben. Guckt man sich die beliebte Liste an sieht man tagtäglich eindeutig, wer wirklich ein Team hat. \n\nGenau so muss ein Rangliste Start von Team Luisa aussehen. Danke von ganzem Herzen an jeden einzelnen, der mitgeholfen hat. Danke danke danke 🙏🏼 \n\nBin morgen früh gegen 10:00 Uhr live 🙏 habt alle eine wundervolle gute Nacht. Schöne Träume und bis morgen bestes Team. 🥰", "views": 679, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/257", "url": "https://t.me/creator/257", "date": "2025-09-22T19:12:16+00:00", "author": "", "text": "Jooooo was ein krasser Comeback nach einer kurzen Auszeit. Einmal über die ganze Rangliste gelaufen 😎 Danke an jeden einzelnen für diesen geisteskranken Empfang. 🥰\n\nHeute 23.30 der nächste Knall. 4er Matches zum Ranglistenstart. Der erste nach der Pause 😎 bin hyped und ready die Rangliste auf den Kopf zu stellen. \n\nUND ICH SAGE EUCH.. die Konstellation um 0 Uhr wird wieder mal für massig Gesprächsstoff sorgen 🤭 \n\nAb 23.30 sind wir ca live. Zum Ranglisten Start brauchen wir echt jeeeeeden der irgendwie am Start sein kann. Wir müssen das etablieren.. 0 Uhr ist der wichtigste Stream von allen 🙏🏼 \n\nBis gleeeeeeich ihr kings und Queens. 🤍 Ich knutsch euch 😘", "views": 678, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/255", "url": "https://t.me/creator/255", "date": "2025-09-22T14:01:54+00:00", "author": "", "text": "Bin ready 😎 knapp 5 Tage Pause reichen dann halt auch einfach aus. \n\nKomme 16:45 Uhr live und dann showtime. Lasst uns die Rangliste mal wieder aufräumen und zeigen, wer hier die wahre Champions League ist. \n\nHeute knallts auf jeden Fall aus allen Löchern 💥 \n\nHoffe ihr habt mich vermisst 😎", "views": 710, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/254", "url": "https://t.me/creator/254", "date": "2025-09-21T17:50:00+00:00", "author": "", "text": "", "views": 753, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/252", "url": "https://t.me/creator/252", "date": "2025-09-21T17:45:53+00:00", "author": "", "text": "Es knallt! 💥 wer das verpasst ist dann halt auch einfach selber schuld.", "views": 732, "media": [{"type": "photo", "url": "https://cdn4.telesco.pe/file/X373WNnFdSFHAAtXKDCygdxX6kHDrYsLQ8P_ySoXvcQLelsyBteCmfC-SV28vDqa1DDNvAuupSuru1ek9L3StSMGRRL5eod4TqEZxZLjt5mLPqEo1PU9Jf-VUo7kXGvpVqy8j-6YZpksj0EW1M3oPYi-K1l3j9lBXiCtK0PhcN3xwbblSABVUbSzyy-wJqcIIaZBdPBQIpDc48rXISwzrrjkBjQ7K4ymX0lV4qiCmZtCa-6nP7XPlKp6HBaXOBg3GVw3zmVrxigrcS8EhI1dasKXX81EZXk18la1rwINetYVznholjclpqu2fv2vRoqs6aaEt9cResCjLCwu6Ecohg.jpg"}], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}, {"platform": "telegram", "channel": "creator", "id": "creator/251", "url": "https://t.me/creator/251", "date": "2025-09-21T09:34:51+00:00", "author": "", "text": "", "views": 766, "media": [], "source": "telegram-web", "extra": {}, "seen_at": "2026-07-25T14:38:45+00:00"}]}, {"platform": "telegram", "target": "creator", "note": "Privates Profil", "channel": {"platform": "telegram", "kind": "user", "id": null, "username": "creator", "title": "Luisa", "description": "Wir alle wollen nur etwas, das bleibt, das länger da ist, als heute 💕", "url": "https://t.me/creator", "members": null, "online": null, "avatar_url": null, "public": false, "readable": false, "verified": false, "source": "telegram-web", "confidence": 1.0, "fetched_at": "2026-07-25T14:59:30+00:00", "extra": {"page_extra": "@creator", "note": "Keine oeffentliche Verlaufs-Vorschau. Entweder privates Nutzerkonto, private Gruppe oder Kanal mit deaktivierter Vorschau."}}, "posts": []}]}, "methods": [{"name": "telegram-web", "platform": "telegram", "available": true, "reason": "Immer verfuegbar - benoetigt keinerlei Zugangsdaten.", "capabilities": ["resolve", "posts", "candidate-search", "web-discovery"]}, {"name": "telegram-bot", "platform": "telegram", "available": false, "reason": "Kein Bot-Token. Setze TELEGRAM_BOT_TOKEN oder telegram.bot_token in config.json.", "capabilities": []}, {"name": "telegram-mtproto", "platform": "telegram", "available": false, "reason": "Telethon fehlt - 'pip install telethon'.", "capabilities": []}, {"name": "discord-bot", "platform": "discord", "available": false, "reason": "Kein Bot-Token - Invite-Lookup funktioniert trotzdem.", "capabilities": ["invite-lookup"]}]};
const esc = s => String(s ?? '').replace(/[&<>"]/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;'}[c]));
const num = n => n == null ? '?' : Number(n).toLocaleString('de-DE');
const nowIso = () => new Date().toISOString();
function when(d){
  if(!d) return '';
  const t = new Date(d);
  return isNaN(t) ? String(d) : t.toLocaleString('de-DE',{dateStyle:'medium',timeStyle:'short'});
}

/* ------------------------------------------------------------ Zustand --- */
const LS = 'tgmon.live.v1';
function loadState(){
  try{ const s = localStorage.getItem(LS); if(s) return JSON.parse(s); }catch(e){}
  const channels = ((BAKED.overview && BAKED.overview.entries) || [])
    .map(e => ({platform: e.platform || 'telegram', target: e.target,
                channel: e.channel || null,
                posts: sortPosts((e.posts || []).map(p => Object.assign({}, p, {seen_at: null}))),
                last_poll: null, polls: 0, error: null}));
  return {channels, mode: null, updated: BAKED.generated_at || null};
}
let ST = loadState();
const save = () => { try{ localStorage.setItem(LS, JSON.stringify(ST)); }catch(e){} };

/* ---------------------------------------------------------- Sortierung --- */
// Telegram vergibt fortlaufende Beitragsnummern - sie sind das verlaesslichste
// Ordnungsmerkmal, weil der eingebettete Datenstand und der Live-Abruf sonst
// unterschiedliche Angaben liefern (mal Datum, mal nur Uhrzeit).
function postNo(p){
  if(p.no != null) return Number(p.no);
  const m = String(p.id || '').match(/[\/#](\d+)(?:-|$)/);
  return m ? parseInt(m[1], 10) : null;
}
function sortPosts(list){
  return list.slice().sort((a, b) => {
    const na = postNo(a), nb = postNo(b);
    if(na != null && nb != null && na !== nb) return nb - na;      // neueste zuerst
    const da = a.date ? Date.parse(a.date) : NaN;
    const db = b.date ? Date.parse(b.date) : NaN;
    if(!isNaN(da) && !isNaN(db) && da !== db) return db - da;
    const sa = a.seen_at ? Date.parse(a.seen_at) : 0;
    const sb = b.seen_at ? Date.parse(b.seen_at) : 0;
    return sb - sa;
  });
}

/* ------------------------------------------------------- Werkzeugaufruf --- */
const TAVILY = 'mcp__0ed159c9-d255-4173-8de6-52405fa59915__tavily_extract';
function txt(r){
  if(!r) return '';
  if(typeof r === 'string') return r;
  if(r.content && r.content.length) return r.content.map(c => c.text || '').join('\n');
  return r.error ? String(r.error) : '';
}
async function callTool(name, args){
  if(!window.cowork || typeof window.cowork.callMcpTool !== 'function'){
    throw new Error('Diese Ansicht kann hier keine Werkzeuge aufrufen - ' +
      'bitte im Cowork-Fenster oeffnen oder das lokale Werkzeug nutzen.');
  }
  return await window.cowork.callMcpTool(name, args);
}

/* ------------------------------------------------- Weg 1: lokales Tool --- */
async function viaBash(target){
  // Projektordner selbst finden - egal ob er im Projektverzeichnis oder im
  // Ausgabeordner liegt. Erkennungsmerkmal: das Paket tgmon/ neben cli.py.
  const cmd = 'p=$(ls -d /sessions/*/mnt/*/tgmon /sessions/*/mnt/*/*/tgmon 2>/dev/null | head -1); ' +
    'p=${p%/tgmon}; cd "$p" && python3 cli.py --json live ' +
    JSON.stringify(target) + ' --once --limit 25';
  const r = await callTool('mcp__workspace__bash', {command: cmd});
  if(r.isError) throw new Error('lokales Werkzeug: ' + txt(r));
  const raw = txt(r) || (r.structuredContent ? JSON.stringify(r.structuredContent) : '');
  const a = raw.indexOf('{'), b = raw.lastIndexOf('}');
  if(a < 0 || b < a) throw new Error('lokales Werkzeug: keine JSON-Antwort');
  const data = JSON.parse(raw.slice(a, b + 1));
  const entry = (data.entries || [])[0];
  if(!entry) throw new Error('lokales Werkzeug: leere Antwort');
  return {posts: entry.posts || [], exact: true, total: entry.total};
}

/* ------------------------------------------- Weg 2: Web-Vorschau lesen --- */
function parsePreview(md, target){
  // Beitragsende erkennen: "679 views", "120 voters686 views",
  // optional gefolgt von "[00:11](https://t.me/kanal/259)" (anderes Abrufformat).
  const term = /(?:([\d.,]+[KM]?)\s*voters)?\s*([\d.,]+[KM]?)\s*views(?:\s*\[(\d{1,2}:\d{2})\]\(https:\/\/t\.me\/[A-Za-z0-9_]+\/(\d+)\))?/g;
  const linkRe = new RegExp('https://t\\.me/(' + target.replace(/[^A-Za-z0-9_]/g, '') + ')/(\\d+)', 'g');
  const out = [];
  let prev = 0, m, idx = 0;
  while((m = term.exec(md)) !== null){
    const block = md.slice(prev, m.index);
    prev = term.lastIndex;
    if(!block.trim()) continue;
    const parsed = cleanBlock(block);

    // Beitragsnummer: entweder aus dem Zeitstempel-Link oder aus einem
    // t.me-Link im Block; sonst ersatzweise aus dem Textinhalt.
    let postNo = m[4] || null;
    if(!postNo){
      let l, last = null;
      linkRe.lastIndex = 0;
      while((l = linkRe.exec(block)) !== null) last = l[2];
      postNo = last;
    }
    const id = postNo ? target + '/' + postNo : target + '#' + hash(parsed.text + (parsed.reactions || '') + idx);
    out.push({
      platform: 'telegram', channel: target, id: id,
      url: postNo ? 'https://t.me/' + target + '/' + postNo : '',
      date: null, time: m[3] || null, no: postNo ? parseInt(postNo, 10) : null,
      text: parsed.text,
      views: parseCount(m[2]), voters: m[1] ? parseCount(m[1]) : null,
      reactions: parsed.reactions, media: parsed.media, source: 'web-vorschau'
    });
    idx++;
  }
  // Manche Beitraege haben keinen eigenen Link in der Vorschau. Telegrams
  // Nummerierung hat Luecken, also wird NICHT geraten - stattdessen ein
  // stabiler Schluessel aus letzter bekannter Nummer + Textkennung. Er dient
  // nur der Wiedererkennung; es wird kein falscher Link erzeugt.
  let anchor = 0;
  for(const post of out){
    if(post.no != null){ anchor = post.no; continue; }
    post.id = target + '#' + anchor + '-' + hash(post.text + (post.reactions || ''));
    post.no = anchor + 0.5;                       // Sortierung: direkt nach dem Anker
    post.no_exact = false;
    post.url = 'https://t.me/s/' + target;        // wenigstens die Kanalvorschau
  }

  // Der Kanalname steht in jedem Block als erste Zeile - einmal ermitteln, ueberall entfernen.
  const firsts = {};
  out.forEach(p => { const f = (p.text || '').split('\n')[0]; if(f) firsts[f] = (firsts[f] || 0) + 1; });
  const top = Object.entries(firsts).sort((a, b) => b[1] - a[1])[0];
  if(top && top[1] >= Math.max(2, out.length * 0.6)){
    out.forEach(p => {
      const lines = (p.text || '').split('\n');
      while(lines.length && lines[0] === top[0]) lines.shift();   // ggf. mehrfach
      p.text = lines.join('\n').trim();
      p.channel_title = top[0];
    });
  }
  return out;
}
function hash(str){
  let h = 5381;
  for(let i = 0; i < str.length; i++) h = ((h << 5) + h + str.charCodeAt(i)) | 0;
  return Math.abs(h).toString(36);
}
function parseCount(v){
  if(!v) return null;
  const s = String(v).replace(/\s/g,'');
  const mult = /K$/i.test(s) ? 1000 : (/M$/i.test(s) ? 1000000 : 1);
  const n = parseFloat(s.replace(/[KM]/ig,'').replace(/\./g, mult>1 ? '.' : '').replace(/,/g,'.'));
  return isNaN(n) ? null : Math.round(n * mult);
}
function cleanBlock(raw){
  let t = raw, media = [];
  if(/telesco\.pe\/file\/[^\s)]*\.mp4/.test(t)) media.push('video');
  if(/telesco\.pe\/file\/[^\s)]*\.jpg/.test(t)) media.push('bild');
  t = t.replace(/\[\*!\[\]\([^)]*\)\*\]\([^)]*\)/g, ' ');
  t = t.replace(/\*!\[\]\([^)]*\)\*/g, ' ').replace(/!\[\]\([^)]*\)/g, ' ');
  for(let i = 0; i < 4; i++){
    t = t.replace(/\[([^\[\]]*)\]\((?:[^()]|\([^()]*\))*\)/g, '$1');
  }
  t = t.replace(/<(https?:\/\/[^>]+)>/g, '$1');
  t = t.replace(/https:\/\/cdn\d+\.telesco\.pe\/\S+/g, ' ');
  t = t.replace(/\*{1,3}/g, '');
  t = t.replace(/Please open Telegram to view this post/g, ' ');
  t = t.replace(/VIEW IN TELEGRAM/g, ' ');
  t = t.replace(/This media is not supported in your browser/g, ' ');
  t = t.replace(/Download Telegram|Join\b/g, ' ');
  t = t.split('\n').map(l => l.trim()).filter(l =>
        l.length &&
        !/^\d{1,2}:\d{2}$/.test(l) &&                                   // Videodauer
        !/^[\d.,]+[KM]?\s+(subscribers|members|photos|videos|links|files|abonnenten)$/i.test(l) &&
        !/^(join|download telegram|telegram)$/i.test(l)                  // Seitenkopf
      ).join('\n');

  // Reaktionsleiste am Ende abtrennen (z. B. "❤36🔥3😴2")
  let reactions = '';
  const lines = t.split('\n');
  while(lines.length){
    const last = lines[lines.length - 1];
    if(/^(?:[^\w\s]{1,6}\s?[\d.,]+K?)+$/u.test(last)){ reactions = lines.pop() + ' ' + reactions; }
    else break;
  }
  t = lines.join('\n').replace(/\n{3,}/g, '\n\n').trim();
  return {text: t, reactions: reactions.trim(), media: media.map(x => ({type: x}))};
}
async function viaTavily(target){
  // Ein Aufruf liefert Text, Beitragslinks, Aufrufe und Reaktionen.
  // Der angehaengte Parameter umgeht den Zwischenspeicher des Dienstes.
  const url = 'https://t.me/s/' + encodeURIComponent(target) + '?_=' + Date.now();
  const r = await callTool(TAVILY, {urls: [url], extract_depth: 'advanced', format: 'markdown'});
  if(r.isError) throw new Error('Textabruf: ' + txt(r));
  let data = r.structuredContent;
  if(!data){
    const raw = txt(r);
    const a = raw.indexOf('{'), b = raw.lastIndexOf('}');
    if(a < 0) throw new Error('Textabruf: keine verwertbare Antwort');
    data = JSON.parse(raw.slice(a, b + 1));
  }
  const res = (data.results || [])[0];
  if(!res || !res.raw_content) throw new Error('Textabruf: leeres Ergebnis');
  let posts = parsePreview(res.raw_content, target);
  posts.sort((a, b) => (a.no || 0) - (b.no || 0));
  posts = posts.reverse();                                        // neueste zuerst
  if(!posts.length) throw new Error('Textabruf: keine Beitraege erkannt');
  return {posts, exact: false, total: posts.length};
}

async function viaFetch(target){
  const base = 'https://t.me/s/' + encodeURIComponent(target);
  // Erst mit Cache-Umgehung, sonst schlicht - je nach Umgebung ist nur eine Form erlaubt.
  let r = null, err = '';
  for(const url of [base + '?_=' + Date.now(), base]){
    try{
      r = await callTool('mcp__workspace__web_fetch', {url});
      if(!r.isError) break;
      err = txt(r); r = null;
    }catch(e){ err = e.message; r = null; }
  }
  if(!r) throw new Error('Web-Vorschau: ' + (err || 'Abruf fehlgeschlagen'));
  const md = txt(r);
  if(!/t\.me\//.test(md)) throw new Error('Web-Vorschau: unerwartete Antwort');
  const posts = parsePreview(md, target).reverse();          // neueste zuerst
  return {posts, exact: false, total: posts.length};
}

/* --------------------------------------------------------- Abruflogik --- */
let mode = null, busy = false;

async function pollOne(ch){
  // Private Nutzerkonten haben keine oeffentliche Vorschau - Abruf waere
  // garantiert erfolglos und wuerde nur eine Fehlermeldung erzeugen.
  if(ch.channel && ch.channel.readable === false){
    ch.last_poll = nowIso();
    ch.polls = (ch.polls || 0) + 1;
    ch.error = null;
    ch.skipped = 'Privates Konto ohne oeffentlichen Verlauf - nichts abzurufen.';
    return 0;
  }
  let res, errs = [];
  const order = mode === 'lokal' ? [viaBash, viaTavily, viaFetch]
                                : [viaTavily, viaBash, viaFetch];
  for(const fn of order){
    try{ res = await fn(ch.target); mode = (fn === viaBash) ? 'lokal' : 'web'; errs = []; break; }
    catch(e){ errs.push(e.message); }
  }
  ch.last_poll = nowIso();
  ch.polls = (ch.polls || 0) + 1;
  ch.error = res ? null : errs.join(' · ');
  if(!res) return 0;

  // Zwei Erkennungsmerkmale: Beitrags-ID und Textkennung. Der eingebettete
  // Datenstand nutzt echte IDs, der Live-Abruf teils Ersatzschluessel - ohne
  // Textvergleich stuende derselbe Beitrag sonst doppelt in der Liste.
  const known = new Set();
  (ch.posts || []).forEach(p => {
    known.add(p.id);
    known.add('t:' + hash((p.text || '').slice(0, 140).replace(/\s+/g, ' ').trim()));
  });
  const fresh = res.posts.filter(p =>
    !known.has(p.id) &&
    !known.has('t:' + hash((p.text || '').slice(0, 140).replace(/\s+/g, ' ').trim())));
  fresh.forEach(p => { p.seen_at = nowIso(); p.is_new = true; });
  (ch.posts || []).forEach(p => { p.is_new = false; });
  ch.posts = sortPosts(fresh.concat(ch.posts || [])).slice(0, 300);
  ch.exact = res.exact;
  if(fresh.length) ch.last_new = nowIso();
  return fresh.length;
}

async function pollAll(){
  if(busy) return;
  busy = true;
  setLive('rufe ab ...', 'busy');
  let total = 0;
  for(const ch of ST.channels){
    try{ total += await pollOne(ch); }catch(e){ ch.error = e.message; }
    render();
  }
  ST.updated = nowIso();
  save(); render();
  busy = false;
  setLive(total ? total + ' neue(r) Beitrag/Beiträge' : 'aktuell', total ? 'new' : 'ok');
  return total;
}

/* ------------------------------------------------------------ Anzeige --- */
function setLive(text, kind){
  document.getElementById('liveLabel').textContent = text;
  const dot = document.getElementById('dot');
  dot.className = 'dot' + (kind === 'paused' ? ' paused' : (kind === 'err' ? ' err' : ''));
}
function postHtml(p, exact){
  const stamp = p.date ? when(p.date)
    : (p.time ? p.time + ' Uhr (Datum unbekannt)'
             : (p.no_exact === false ? 'aus der Kanalvorschau'
                                     : (p.no ? 'Beitrag ' + p.no : '')));
  return '<div class="post' + (p.is_new ? ' fresh' : '') + '">' +
    '<div class="when">' + esc(stamp) +
      (p.is_new ? '<span class="new-badge">NEU</span>' : '') +
      (p.views ? ' · ' + num(p.views) + ' Aufrufe' : '') +
      (p.voters ? ' · ' + num(p.voters) + ' Stimmen' : '') +
      (p.author ? ' · ' + esc(p.author) : '') +
      (p.url ? ' · <a href="' + esc(p.url) + '" target="_blank" rel="noopener">' +
        (p.no_exact === false ? 'Kanal öffnen' : 'Beitrag') + '</a>' : '') +
    '</div>' +
    '<div class="txt">' + esc((p.text || '(kein Text)').slice(0, 900)) + '</div>' +
    (p.reactions ? '<div class="reac">' + esc(p.reactions) + '</div>' : '') +
    (p.media && p.media.length ? '<div class="reac">Medien: ' +
      esc(p.media.map(m => m.type).join(', ')) + '</div>' : '') +
    '</div>';
}
function channelHtml(ch){
  const c = ch.channel || {};
  const av = c.avatar_url ? '<img class="avatar" src="' + esc(c.avatar_url) + '" alt="">'
                          : '<div class="avatar"></div>';
  const tags = ['<span class="tag ' + (ch.platform === 'discord' ? 'dc' : 'tg') + '">' +
                esc(ch.platform) + '</span>'];
  if(c.kind) tags.push('<span class="tag">' + esc(c.kind) + '</span>');
  tags.push(c.readable === false ? '<span class="tag no">nicht lesbar</span>'
                                 : '<span class="tag ok">lesbar</span>');
  const posts = sortPosts(ch.posts || []);
  return '<div class="card"><div class="head">' + av + '<div style="flex:1;min-width:0">' +
    '<div class="title">' + esc(c.title || ch.target) + tags.join('') +
      '<button data-drop="' + esc(ch.target) + '" style="margin-left:auto;padding:3px 9px;font-size:12px">entfernen</button>' +
    '</div>' +
    '<div class="meta">@' + esc(ch.target) +
      (c.members ? ' · ' + num(c.members) + ' Abonnenten' : '') +
      ' · ' + posts.length + ' Beiträge gesammelt · ' + (ch.polls || 0) + ' Abrufe' +
      (ch.last_poll ? ' · zuletzt geprüft ' + esc(when(ch.last_poll)) : '') +
      (ch.last_new ? ' · Neues zuletzt ' + esc(when(ch.last_new)) : '') + '</div>' +
    (c.description ? '<div class="desc">' + esc(c.description.slice(0, 260)) + '</div>' : '') +
    (ch.error ? '<div class="errbox">' + esc(ch.error) + '</div>' : '') +
    (posts.length
      ? '<div class="stream">' + posts.map(p => postHtml(p, ch.exact)).join('') + '</div>'
      : '<div class="empty" style="margin-top:10px">' + esc(ch.skipped ||
          'Noch keine Beiträge gesammelt — entweder keine öffentliche Vorschau ' +
          'oder der Kanal hat nichts veröffentlicht.') + '</div>') +
    '</div></div></div>';
}
function render(){
  document.getElementById('stand').textContent =
    'Letzte Aktualisierung: ' + (ST.updated ? when(ST.updated) : 'noch keine') +
    ' · neueste Beiträge oben · Verlauf wird in dieser Ansicht gesammelt';

  document.getElementById('live').innerHTML = ST.channels.length
    ? ST.channels.map(channelHtml).join('')
    : '<div class="empty">Kein Kanal beobachtet — oben einen @namen eintragen.</div>';

  document.getElementById('modeChips').innerHTML =
    (mode ? '<span class="chip mode">Quelle: ' +
      (mode === 'lokal' ? 'lokales Werkzeug (exakte Zeitstempel)'
                        : 'Web-Vorschau (nur Uhrzeit)') + '</span>' : '');

  const s = BAKED.search || {};
  document.getElementById('searchmeta').textContent = s.query
    ? 'Suchbegriff "' + s.query + '" · ' + (s.count || 0) + ' Treffer · Methoden: ' +
      ((s.methods_used || []).join(', ') || '-')
    : '';
  document.getElementById('search').innerHTML = (s.results || []).length
    ? s.results.map(c => '<div class="card"><div class="head">' +
        (c.avatar_url ? '<img class="avatar" src="' + esc(c.avatar_url) + '">' : '<div class="avatar"></div>') +
        '<div style="flex:1;min-width:0"><div class="title">' + esc(c.title || c.username) +
        '<span class="tag ' + (c.platform === 'discord' ? 'dc' : 'tg') + '">' + esc(c.platform) + '</span>' +
        '<span class="tag">' + esc(c.kind) + '</span>' +
        (c.readable ? '<span class="tag ok">lesbar</span>' : '<span class="tag no">nicht lesbar</span>') +
        '<span class="score">' + Number(c.confidence).toFixed(2) + '</span>' +
        (c.readable ? '<button data-watch="' + esc(c.username) + '" style="margin-left:auto;padding:3px 9px;font-size:12px">beobachten</button>' : '') +
        '</div><div class="meta">@' + esc(c.username || '') + ' · ' + num(c.members) +
        ' Abonnenten · <a href="' + esc(c.url) + '" target="_blank" rel="noopener">öffnen</a></div>' +
        (c.description ? '<div class="desc">' + esc(c.description.slice(0, 240)) + '</div>' : '') +
        '</div></div></div>').join('')
    : '<div class="empty">Keine Suchtreffer im Datenstand.</div>';

  document.getElementById('chips').innerHTML = (BAKED.methods || []).map(m =>
    '<span class="chip' + (m.available ? '' : ' off') + '" title="' + esc(m.reason) + '">' +
    esc(m.name) + (m.available ? ' aktiv' : ' inaktiv') + '</span>').join('');
}

/* ------------------------------------------------------------ Steuerung --- */
let timer = null, paused = false;
function schedule(){
  if(timer) clearInterval(timer);
  const every = parseInt(document.getElementById('every').value, 10);
  if(!every || paused) return;
  timer = setInterval(() => { if(!paused) pollAll(); }, every * 1000);
}
document.getElementById('every').addEventListener('change', schedule);
document.getElementById('now').onclick = () => pollAll();
document.getElementById('pause').onclick = (ev) => {
  paused = !paused;
  ev.target.textContent = paused ? 'Fortsetzen' : 'Pause';
  setLive(paused ? 'pausiert' : 'aktiv', paused ? 'paused' : 'ok');
  schedule();
};
document.getElementById('add').onclick = () => {
  const v = document.getElementById('addName').value.trim().replace(/^@/, '')
              .replace(/^https?:\/\/t\.me\/(s\/)?/, '');
  if(!v || ST.channels.some(c => c.target.toLowerCase() === v.toLowerCase())) return;
  ST.channels.push({platform: 'telegram', target: v, channel: {title: v}, posts: [],
                    polls: 0, last_poll: null, error: null});
  document.getElementById('addName').value = '';
  save(); render(); pollAll();
};
document.getElementById('reset').onclick = () => {
  localStorage.removeItem(LS);
  ST = loadState(); mode = null; save(); render();
};
document.addEventListener('click', ev => {
  const d = ev.target.closest('button[data-drop]');
  if(d){
    ST.channels = ST.channels.filter(c => c.target !== d.dataset.drop);
    save(); render();
  }
  const w = ev.target.closest('button[data-watch]');
  if(w){
    const t = w.dataset.watch;
    if(!ST.channels.some(c => c.target === t)){
      ST.channels.push({platform: 'telegram', target: t, channel: {title: t}, posts: [],
                        polls: 0, last_poll: null, error: null});
      save(); render(); pollAll();
    }
  }
});

render();
schedule();
pollAll();
</script>
</body>
</html>
"@

Set-Content -Path $OutputPath -Value $htmlContent -Encoding UTF8
