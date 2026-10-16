const test = require('node:test');
const assert = require('node:assert/strict');
const {shouldFilterExternalSpeechTrigger: filter, normalizeExternalSpeechTriggerCharacters: normalize} = require('../browser-extension/content-core.js');
for (const enabled of [false,true]) for (const text of ['.Text','. Text','  .Text','\t\n. Text','Normal','Ein Satz. Noch einer','']) {
 test(JSON.stringify({enabled,text}),()=>assert.equal(filter(text,enabled),enabled && text.trimStart().startsWith('.')));
}
test('0PE-187: individual literal prefixes, commas and semicolons are not separators', () => {
 for (const enabled of [false,true]) {
  for (const text of ['.Hallo', ',Hallo', '- Hallo', '  , Hallo']) assert.equal(filter(text,enabled,'.,-'),enabled);
  for (const text of ['Hallo, zusammen.','Normal-Text','Hallo','.']) assert.equal(filter(text,enabled,',-'),false);
  assert.equal(filter(';Hallo',enabled,';'),enabled);
  assert.equal(filter('[Hallo',enabled,'['),enabled);
  assert.equal(filter('Hallo',enabled,'['),false);
 }
});
test('0PE-187: five Unicode scalar triggers, paste sanitization and explicit empty selection', () => {
 assert.equal(normalize(undefined),'.');
 assert.equal(normalize(''), '');
 assert.equal(normalize('.,-;:!'), '.,-;:');
 assert.equal(normalize(' a1 \"\'.,- '), '.,-');
 assert.equal(normalize('😀😁😂😃😄😅'), '😀😁😂😃😄');
 assert.equal(filter('😀Hallo',true,'😀'),true);
 assert.equal(filter('.Hallo',true,''),false);
 assert.equal(filter('.Hallo',true,','),false);
});
