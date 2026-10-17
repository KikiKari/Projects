const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const source = fs.readFileSync(path.join(__dirname, '../browser-extension/sidepanel.js'), 'utf8');
const {voices} = JSON.parse(fs.readFileSync(path.join(__dirname, '../companion-service/voice-catalog.json'), 'utf8'));
function element(tag) { return {tag, children: [], dataset: {}, value: '', append(node) { this.children.push(node); }}; }
const select = element('select');
const context = vm.createContext({document:{createElement:element},elements:{'speech-voice':select},speechVoiceName:'sherpa-de-supertonic-7',voiceCatalog:voices,clearChildren(node){node.children=[];}});
vm.runInContext(source.slice(source.indexOf('  const BASE_VOICE_ORDER'), source.indexOf('  const core =')), context);
vm.runInContext(source.slice(source.indexOf('  function sherpaSpeechVoices'), source.indexOf('  async function loadSpeechVoices')), context);
context.setSpeechVoiceOptions([], voices);
for (const label of ['Kyrillisch','Asiatisch','Abjad','Indisch','Effekt Stimmen']) {
  const group=select.children.find(node=>node.label===label);
  assert.ok(group,label);
  assert.ok(group.children.length>=3,label);
}
assert.equal(select.children.find(node=>node.label==='Effekt Stimmen').children.length,5);
assert.equal(select.value,'sherpa-de-supertonic-7');
context.setSpeechVoiceOptions([{id:'sherpa-de-supertonic-7',name:'Stil 3',group:''}],voices);
assert.equal(select.value,'sherpa-de-supertonic-7');
assert.ok(select.children.find(node=>node.label==='Effekt Stimmen').children.find(node=>node.value===select.value));
context.speechVoiceName='sherpa-ru-irina';
context.setSpeechVoiceOptions([],voices.map(({group,...voice})=>voice));
assert.equal(select.value,'sherpa-ru-irina');
assert.ok(select.children.find(node=>node.label==='Kyrillisch').children.find(node=>node.value==='sherpa-ru-irina'));
console.log('PASS: five groups, all styles selectable, retained selection, legacy catalog fallback');
