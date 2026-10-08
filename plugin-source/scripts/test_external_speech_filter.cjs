const test = require('node:test');
const assert = require('node:assert/strict');
const {shouldFilterExternalSpeechTrigger: filter} = require('../browser-extension/content-core.js');
for (const enabled of [false,true]) for (const text of ['.Text','. Text','  .Text','\t\n. Text','Normal','Ein Satz. Noch einer','']) {
 test(JSON.stringify({enabled,text}),()=>assert.equal(filter(text,enabled),enabled && text.trimStart().startsWith('.')));
}
