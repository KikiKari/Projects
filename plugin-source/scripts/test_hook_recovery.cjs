"use strict";
const {test}=require('node:test');
const assert=require('node:assert/strict');
const {create}=require('../browser-extension/hook-recovery.js');
function harness() {
 let now=1000, serial=0, identity='stream-a'; const timers=new Map(), events=[], sockets=[];
 const controller=create({now:()=>now,uuid:()=>String(++serial),identity:()=>identity,
 emit:e=>events.push(e), later:(fn,ms)=>{const id=++serial;timers.set(id,{at:now+ms,fn});return id;},cancel:id=>timers.delete(id),
 connect:(template,token)=>{const s={token,closed:false,close(){this.closed=true;}};sockets.push(s);return s;}});
 const tick=ms=>{const target=now+ms;while(true){const next=[...timers].filter(([,t])=>t.at<=target).sort((a,b)=>a[1].at-b[1].at)[0];if(!next)break;now=next[1].at;timers.delete(next[0]);next[1].fn();}now=target;};
 return {controller,tick,events,sockets,timers,stream:v=>{identity=v;controller.checkStream();},prime:()=>{controller.nativeConnected({supported:true});controller.configure({enabled:true,seconds:3});controller.nativeDisconnected();}};
}
test('hook default disabled and unverified protocol cannot create sockets',()=>{const h=harness();h.controller.nativeDisconnected();h.tick(60000);assert.equal(h.sockets.length,0);h.controller.configure({enabled:true});h.tick(60000);assert.equal(h.sockets.length,0);assert.equal(h.events.at(-1).phase,'unavailable');});
test('five synthetic hook failures recover without any media/navigation capability',()=>{const h=harness();h.prime();for(let i=0;i<5;i++){h.tick(2999);assert.equal(h.sockets.length,i);h.tick(1);const {token}=h.sockets.at(-1);h.controller.stage(token,'socket-open');h.tick(200);h.controller.stage(token,'first-frame');h.tick(100);h.controller.stage(token,'first-decoded-message');assert.equal(h.controller.connected(token),true);assert.equal(h.events.at(-1).disconnectToDecodedMs,3300);h.controller.nativeConnected({supported:true});assert.equal(h.sockets.at(-1).closed,true);h.controller.nativeDisconnected();}});
test('open alone times out after ten seconds, one socket, backoff capped at 30 seconds',()=>{const h=harness();h.prime();h.tick(3000);for(let i=0;i<6;i++){const s=h.sockets.at(-1);h.controller.stage(s.token,'socket-open');h.tick(9999);assert.equal(s.closed,false);h.tick(1);assert.equal(s.closed,true);const delay=h.events.at(-1).effectiveDelayMs;assert.ok(delay<=30000);h.tick(delay);assert.equal(h.sockets.filter(s=>!s.closed).length,1);}});
test('native takeover cancels deadline and ignores stale socket callbacks',()=>{const h=harness();h.prime();h.tick(3000);const token=h.sockets[0].token;h.controller.nativeConnected({supported:true});assert.equal(h.controller.connected(token),false);h.controller.failed(token,'socket-close');h.tick(60000);assert.equal(h.sockets.length,1);assert.equal(h.events.at(-1).phase,'native');});
test('stream switch discards template and cancels scheduled attempt',()=>{const h=harness();h.prime();h.stream('stream-b');h.tick(60000);assert.equal(h.sockets.length,0);h.controller.nativeDisconnected();assert.equal(h.events.at(-1).phase,'unavailable');});
test('disable closes owned socket and policy rejection forbids retries',()=>{const h=harness();h.prime();h.tick(3000);h.controller.configure({enabled:false});assert.equal(h.sockets[0].closed,true);h.tick(60000);assert.equal(h.sockets.length,1);const p=harness();p.prime();p.tick(3000);p.controller.failed(p.sockets[0].token,'policy-rejected');p.tick(60000);assert.equal(p.sockets.length,1);assert.equal(p.events.at(-1).phase,'unavailable');});
test('disposed document never reconnects after new configuration',()=>{const h=harness();h.prime();h.controller.dispose();h.controller.configure({enabled:true});h.tick(60000);assert.equal(h.sockets.length,0);});
const proto=require('../browser-extension/proto-main.js');
test('ACK and heartbeat encoder round trips supported dialect and rejects malformed controls',()=>{
 assert.equal(proto.inspectTransportControl(proto.encodeTransport('hb')).type,'hb');
 const ack=proto.inspectTransportControl(proto.encodeTransport('ack','18446744073709551615','opaque'));
 assert.equal(ack.id,'18446744073709551615');assert.equal(ack.payload,'opaque');
 assert.equal(proto.inspectTransportControl(proto.encodeTransport('ack',0)),null);
 assert.equal(proto.inspectTransportControl(proto.encodeTransport('hb',1)),null);
 assert.equal(proto.inspectTransportControl(new Uint8Array([255])),null);
 assert.throws(()=>proto.encodeTransport('ack',-1),RangeError);
});
const vm=require('node:vm'),fs=require('node:fs'),path=require('node:path');
const {webcrypto}=require('node:crypto');
test('actual hook observes protocol before reconnecting; own socket ACKs only requested frames',async()=>{
 let now=1000,seq=0;const timers=new Map(),sockets=[],posts=[],listeners={};
 class Socket {constructor(){this.listeners={};this.sent=[];sockets.push(this);}addEventListener(k,f){(this.listeners[k]??=[]).push(f);}emit(k,event={}){for(const f of this.listeners[k]||[])f(event);}send(data){this.sent.push(data);}close(){this.emit('close',{code:1000,wasClean:true});}}
 const later=(fn,ms,repeat=false)=>{const id=++seq;timers.set(id,{at:now+ms,ms,fn,repeat});return id;};
 const tick=ms=>{const until=now+ms;while(true){const next=[...timers].filter(([,v])=>v.at<=until).sort((a,b)=>a[1].at-b[1].at)[0];if(!next)break;now=next[1].at;if(next[1].repeat)next[1].at+=next[1].ms;else timers.delete(next[0]);next[1].fn();}now=until;};
 class ClockDate extends Date{constructor(...a){super(...(a.length?a:[now]));}static now(){return now;}}
 const window={WebSocket:Socket,postMessage:m=>posts.push(m),addEventListener:(k,f)=>{listeners[k]=f;}};
 const context=vm.createContext({window,location:{origin:'https://www.tiktok.com',pathname:'/@fixture/live',href:'https://www.tiktok.com/@fixture/live'},URL,crypto:webcrypto,performance:{now:()=>now},Date:ClockDate,setTimeout:later,clearTimeout:id=>timers.delete(id),setInterval:(fn,ms)=>later(fn,ms,true),clearInterval:id=>timers.delete(id)});
 vm.runInContext(fs.readFileSync(path.join(__dirname,'../browser-extension/hook-recovery.js'),'utf8'),context);
 vm.runInContext("window[Symbol.for('tiktok-live-companion.hook-recovery')]=globalThis[Symbol.for('tiktok-live-companion.hook-recovery')]",context);
 window[Symbol.for('tiktok-live-companion.proto')]={...proto,decodeWebSocketEnvelope:async data=>({transport:{type:'msg',id:'42',needAck:data[0]===1,internalExt:'opaque'},records:{captions:[],chatMessages:[],giftMessages:[],liveEvents:[{type:'test'}]}})};
 vm.runInContext(fs.readFileSync(path.join(__dirname,'../browser-extension/hook.js'),'utf8'),context);
 listeners.message({source:window,origin:'https://www.tiktok.com',data:{source:'tiktok-live-companion-control',type:'hook-reconnect-config',enabled:true,seconds:3}});
 const native=new window.WebSocket('wss://webcast.tiktok.com/socket');native.emit('open');
 native.emit('message',{data:new Uint8Array([1])});await new Promise(r=>setImmediate(r));
 native.send(proto.encodeTransport('ack',42,'opaque'));native.send(proto.encodeTransport('hb'));tick(5000);native.send(proto.encodeTransport('hb'));
 native.emit('close',{code:1006});tick(3000);assert.equal(sockets.length,2);
 const owned=sockets[1];owned.emit('open');owned.emit('message',{data:new Uint8Array([0])});await new Promise(r=>setImmediate(r));assert.equal(owned.sent.length,0);
 owned.emit('message',{data:new Uint8Array([1])});await new Promise(r=>setImmediate(r));assert.equal(proto.inspectTransportControl(owned.sent[0]).type,'ack');
 tick(5000);assert.equal(proto.inspectTransportControl(owned.sent[1]).type,'hb');
 assert.ok(posts.some(p=>p.recovery?.phase==='connected'));
 listeners.pagehide();
});
