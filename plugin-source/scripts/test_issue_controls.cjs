const {test}=require('node:test');
const assert=require('node:assert/strict');
const fs=require('node:fs');
const vm=require('node:vm');
const path=require('node:path');
const source=fs.readFileSync(path.join(__dirname,'../browser-extension/sidepanel.js'),'utf8');
const core=require('../browser-extension/content-core.js');
function fragment(start,end) { const a=source.indexOf(start),b=source.indexOf(end,a+start.length); assert(a>=0&&b>a); return source.slice(a,b); }
function controls() {
 const document={activeElement:null};
 const elements=new Proxy({}, {get(target,id){return target[id] ||= {hidden:true,disabled:false,textContent:'Off',handlers:{},addEventListener(name,fn){this.handlers[name]=fn},focus(){document.activeElement=this},click(){return this.handlers.click?.({target:this})}}}});
 return {elements,document};
}
test('175 manual and automatic speech reject raw point triggers before author prefixes',async()=>{
 for(const enabled of [false,true]) {
  const spoken=[];const s={core,filterExternalSpeechTriggers:enabled,speechEnabled:true,speechQueue:[],elements:{'speech-status':{}},pumpSpeech(){},speechText:item=>`Autor sagt ${item.content}`,speechLang:()=> 'de',serviceSpeech:async text=>spoken.push(text),browserSpeech:async()=>assert.fail('unexpected fallback')};
  const ctx=vm.createContext(s);
  vm.runInContext(fragment('  async function speakItem(', '  async function pumpSpeech('),ctx);
  vm.runInContext(fragment('  function enqueueSpeech(', '  function ',),ctx);
  for(const content of ['.Text','. Text','  .Text','Normal','Ein Satz. Noch einer']) {await s.speakItem({content});s.enqueueSpeech({content});}
  assert.equal(spoken.length,enabled?2:5);assert.equal(s.speechQueue.length,enabled?2:5);
 }
});
test('176 speech switch commits On/Off only after a successful request',async()=>{
 const s={...controls(),speechEnabled:false,send:async()=>{},refresh:async()=>{},activateSpeech(){s.speechEnabled=true},stopSpeech(){s.speechEnabled=false}};
 vm.runInNewContext(fragment('  elements["toggle-speech"].addEventListener','  elements["speech-volume"].addEventListener'),s);
 await s.elements['toggle-speech'].click();assert.equal(s.speechEnabled,true);
 s.send=async()=>{throw Error('failed')};await s.elements['toggle-speech'].click();assert.equal(s.speechEnabled,true);
 assert.match(s.elements['speech-status'].textContent,/failed/);
 s.send=async()=>{};await s.elements['toggle-speech'].click();assert.equal(s.speechEnabled,false);
});
test('176 Connection selects both commands and preserves state on rejection',async()=>{
 const calls=[];const s={...controls(),currentState:{hook:{armed:false}},send:async cmd=>calls.push(cmd),refresh:async()=>{s.currentState.hook.armed=!s.currentState.hook.armed}};
 vm.runInNewContext(fragment('  elements["toggle-hook"].addEventListener','  elements["reset-tab"].addEventListener'),s);
 await s.elements['toggle-hook'].click();await s.elements['toggle-hook'].click();assert.deepEqual(calls,['TLC_ENABLE_HOOK','TLC_DISABLE_HOOK']);
 s.send=async()=>{throw Error('failed')};await s.elements['toggle-hook'].click();assert.equal(s.currentState.hook.armed,false);assert.match(s.elements.notice.textContent,/failed/);
});
test('176 Connection dialog returns focus and traps Tab in both directions',()=>{
 const s=controls();vm.runInNewContext(fragment('  elements["open-connection-settings"].addEventListener','  elements["open-speech-settings"].addEventListener'),s);
 let key;s.document.addEventListener=(name,fn)=>{key=fn};
 vm.runInNewContext(fragment('  document.addEventListener("keydown"','  elements["keep-speech-active"].addEventListener'),s);
 s.elements['open-connection-settings'].click();assert.equal(s.elements['connection-settings-modal'].hidden,false);assert.equal(s.document.activeElement,s.elements['close-connection-settings']);
 const first=s.elements['close-connection-settings'],last=s.elements['quick-recover-seconds'];s.elements['connection-settings-modal'].querySelectorAll=()=>[first,last];
 let prevented=0;key({key:'Tab',shiftKey:true,preventDefault(){prevented++}});assert.equal(s.document.activeElement,last);
 key({key:'Tab',shiftKey:false,preventDefault(){prevented++}});assert.equal(s.document.activeElement,first);assert.equal(prevented,2);
 key({key:'Escape'});assert.equal(s.elements['connection-settings-modal'].hidden,true);assert.equal(s.document.activeElement,s.elements['open-connection-settings']);
});
