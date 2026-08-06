/**
 * TikTokCompanion — Live/Offline-Erkennung und Embed-Steuerung.
 *
 * Bewusst ohne jede Umgehung von Zugangskontrollen: gelesen werden nur
 * öffentliche Statusdaten, angezeigt wird der offizielle Embed-Player
 * (tiktok.com/embed/live/@name), der ohne Anmeldung und ohne Geschenk-
 * oder Kauf-Oberfläche läuft.
 *
 * Zwei Bezugswege für den Status, in dieser Reihenfolge:
 *   1. Lokaler Monitor  ->  GET {apiBase}/api/tiktok/status?users=<name>
 *      (Projekt "Telegram Monitor", `python server.py`)
 *   2. Direktabruf der öffentlichen Aufzeichnungs-Profilseite
 *      (braucht in einer Erweiterung host_permissions für streamrecorder.io)
 *
 * Verwendung:
 *   const ttc = new TikTokCompanion({ apiBase: 'http://127.0.0.1:8765',
 *                                     onState: st => {...} });
 *   ttc.watch('creator', 120);   // Intervall in Sekunden, 0 = manuell
 *   ttc.stop();
 */
class TikTokCompanion {
  constructor(opts = {}) {
    this.apiBase = (opts.apiBase || '').replace(/\/+$/, '');
    this.onState = opts.onState || (() => {});
    this.onError = opts.onError || (() => {});
    this.onGoLive = opts.onGoLive || null;
    this.notifyOnLive = !!opts.notifyOnLive;
    this.user = null;
    this.timer = null;
    this.last = null;
  }

  static embedUrl(user) {
    return 'https://www.tiktok.com/embed/live/@' + encodeURIComponent(user);
  }

  /** Beobachtung starten. interval in Sekunden (0 = nur einmal). */
  watch(user, interval = 120) {
    this.user = String(user || '').replace(/^@/, '').trim();
    this.stop();
    if (!this.user) return;
    this.refresh();
    if (interval > 0) {
      this.timer = setInterval(() => this.refresh(), Math.max(30, interval) * 1000);
    }
  }

  stop() {
    if (this.timer) clearInterval(this.timer);
    this.timer = null;
  }

  async refresh() {
    if (!this.user) return null;
    let st = null;
    try {
      st = await this.viaMonitor(this.user);
    } catch (e) {
      try {
        st = await this.viaPublicPage(this.user);
      } catch (e2) {
        this.onError('Status nicht abrufbar: ' + e.message + ' · ' + e2.message);
        return null;
      }
    }
    this.onError('');
    this._handle(st);
    return st;
  }

  /** Weg 1: lokaler Monitor. */
  async viaMonitor(user) {
    if (!this.apiBase) throw new Error('kein Monitor konfiguriert');
    const r = await fetch(this.apiBase + '/api/tiktok/status?users=' + encodeURIComponent(user),
                          { cache: 'no-store' });
    if (!r.ok) throw new Error('Monitor HTTP ' + r.status);
    const d = await r.json();
    const st = (d.accounts || [])[0];
    if (!st) throw new Error('Monitor ohne Ergebnis');
    return st;
  }

  /** Weg 2: öffentliche Profilseite des Aufzeichnungsdienstes direkt lesen. */
  async viaPublicPage(user) {
    const url = 'https://streamrecorder.io/tiktok/@' + encodeURIComponent(user);
    const r = await fetch(url, { cache: 'no-store' });
    if (!r.ok) throw new Error('Profilseite HTTP ' + r.status);
    return TikTokCompanion.parsePublicPage(await r.text(), user);
  }

  /** Reiner Parser — ohne Netzwerk, damit er sich testen lässt. */
  static parsePublicPage(html, user) {
    const st = {
      platform: 'tiktok', username: user, live: null,
      embed_url: TikTokCompanion.embedUrl(user),
      profile_url: 'https://www.tiktok.com/@' + user,
      live_url: 'https://www.tiktok.com/@' + user + '/live',
      checked_at: new Date().toISOString(), streams: [], source: 'oeffentliche-profilseite'
    };
    const m = html.match(/window\.ALT_DAILY_DATA\s*=\s*(\{[\s\S]*?\});\s*\n/);
    if (m) {
      let daily = {};
      try { daily = JSON.parse(m[1]); } catch (e) { /* unverändert lassen */ }
      const rows = [];
      for (const day of Object.keys(daily).sort().reverse()) {
        for (const s of (daily[day].streams || [])) {
          rows.push({
            day, time: s.time, title: s.title || '',
            duration: s.duration_hr || s.duration_hms,
            is_live: !!s.is_live, thumbnail: s.thumbnail,
            started_at: day + 'T' + (s.time || '00:00') + ':00'
          });
        }
      }
      rows.sort((a, b) => (b.day + (b.time || '')).localeCompare(a.day + (a.time || '')));
      st.streams = rows.slice(0, 20);
      const now = rows.find(r => r.is_live);
      st.live = !!now;
      const ref = now || rows[0];
      if (ref) {
        st.title = ref.title;
        st.started_at = ref.started_at;
        st.duration = ref.duration;
        if (now) {
          const diff = Date.now() - new Date(ref.started_at).getTime();
          if (diff > 0) st.since = Math.floor(diff / 3600000) + 'h ' +
                                   Math.floor((diff % 3600000) / 60000) + 'm';
        }
      }
    }
    const text = html.replace(/<[^>]+>/g, ' ');
    const t = text.match(/tracked\s+([\d.,]+)\s+streams/);
    if (t) st.streams_total = parseInt(t[1].replace(/[.,]/g, ''), 10);
    const a = text.match(/with\s+([\dhm\s]+)\s+of total airtime/);
    if (a) st.airtime = a[1].trim();
    const d = text.match(/across\s+(\d+)\s+active days/);
    if (d) st.active_days = parseInt(d[1], 10);
    const l = text.match(/last seen on ([A-Za-z]{3} \d{1,2}, \d{4})/);
    if (l) st.last_seen = l[1];
    return st;
  }

  _handle(st) {
    const wasLive = this.last && this.last.live === true;
    this.last = st;
    this.onState(st);
    if (st.live === true && !wasLive) {
      if (this.onGoLive) this.onGoLive(st);
      if (this.notifyOnLive) TikTokCompanion.notify(st);
    }
  }

  static notify(st) {
    const title = '@' + st.username + ' ist live';
    const body = st.title || 'Die Sendung läuft.';
    try {
      // In einer Erweiterung: chrome.notifications, sonst die Web-API.
      if (typeof chrome !== 'undefined' && chrome.notifications) {
        chrome.notifications.create({ type: 'basic', title, message: body,
                                      iconUrl: 'icon128.png' });
      } else if ('Notification' in self && Notification.permission === 'granted') {
        new Notification(title, { body, tag: 'ttc-' + st.username });
      }
    } catch (e) { /* Benachrichtigung ist Beiwerk, kein Grund zu scheitern */ }
  }
}

if (typeof module !== 'undefined' && module.exports) module.exports = { TikTokCompanion };
if (typeof window !== 'undefined') window.TikTokCompanion = TikTokCompanion;
