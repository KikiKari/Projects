const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const source = fs.readFileSync(require('node:path').join(__dirname,'../browser-extension/status-overview-player.js'),'utf8');
class Element {
  constructor(tag){this.tag=tag;this.style={};this.classList={toggle(){}};this.children=[];this.listeners={};this.muted=false;this.paused=true;this.src='';this.currentTime=0;}
  append(...nodes){this.children.push(...nodes)} addEventListener(name,fn){(this.listeners[name] ||= new Set()).add(fn)} removeEventListener(name,fn){this.listeners[name]?.delete(fn)}
  emit(name){for(const fn of [...(this.listeners[name] || [])]) fn()} pause(){this.paused=true} removeAttribute(){this.src=''} load(){}
  play(){this.paused=false;queueMicrotask(()=>{if(this.src.includes('bad'))this.emit('error');else {this.currentTime+=1;this.emit('playing');this.emit('timeupdate')}});return Promise.resolve()}
}
test('nine independent tiles start muted and try the next source',async()=>{
  const grid=new Element('main'); let change; const rows=Array.from({length:9},(_,i)=>({handle:'user'+i,status:'online',checkedAt:Date.now(),media:[{protocol:'hls',url:'https://example.test/bad.m3u8'},{protocol:'hls',url:'https://example.test/good.m3u8'}]}));
  const context={document:{getElementById:()=>grid,createElement:tag=>new Element(tag)},chrome:{runtime:{sendMessage:async()=>({ok:true,config:{interval:5},rows})},storage:{onChanged:{addListener:fn=>change=fn}}},window:{addEventListener(){}},URL,Date,Promise,Number,String,Array,JSON,Object,setTimeout,clearTimeout};
  vm.createContext(context);vm.runInContext(source,context);await new Promise(resolve=>setTimeout(resolve,20));
  assert.equal(grid.children.length,29);
  for(const tile of grid.children.slice(0,9)){assert.equal(tile.children[1].muted,true);assert.match(tile.children[1].src,/good/);assert.match(tile.children[2].textContent,/abgespielt/)}
  rows[0]={handle:'user0',status:'offline',checkedAt:Date.now(),media:[]};change({'tlc-overview-row-0':{}},'session');await new Promise(resolve=>setTimeout(resolve,10));
  assert.equal(grid.children[0].hidden,true);assert.match(grid.children[1].children[1].src,/good/);
});
test('retry switches only the requested tile, tries remaining sources and can restart a single source',async()=>{
  const grid=new Element('main'); let change;
  const rows=Array.from({length:9},(_,i)=>({handle:'user'+i,status:'online',checkedAt:Date.now()-600000,media:[{protocol:'hls',url:`https://example.test/${i}-first.m3u8`},{protocol:'hls',url:`https://example.test/${i}-bad.m3u8`},{protocol:'hls',url:`https://example.test/${i}-next.m3u8`}]}));
  for(const row of rows) row.checkedAt=Date.now();
  const context={document:{getElementById:()=>grid,createElement:tag=>new Element(tag)},chrome:{runtime:{sendMessage:async()=>({ok:true,config:{interval:5},rows})},storage:{onChanged:{addListener:fn=>change=fn}}},window:{addEventListener(){}},URL,Date,Promise,Number,String,Array,JSON,Object,setTimeout,clearTimeout};
  vm.createContext(context);vm.runInContext(source,context);await new Promise(r=>setTimeout(r,20));
  const untouched=grid.children[1].children[1].src;assert.match(grid.children[0].children[1].src,/first/);
  change({'tlc-overview-retry-0':{newValue:{handle:'user0',nonce:1}}},'session');await new Promise(r=>setTimeout(r,20));
  assert.match(grid.children[0].children[1].src,/next/);assert.equal(grid.children[1].children[1].src,untouched);
  change({'tlc-overview-retry-0':{newValue:{handle:'other',nonce:2}}},'session');await new Promise(r=>setTimeout(r,10));assert.match(grid.children[0].children[1].src,/next/);
  rows[0].media=[{protocol:'hls',url:'https://example.test/only.m3u8'}];rows[0].checkedAt=Date.now();change({'tlc-overview-row-0':{}},'session');await new Promise(r=>setTimeout(r,10));
  change({'tlc-overview-retry-0':{newValue:{handle:'user0',nonce:3}}},'session');await new Promise(r=>setTimeout(r,10));assert.match(grid.children[0].children[1].src,/only/);
});

test('selects first online entries among 20, reverse order and four-tile mode without restarting retained streams',async()=>{
 const grid=new Element('main');let change;const config={interval:5,expanded:true,grid2:true,reverse:false,autoSort:true};
 const rows=Array.from({length:20},(_,i)=>({handle:'user'+i,status:i%2?'online':'offline',checkedAt:Date.now(),media:[{protocol:'hls',url:`https://example.test/${i}.m3u8`}]}));
 const ctx={document:{getElementById:()=>grid,createElement:tag=>new Element(tag)},chrome:{runtime:{sendMessage:async()=>({ok:true,config,rows})},storage:{onChanged:{addListener:fn=>change=fn}}},window:{addEventListener(){}},URL,Date,Promise,Number,String,Array,JSON,Object,Map,setTimeout,clearTimeout};
 vm.createContext(ctx);vm.runInContext(source,ctx);await new Promise(r=>setTimeout(r,20));
 const shown=()=>grid.children.slice(0,20).map((tile,i)=>tile.hidden?null:i).filter(x=>x!==null);assert.deepEqual(shown(),[1,3,5,7]);
 config.reverse=true;change({'tlc-overview-config':{}},'local');await new Promise(r=>setTimeout(r,20));assert.deepEqual(shown(),[13,15,17,19]);assert.equal(grid.children[19].style.order,'0');
 config.grid2=false;change({'tlc-overview-config':{}},'local');await new Promise(r=>setTimeout(r,20));assert.equal(shown().length,9);assert.equal(grid.children[19].style.order,'0');
 config.expanded=false;change({'tlc-overview-config':{}},'local');await new Promise(r=>setTimeout(r,20));assert.deepEqual(shown(),[1,3,5,7]);
});
