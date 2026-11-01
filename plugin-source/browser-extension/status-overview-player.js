(() => {
  const grid = document.getElementById('grid');
  const tiles = Array.from({length: 20}, (_, index) => {
    const root = document.createElement('section'); root.className = 'tile'; root.hidden = true;
    const title = document.createElement('h2'), video = document.createElement('video'), status = document.createElement('p');
    video.controls = true; video.muted = true; video.autoplay = true; video.playsInline = true;
    root.append(title, video, status); grid.append(root);
    const tile = {root, title, video, status, player: null, generation: 0, signature: '', index, handle: '', lastReport: 0, sourceUrl: '', reporting: Promise.resolve()};
    const active = () => { if (tile.handle && !video.paused && Date.now() - tile.lastReport >= 10000) { tile.lastReport = Date.now(); report(tile, true); } };
    const inactive = () => { tile.lastReport = 0; report(tile, false); };
    video.addEventListener('timeupdate', active);
    for (const event of ['pause', 'ended', 'error', 'waiting']) video.addEventListener(event, inactive);
    return tile;
  });
  const placeholders = Array.from({length:9}, () => { const root = document.createElement('section'); root.className = 'tile'; root.hidden = true; grid.append(root); return root; });
  function report(tile, playing) {
    const payload = {type:'TLC_OVERVIEW_PLAYBACK', index:tile.index, handle:tile.handle, playing};
    tile.reporting = tile.reporting.catch(() => {}).then(() => chrome.runtime.sendMessage(payload)).catch(() => {});
  }
  function destroy(tile) {
    report(tile, false);
    if (tile.cancel) { const cancel = tile.cancel; tile.cancel = null; cancel(); }
    try { tile.player?.pause(); tile.player?.unload(); tile.player?.detachMediaElement(); tile.player?.destroy(); } catch (_) {}
    tile.player = null; tile.video.pause(); tile.video.removeAttribute('src'); tile.video.load();
  }
  function trySource(tile, source, generation) {
    return new Promise(resolve => {
      let done = false, player = null;
      const video = tile.video;
      const startedAt = Number(video.currentTime || 0);
      const finish = ok => {
        if (done) return; done = true; tile.cancel = null; clearTimeout(timer);
        video.removeEventListener('timeupdate', progressed); video.removeEventListener('error', failed);
        if (ok && tile.generation === generation) tile.player = player;
        else if (player) { try { player.pause(); player.unload(); player.detachMediaElement(); player.destroy(); } catch (_) {} }
        resolve(ok && tile.generation === generation);
      };
      const progressed = () => { if (!video.paused && Number(video.currentTime || 0) > startedAt + 0.2) finish(true); };
      const failed = () => finish(false);
      const timer = setTimeout(failed, 15000);
      tile.cancel = failed;
      video.addEventListener('timeupdate', progressed); video.addEventListener('error', failed);
      try {
        if (/flv/i.test(source.protocol || '')) {
          if (!globalThis.mpegts?.isSupported?.()) return finish(false);
          player = mpegts.createPlayer({type:'flv', isLive:true, url:source.url}, {enableWorker:false, enableStashBuffer:false, liveBufferLatencyChasing:true});
          player.on(mpegts.Events.ERROR, failed); player.attachMediaElement(video); player.load(); player.play().catch(() => {});
        } else { video.src = source.url; video.load(); video.play().catch(() => {}); }
      } catch (_) { finish(false); }
    });
  }
  async function render(tile, row, interval, retry = false) {
    const signature = JSON.stringify([row.handle, row.status, row.checkedAt]);
    if (!retry && tile.signature === signature) return;
    tile.signature = signature; const generation = ++tile.generation; destroy(tile);
    if (tile.handle !== (row.handle || '')) tile.sourceUrl = '';
    tile.handle = row.handle || ''; tile.lastReport = 0;
    tile.title.textContent = row.handle ? '@' + row.handle : 'Nicht belegt';
    const descriptions = {unknown:'Noch nicht geprüft', checking:'LIVE wird geprüft …', offline:'Offline', error:'LIVE-Prüfung fehlgeschlagen'};
    if (row.status !== 'online') { tile.status.textContent = descriptions[row.status] || 'Nicht belegt'; return; }
    if (!retry && (!row.checkedAt || Date.now() - row.checkedAt > (interval + 1) * 60000)) { tile.status.textContent = 'Links veraltet – nächste Prüfung abwarten.'; return; }
    const sources = (row.media || []).filter(m => {
      try { if (m.audioOnly) return false; const expires = Number(new URL(m.url).searchParams.get('expire')); return !expires || expires * 1000 > Date.now(); } catch (_) { return false; }
    }).sort((a,b) => (/hls/i.test(a.protocol) ? 0 : 1) - (/hls/i.test(b.protocol) ? 0 : 1));
    const previous = retry ? sources.findIndex(source => source.url === tile.sourceUrl) : -1;
    if (previous >= 0) sources.push(...sources.splice(0, previous + 1));
    for (const source of sources) {
      tile.sourceUrl = source.url;
      if (generation !== tile.generation) return;
      tile.status.textContent = `Quelle wird geprüft (${source.quality || source.protocol || 'Video'}) …`;
      if (await trySource(tile, source, generation)) { tile.lastReport = Date.now(); report(tile, true); tile.status.textContent = `${source.quality || 'Video'} wird abgespielt.`; return; }
      if (generation !== tile.generation) return;
      destroy(tile);
    }
    if (generation === tile.generation) tile.status.textContent = 'Keine Quelle abspielbar; nächste Prüfung abwarten.';
  }
  async function refresh() {
    const result = await chrome.runtime.sendMessage({type:'TLC_OVERVIEW_GET'});
    if (!result?.ok) return;
    const limit = result.config.grid2 ? 4 : 9;
    grid.classList.toggle('grid2', Boolean(result.config.grid2));
    const order = result.rows.map((row, i) => i).filter(i => result.config.expanded || i < 9);
    if (result.config.autoSort) order.sort((a, b) => Number(result.rows[b].status === 'online') - Number(result.rows[a].status === 'online') || a - b);
    if (result.config.reverse) order.reverse();
    const selected = order.filter(i => result.rows[i].handle && result.rows[i].status === 'online').slice(0, limit);
    const positions = new Map(selected.map((index, position) => [index, position]));
    tiles.forEach((tile, i) => {
      const position = positions.get(i);
      if (position === undefined) {
        if (!tile.root.hidden) { tile.generation++; destroy(tile); tile.signature = ''; tile.handle = ''; tile.sourceUrl = ''; }
        tile.root.hidden = true;
      } else {
        tile.root.hidden = false; tile.root.style.order = String(position);
        render(tile, result.rows[i], result.config.interval);
      }
    });
    placeholders.forEach((root, i) => { root.hidden = i >= limit - selected.length; root.style.order = String(selected.length + i); });
  }
  chrome.storage.onChanged.addListener((changes, area) => {
    if (area === 'session') {
      for (const [key, change] of Object.entries(changes)) {
        const match = /^tlc-overview-retry-(\d|1\d)$/.exec(key), request = change.newValue;
        if (!match || !request?.handle) continue;
        const index = Number(match[1]);
        chrome.runtime.sendMessage({type:'TLC_OVERVIEW_GET'}).then(result => {
          const row = result?.rows?.[index];
          if (result?.ok && row?.handle === request.handle && !tiles[index].root.hidden) render(tiles[index], row, result.config.interval, true);
        }).catch(() => {});
      }
    }
    if ((area === 'session' && Object.keys(changes).some(k => k.startsWith('tlc-overview-row-'))) || (area === 'local' && changes['tlc-overview-config'])) refresh().catch(() => {});
  });
  window.addEventListener('pagehide', () => tiles.forEach(tile => { tile.generation++; destroy(tile); }));
  refresh().catch(() => {});
})();
