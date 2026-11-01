const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs'), vm = require('node:vm'), path = require('node:path');
const source = fs.readFileSync(path.join(__dirname,'../browser-extension/status-overview-worker.js'),'utf8');
function setup(fetchImpl, captured = null) {
 const local={},session={},alarms=new Map(),opened=[];let onAlarm;
 const storage=data=>({async get(keys){if(keys==null)return {...data};if(!Array.isArray(keys))keys=[keys];return Object.fromEntries(keys.filter(k=>k in data).map(k=>[k,data[k]]))},async set(values){Object.assign(data,values)},async remove(key){delete data[key]}});
 const chrome={storage:{local:storage(local),session:storage(session)},alarms:{onAlarm:{addListener(f){onAlarm=f}},async create(n,v){alarms.set(n,v)},async clear(n){alarms.delete(n)}},runtime:{onStartup:{addListener(){}},getURL:x=>'chrome-extension://test/'+x},tabs:{async create(v){opened.push(v)},async get(id){return {id,url:'chrome-extension://test/status-overview.html'}}}};
 const core={inspectMetadata(room){return {media:room.media||[]}},liveHandleFromUrl(url){return url.match(/@([^/]+)/)?.[1] || ''}};
 if(captured) { chrome.tabs.query=async()=>captured.tabs; chrome.tabs.sendMessage=async id=>{captured.scans.push(id)}; }
 const context={chrome,core,fetch:fetchImpl,getState:async id=>captured?.states[id] || {media:[]},URL,Date,Set,Map,Object,Array,Math,Number,String,Promise,AbortController,setTimeout,clearTimeout};vm.createContext(context);vm.runInContext(source+'\nglobalThis.overview=TLCOverview;',context);
 return {api:context.overview,opened,session,alarms,async fire(){onAlarm({name:'tlc-overview-check'});await new Promise(r=>setTimeout(r,10))}};
}
const html=(handle,status,media=[])=>`<script id="SIGI_STATE" type="application/json">${JSON.stringify({LiveRoom:{liveRoomUserInfo:{user:{uniqueId:handle},liveRoom:{status,media}}}})}</script>`;
test('checks LIVE and offline via direct requests without opening tabs',async()=>{
 const requested=[];const x=setup(async url=>{requested.push(url);const name=url.match(/@([^/]+)/)[1];return {ok:true,text:async()=>html(name,name==='one'?2:4,[{url:'https://cdn.test/a.flv',audioOnly:false}])}});
 await x.api.message({type:'TLC_OVERVIEW_SET',config:{handles:['@One','Two'],interval:5}});await x.api.message({type:'TLC_OVERVIEW_CHECK'});
 const rows=(await x.api.message({type:'TLC_OVERVIEW_GET'})).rows;assert.equal(rows[0].status,'online');assert.equal(rows[0].media.length,1);assert.equal(rows[1].status,'offline');assert.equal(rows[1].media.length,0);assert.equal(requested.length,2);assert.equal(x.opened.length,0);assert.equal(x.alarms.get('tlc-overview-check').periodInMinutes,5);
});
test('unavailable or mismatched response is an error, never falsely offline',async()=>{
 const x=setup(async url=>url.includes('@one/')?{ok:false}:{ok:true,text:async()=>html('other',4)});await x.api.message({type:'TLC_OVERVIEW_SET',config:{handles:['one','two']}});await x.api.message({type:'TLC_OVERVIEW_CHECK'});const rows=(await x.api.message({type:'TLC_OVERVIEW_GET'})).rows;assert.equal(rows[0].status,'error');assert.equal(rows[1].status,'error');
});
test('rejects duplicate and invalid names; opens overview in requested window',async()=>{
 const x=setup(async()=>{});await assert.rejects(x.api.message({type:'TLC_OVERVIEW_SET',config:{handles:['a','@A']}}),/einmal/);await assert.rejects(x.api.message({type:'TLC_OVERVIEW_SET',config:{handles:['bad/name']}}),/Ungültiger/);await x.api.message({type:'TLC_OVERVIEW_OPEN',windowId:23});assert.equal(x.opened[0].windowId,23);assert.match(x.opened[0].url,/status-overview.html/);await assert.rejects(x.api.message({type:'TLC_OVERVIEW_OPEN'}),/Browserfenster/);
});
test('does not apply an obsolete result after changing a handle',async()=>{
 let release;const pending=new Promise(r=>release=r);const x=setup(async()=>{await pending;return {ok:true,text:async()=>html('one',2)}});await x.api.message({type:'TLC_OVERVIEW_SET',config:{handles:['one']}});const check=x.api.message({type:'TLC_OVERVIEW_CHECK'});await new Promise(r=>setTimeout(r,0));await x.api.message({type:'TLC_OVERVIEW_SET',config:{handles:['two']}});release();await check;const row=(await x.api.message({type:'TLC_OVERVIEW_GET'})).rows[0];assert.equal(row.handle,'two');assert.equal(row.status,'unknown');
});

test('playing streams are skipped until playback stops and timer can be disabled',async()=>{
 const seen=[];const x=setup(async url=>{seen.push(url);const name=url.match(/@([^/]+)/)[1];return {ok:true,text:async()=>html(name,2)}});
 await x.api.message({type:'TLC_OVERVIEW_SET',config:{handles:['one','two'],interval:5}});
 const sender={tab:{id:42},url:'chrome-extension://test/status-overview.html'};
 await x.api.message({type:'TLC_OVERVIEW_PLAYBACK',index:0,handle:'one',playing:true},sender);
 await x.api.message({type:'TLC_OVERVIEW_CHECK'});assert.equal(seen.length,1);assert.match(seen[0],/@two/);
 await x.api.message({type:'TLC_OVERVIEW_PLAYBACK',index:0,handle:'one',playing:false},sender);await x.api.message({type:'TLC_OVERVIEW_CHECK'});assert.equal(seen.length,3);
 await x.api.message({type:'TLC_OVERVIEW_SET',config:{handles:['one','two'],enabled:false}});assert.equal(x.alarms.has('tlc-overview-check'),false);await x.fire();assert.equal(seen.length,3);
});

test('persists settings, limits sources, and resets only handles', async()=>{
 const media=Array.from({length:35},(_,i)=>({url:`https://cdn.test/${i}.flv`,audioOnly:i===0}));
 const x=setup(async()=>({ok:true,text:async()=>html('one',2,media)}));
 await x.api.message({type:'TLC_OVERVIEW_SET',config:{handles:['one'],interval:7,maxLinks:30,showLinks:true,autoSort:true,skipOnline:false}});
 await x.api.message({type:'TLC_OVERVIEW_CHECK'}); let state=await x.api.message({type:'TLC_OVERVIEW_GET'});
 assert.equal(state.rows[0].media.length,30);assert.equal(state.rows[0].media[0].audioOnly,true);
 await x.api.message({type:'TLC_OVERVIEW_SET',config:{maxLinks:5}});state=await x.api.message({type:'TLC_OVERVIEW_GET'});assert.equal(state.rows[0].media.length,5);
 await x.api.message({type:'TLC_OVERVIEW_RESET'});state=await x.api.message({type:'TLC_OVERVIEW_GET'});
 assert.equal(state.rows[0].handle,'');assert.equal(state.rows[0].media.length,0);assert.equal(state.config.interval,7);assert.equal(state.config.autoSort,true);assert.equal(state.config.showLinks,true);
});
test('skips online streams only when the option is enabled',async()=>{
 let calls=0;const x=setup(async()=>{calls++;return {ok:true,text:async()=>html('one',2,[{url:'https://cdn.test/a.flv'}])}});
 await x.api.message({type:'TLC_OVERVIEW_SET',config:{handles:['one'],skipOnline:true}});await x.api.message({type:'TLC_OVERVIEW_CHECK'});await x.api.message({type:'TLC_OVERVIEW_CHECK'});assert.equal(calls,1);
 await x.api.message({type:'TLC_OVERVIEW_SET',config:{skipOnline:false}});await x.api.message({type:'TLC_OVERVIEW_CHECK'});assert.equal(calls,2);
});
test('retry targets the original handle and rejects stale or invalid slots',async()=>{
 const x=setup(async()=>{});await x.api.message({type:'TLC_OVERVIEW_SET',config:{handles:['one','two'],skipOnline:true}});
 x.session['tlc-overview-row-1']={handle:'two',status:'online',media:[{url:'https://cdn.test/a.flv'}]};
 await x.api.message({type:'TLC_OVERVIEW_RETRY',index:1,handle:'two'});assert.equal(x.session['tlc-overview-retry-1'].handle,'two');
 await assert.rejects(x.api.message({type:'TLC_OVERVIEW_RETRY',index:1,handle:'one'}),/nicht gefunden/);
 await assert.rejects(x.api.message({type:'TLC_OVERVIEW_RETRY',index:9,handle:'two'}),/nicht gefunden/);
});

test('online without links is checked on schedule and retries only its own slot',async()=>{
 const seen=[]; const x=setup(async url=>{const name=url.match(/@([^/]+)/)[1];seen.push(name);return {ok:true,text:async()=>html(name,2,name==='two'?[{url:'https://cdn.test/two.flv'}]:[])}});
 await x.api.message({type:'TLC_OVERVIEW_SET',config:{handles:['one','two'],skipOnline:true}});await x.api.message({type:'TLC_OVERVIEW_CHECK'});await x.api.message({type:'TLC_OVERVIEW_CHECK'});assert.deepEqual(seen,['one','two','one']);
 await x.api.message({type:'TLC_OVERVIEW_RETRY',index:0,handle:'one'});assert.deepEqual(seen,['one','two','one','one']);
});
test('top selection is persisted and reset preserves it',async()=>{const x=setup(async()=>{});await x.api.message({type:'TLC_OVERVIEW_SET',config:{top:'monitor'}});assert.equal((await x.api.message({type:'TLC_OVERVIEW_GET'})).config.top,'monitor');await x.api.message({type:'TLC_OVERVIEW_SET',config:{top:'connection'}});assert.equal((await x.api.message({type:'TLC_OVERVIEW_GET'})).config.top,'connection');await x.api.message({type:'TLC_OVERVIEW_RESET'});assert.equal((await x.api.message({type:'TLC_OVERVIEW_GET'})).config.top,'connection');await x.api.message({type:'TLC_OVERVIEW_SET',config:{top:''}});assert.equal((await x.api.message({type:'TLC_OVERVIEW_GET'})).config.top,'');});

test('manual zero-link retry rescans only matching LIVE tab and imports its captured sources',async()=>{
 const captured={tabs:[{id:1,url:'https://www.tiktok.com/@one/live'},{id:2,url:'https://www.tiktok.com/@two/live'}],states:{1:{media:[]},2:{media:[{url:'https://cdn.test/wrong.flv'}]}},scans:[]};
 const x=setup(async()=>({ok:true,text:async()=>html('one',2)}),captured);
 await x.api.message({type:'TLC_OVERVIEW_SET',config:{handles:['one']}});await x.api.message({type:'TLC_OVERVIEW_CHECK'});assert.equal((await x.api.message({type:'TLC_OVERVIEW_GET'})).rows[0].media.length,0);
 captured.states[1].media=[{url:'https://cdn.test/live.flv',protocol:'FLV'}];await x.api.message({type:'TLC_OVERVIEW_RETRY',index:0,handle:'one'});
 const row=(await x.api.message({type:'TLC_OVERVIEW_GET'})).rows[0];assert.equal(row.media[0].url,'https://cdn.test/live.flv');assert.deepEqual(captured.scans,[1,1]);
});

test('twenty handles, persistent grid options and high-index actions are supported',async()=>{
 const x=setup(async url=>{const name=url.match(/@([^/]+)/)[1];return {ok:true,text:async()=>html(name,2,[{url:`https://cdn.test/${name}.flv`}])}});
 const handles=Array.from({length:20},(_,i)=>`user${i}`);await x.api.message({type:'TLC_OVERVIEW_SET',config:{handles,expanded:true,reverse:true,grid2:true}});await x.api.message({type:'TLC_OVERVIEW_CHECK'});
 let result=await x.api.message({type:'TLC_OVERVIEW_GET'});assert.equal(result.rows.length,20);assert.equal(result.rows[19].status,'online');assert.equal(result.config.reverse,true);assert.equal(result.config.grid2,true);
 await x.api.message({type:'TLC_OVERVIEW_RETRY',index:19,handle:'user19'});assert.equal(x.session['tlc-overview-retry-19'].handle,'user19');
 await x.api.message({type:'TLC_OVERVIEW_SET',config:{expanded:false}});result=await x.api.message({type:'TLC_OVERVIEW_GET'});assert.equal(result.config.handles[19],'user19');
 await x.api.message({type:'TLC_OVERVIEW_RESET'});result=await x.api.message({type:'TLC_OVERVIEW_GET'});assert.equal(result.config.handles.every(h=>!h),true);
});

test('manual retry refreshes playing stream URLs only when skipOnline is disabled',async()=>{
 let count=0;const x=setup(async()=>{count++;return {ok:true,text:async()=>html('one',2,[{url:`https://cdn.test/live-${count}.flv`}])}});
 await x.api.message({type:'TLC_OVERVIEW_SET',config:{handles:['one'],skipOnline:false}});await x.api.message({type:'TLC_OVERVIEW_CHECK'});
 const sender={tab:{id:42},url:'chrome-extension://test/status-overview.html'};await x.api.message({type:'TLC_OVERVIEW_PLAYBACK',index:0,handle:'one',playing:true},sender);
 await x.api.message({type:'TLC_OVERVIEW_RETRY',index:0,handle:'one'});assert.equal(count,2);assert.match((await x.api.message({type:'TLC_OVERVIEW_GET'})).rows[0].media[0].url,/live-2/);assert.equal(x.session['tlc-overview-retry-0'].handle,'one');
 await x.api.message({type:'TLC_OVERVIEW_SET',config:{skipOnline:true}});await x.api.message({type:'TLC_OVERVIEW_CHECK'});await x.api.message({type:'TLC_OVERVIEW_RETRY',index:0,handle:'one'});assert.equal(count,2);
});
