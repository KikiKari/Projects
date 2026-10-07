const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const path = require('node:path');
const source = fs.readFileSync(path.join(__dirname, '../browser-extension/sidepanel.js'), 'utf8');
const start = source.indexOf('  async function refreshPlayer()');
const end = source.indexOf('  function setButtonBusy', start);
assert(start >= 0 && end > start);
async function main() {
  let reply;
  let calls = 0;
  const rendered = [];
  const context = vm.createContext({activeTabId: 1, activeIsTikTok: true, playerContextGeneration: 0,
    send: () => { calls++; return new Promise(resolve => { reply = resolve; }); },
    renderPlayer: state => rendered.push(state)});
  vm.runInContext(source.slice(start, end), context);
  let pending = context.refreshPlayer();
  context.activeTabId = 2;
  reply({response: {playerState: {playing: true}}});
  await pending;
  assert.equal(rendered.length, 0, 'Old tab response must be ignored');
  context.activeIsTikTok = false;
  await context.refreshPlayer();
  assert.equal(calls, 1, 'Non-TikTok tabs must not be polled');
  context.activeIsTikTok = true;
  pending = context.refreshPlayer();
  reply({response: {playerState: {playing: true}}});
  await pending;
  assert.equal(rendered.length, 1, 'Current tab response must render');
  pending = context.refreshPlayer();
  context.activeTabId = 3;
  context.playerContextGeneration++;
  context.activeTabId = 2;
  context.playerContextGeneration++;
  reply({response: {playerState: {playing: false}}});
  await pending;
  assert.equal(rendered.length, 1, 'Returning to the same tab must not revive an old response');
  assert.match(source, /async function refresh\(\)\s*\{\s*playerContextGeneration\+\+;/,
    'Context invalidation must precede asynchronous tab lookup');
  console.log('PASS: stale tab response ignored, non-TikTok polling skipped, current response rendered');
}
main().catch(error => { console.error(error); process.exitCode = 1; });
