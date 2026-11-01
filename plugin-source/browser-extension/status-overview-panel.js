(() => {
  const container = document.getElementById('overview-rows');
  if (!container) return;
  const byId = id => document.getElementById(id);
  const interval = byId('overview-interval'), maxLinks = byId('overview-max-links'), enabled = byId('overview-enabled'), showLinks = byId('overview-show-links'), autoSort = byId('overview-auto-sort'), skipOnline = byId('overview-skip-online'), message = byId('overview-message');
  const reverse = byId('overview-reverse'), grid2 = byId('overview-grid2');
  const settingsModal = byId('overview-settings-modal'), linksModal = byId('overview-links-modal');
  const monitorTop = byId('overview-top'), connectionTop = byId('connection-top');
  const monitorSection = byId('overview-heading').closest('section'), connectionSection = byId('hook-heading').closest('section');
  const inputs = [], statuses = [], counts = [], buttons = [], retries = [], rowElements = [];
  const labels = { online: 'Online', offline: 'Offline', unknown: 'Ungeprüft', checking: 'Prüft', error: 'Prüfung fehlgeschlagen' };
  let current = [], linkIndex = null, returnFocus = null;
  const send = async (type, extra = {}) => { const result = await chrome.runtime.sendMessage({type, ...extra}); if (!result?.ok) throw new Error(result?.error || 'Aktion fehlgeschlagen'); return result; };
  const copy = async rows => {
    const text = rows.filter(r => r?.handle && r.media?.length).map(r => `@${r.handle}\n${r.media.map(m => m.url).join('\n')}`).join('\n\n');
    if (!text) { message.textContent = 'Keine Links vorhanden.'; return; }
    await navigator.clipboard.writeText(text); message.textContent = 'Links in die Zwischenablage kopiert.';
  };
  function openModal(modal, focus) { returnFocus = document.activeElement; modal.hidden = false; focus.focus(); }
  function closeModal(modal) { modal.hidden = true; if (modal === linksModal) linkIndex = null; returnFocus?.focus(); }
  function renderLinks() {
    if (linkIndex === null) return;
    const row = current[linkIndex], list = byId('overview-links-list');
    byId('overview-links-heading').textContent = row?.handle ? `@${row.handle}` : 'Streamlinks';
    list.replaceChildren();
    for (const item of row?.media || []) {
      const entry = document.createElement('div'); entry.className = 'overview-link';
      const heading = document.createElement('strong');
      const protocol = /hls|m3u8/i.test(`${item.protocol || ''} ${item.url}`) ? 'HLS' : /flv/i.test(`${item.protocol || ''} ${item.url}`) ? 'FLV' : (item.protocol || 'Video');
      heading.textContent = `${protocol} · ${item.audioOnly ? 'Audio' : (item.quality || item.sdkKey || 'Video')}`;
      const url = document.createElement('p'); url.textContent = item.url;
      const button = document.createElement('button'); button.className = 'secondary compact'; button.textContent = 'Kopieren';
      button.addEventListener('click', () => navigator.clipboard.writeText(item.url).then(() => { message.textContent = 'Link in die Zwischenablage kopiert.'; }).catch(e => { message.textContent = e.message; }));
      entry.append(heading, url, button); list.append(entry);
    }
  }
  for (let i = 0; i < 20; i++) {
    const row = document.createElement('div'); row.className = 'overview-row';
    const retry = document.createElement('button'); retry.type = 'button'; retry.className = 'secondary overview-retry'; retry.setAttribute('aria-label', `Stream ${i + 1} neu starten`); retry.title = 'Nächste Streamquelle starten';
    retry.addEventListener('click', async () => { const row = current[i], probing = row?.status === 'online' && !row.media?.length; try { if (probing) message.textContent = `@${row.handle} wird geprüft …`; retry.disabled = true; await send('TLC_OVERVIEW_RETRY', {index: i, handle: row?.handle}); await refresh(); if (probing) message.textContent = `@${row.handle}: ${current[i]?.media?.length || 0} Links`; } catch (error) { message.textContent = error.message; } finally { retry.disabled = current[i]?.status !== 'online'; } });
    const input = document.createElement('input'); input.placeholder = '@live-stream'; input.setAttribute('aria-label', `Stream ${i + 1}`);
    const state = document.createElement('span'); state.className = 'overview-state'; state.setAttribute('role', 'status');
    const count = document.createElement('span'); count.className = 'overview-count';
    const button = document.createElement('button'); button.className = 'secondary compact'; button.textContent = 'Kopieren';
    button.addEventListener('click', () => { if (showLinks.checked) { linkIndex = i; renderLinks(); openModal(linksModal, byId('overview-links-close')); } else copy([current[i]]).catch(e => message.textContent = e.message); });
    input.addEventListener('change', save); row.append(retry, input, state, count, button); container.append(row); retries.push(retry); inputs.push(input); statuses.push(state); counts.push(count); buttons.push(button); rowElements.push(row);
  }
  async function refresh() {
    const result = await send('TLC_OVERVIEW_GET'); current = result.rows;
    if (document.activeElement !== interval) interval.value = result.config.interval;
    if (document.activeElement !== maxLinks) maxLinks.value = result.config.maxLinks;
    monitorTop.checked = result.config.top === 'monitor'; connectionTop.checked = result.config.top === 'connection';
    monitorSection.style.order = monitorTop.checked ? '-1' : ''; connectionSection.style.order = connectionTop.checked ? '-1' : '';
    enabled.checked = result.config.enabled; showLinks.checked = result.config.showLinks; autoSort.checked = result.config.autoSort; skipOnline.checked = result.config.skipOnline; reverse.checked = result.config.reverse; grid2.checked = result.config.grid2;
    byId('overview-more').hidden = result.config.expanded; byId('overview-collapse').hidden = !result.config.expanded;
    const order = result.rows.map((row, i) => i);
    if (result.config.autoSort) order.sort((a, b) => Number(result.rows[b].status === 'online') - Number(result.rows[a].status === 'online') || a - b);
    order.forEach((index, position) => { rowElements[index].style.order = String(position); });
    result.rows.forEach((row, i) => {
      rowElements[i].hidden = !result.config.expanded && i >= 9;
      if (document.activeElement !== inputs[i]) inputs[i].value = row.handle ? '@' + row.handle : '';
      const label = `${labels[row.status] || labels.unknown}${row.checking ? ' (prüft)' : ''}`;
      statuses[i].setAttribute('aria-label', label); statuses[i].title = label; statuses[i].className = `overview-state ${row.status}`;
      counts[i].textContent = String(row.media?.length || 0); counts[i].setAttribute('aria-label', `${row.media?.length || 0} Links`);
      retries[i].disabled = row.status !== 'online';
      retries[i].title = row.media?.length ? 'Nächste Streamquelle starten' : 'Streamstatus und Links erneut prüfen';
      buttons[i].textContent = result.config.showLinks ? 'Anzeigen' : 'Kopieren'; buttons[i].disabled = !row.media?.length;
    });
    if (!linksModal.hidden) renderLinks();
  }
  async function save() {
    try { await send('TLC_OVERVIEW_SET', { config: {handles: inputs.map(input => input.value), interval: interval.value, enabled: enabled.checked, maxLinks: maxLinks.value, showLinks: showLinks.checked, autoSort: autoSort.checked, skipOnline: skipOnline.checked, reverse: reverse.checked, grid2: grid2.checked} }); await refresh(); }
    catch (error) { message.textContent = error.message; }
  }
  for (const element of [interval, maxLinks, enabled, showLinks, autoSort, skipOnline, reverse, grid2]) element.addEventListener('change', save);
  async function setTop(value) { try { await send('TLC_OVERVIEW_SET', {config: {top: value}}); await refresh(); } catch (error) { message.textContent = error.message; } }
  monitorTop.addEventListener('change', () => setTop(monitorTop.checked ? 'monitor' : ''));
  connectionTop.addEventListener('change', () => setTop(connectionTop.checked ? 'connection' : ''));
  byId('overview-more').addEventListener('click', async () => { try { await send('TLC_OVERVIEW_SET', {config:{expanded:true}}); await refresh(); } catch (error) { message.textContent = error.message; } });
  byId('overview-collapse').addEventListener('click', async () => { try { await send('TLC_OVERVIEW_SET', {config:{expanded:false}}); await refresh(); } catch (error) { message.textContent = error.message; } });
  byId('overview-settings').addEventListener('click', () => openModal(settingsModal, interval));
  byId('overview-settings-close').addEventListener('click', () => closeModal(settingsModal));
  byId('overview-links-close').addEventListener('click', () => closeModal(linksModal));
  for (const modal of [settingsModal, linksModal]) modal.addEventListener('click', event => { if (event.target === modal) closeModal(modal); });
  document.addEventListener('keydown', event => { if (event.key === 'Escape') { if (!linksModal.hidden) closeModal(linksModal); else if (!settingsModal.hidden) closeModal(settingsModal); } });
  byId('overview-check').addEventListener('click', async () => { try { await send('TLC_OVERVIEW_CHECK'); await refresh(); } catch(e) { message.textContent = e.message; } });
  byId('overview-reset').addEventListener('click', async () => { try { await send('TLC_OVERVIEW_RESET'); await refresh(); } catch(e) { message.textContent = e.message; } });
  byId('overview-copy').addEventListener('click', () => copy(current).catch(e => message.textContent = e.message));
  byId('overview-open').addEventListener('click', async () => { try { const window = await chrome.windows.getCurrent(); await send('TLC_OVERVIEW_OPEN', {windowId: window.id}); } catch (e) { message.textContent = e.message; } });
  chrome.storage.onChanged.addListener((changes, area) => { if ((area === 'session' && Object.keys(changes).some(k => k.startsWith('tlc-overview-row-'))) || (area === 'local' && changes['tlc-overview-config'])) refresh().catch(() => {}); });
  refresh().catch(e => message.textContent = e.message);
})();
