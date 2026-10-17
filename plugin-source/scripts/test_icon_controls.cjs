"use strict";
const fs=require("node:fs"),path=require("node:path"),vm=require("node:vm"),assert=require("node:assert/strict"),crypto=require("node:crypto");
const root=path.join(__dirname,"../browser-extension");
const script=fs.readFileSync(path.join(root,"icon-controls.js"),"utf8");
function harness(saved){
 const elements=new Map();
 function element(id){if(!elements.has(id))elements.set(id,{dataset:{},value:"",textContent:id==="player-play"?"Play":id==="player-mute"?"Mute":"On",handlers:{},attributes:{},classList:{add(){}},setAttribute(k,v){this.attributes[k]=v},getAttribute(k){return this.attributes[k]},addEventListener(n,f){this.handlers[n]=f},before(){throw new Error("Unexpected decorative control image")}});return elements.get(id)}
 let observer;const storage=new Map([["tlc-icon-style",saved]]);
 const document={documentElement:{dataset:{}},body:{},getElementById:element,createElement:()=>element(Symbol()),querySelectorAll:()=>[...elements.values()]};
 vm.runInNewContext(script,{document,localStorage:{getItem:k=>storage.get(k),setItem:(k,v)=>storage.set(k,v)},MutationObserver:class{constructor(f){observer=f}observe(){}}});
 return {elements,document,storage,observer};
}
for(const style of [undefined,"invalid","plastisch","glass","linear"]){const h=harness(style);assert.equal(h.document.documentElement.dataset.iconStyle,["plastisch","glass","linear"].includes(style)?style:"plastisch");const picker=h.elements.get("icon-style");picker.value="glass";picker.handlers.change();assert.equal(h.storage.get("tlc-icon-style"),"glass");assert.equal(h.document.documentElement.dataset.iconStyle,"glass");for(const [playing,muted] of [[false,false],[true,false],[false,true],[true,true]]){h.elements.get("player-play").textContent=playing?"Stop":"Play";h.elements.get("player-mute").textContent=muted?"Unmute":"Mute";h.observer();assert.equal(h.elements.get("player-play").dataset.controlIcon,playing?"stop":"play");assert.equal(h.elements.get("player-mute").dataset.controlIcon,muted?"unmute":"mute");}}
const manifest=JSON.parse(fs.readFileSync(path.join(root,"icons/manifest.json"),"utf8"));assert.equal(manifest.length,60);for(const m of manifest){const bytes=fs.readFileSync(path.join(root,"icons",m.style,m.component+".png"));assert.equal(crypto.createHash("sha256").update(bytes).digest("hex"),m.sha256)}
const h=harness("plastisch");
assert.equal(h.elements.get("refresh-page-info").attributes.title,"Refresh");
assert.equal(h.elements.get("refresh-page-info").attributes["aria-label"],"Refresh");
for(const id of ["chat-count","player-volume","speech-volume","limiter-strength","recommendation-limit","auto-chat-refresh-minutes"]) assert.equal(h.elements.has(id),false,`${id} must not receive a decorative icon`);
for(const [id,values] of [["player-play",["Play","Stop"]],["player-mute",["Mute","Unmute"]],["toggle-speech",["On","Off"]],["toggle-hook",["On","Off"]]]) for(const value of values){const el=h.elements.get(id);el.textContent=value;h.observer();assert.ok(el.attributes["aria-label"].endsWith(value));assert.ok(el.attributes.title.endsWith(value));}
const css=fs.readFileSync(path.join(root,"icon-controls.css"),"utf8");assert.match(css,/button\[data-control-icon\] \{[^}]*font-size:0/);
const sidepanel=fs.readFileSync(path.join(root,"sidepanel.js"),"utf8");assert.ok(!sidepanel.includes("von bis zu ${requested}"));
console.log("PASS: defaults, invalid stored style, three styles, persistence, 20 state combinations and 60 packaged asset hashes");
