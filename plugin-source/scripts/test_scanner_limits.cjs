"use strict";
const assert = require("node:assert/strict"), fs = require("node:fs"), path = require("node:path"), vm = require("node:vm");
const root=path.resolve(__dirname,"..");
const sources=[
 ["browser-extension/content.js", "  function explicitCardSummary", true],
 ["mobile-shared/webview-bridge.js", "  function primaryVideo", false]
];
(async()=>{
 for(const [file,end,browser] of sources){
  const source=fs.readFileSync(path.join(root,file),"utf8");
  const code=source.slice(source.indexOf("  async function scanRecommendations(run)"), source.indexOf(end,source.indexOf("  async function scanRecommendations(run)")));
  assert.ok(code.length>100);
  for(const n of [1,50,51,299,300,301]){
   const updates=[],cards=Array.from({length:301},(_,i)=>({handle:"creator"+i,card:{scrollIntoView(){},dispatchEvent(){}}}));
   const run={limit:Math.min(n,300),sourceUrl:"https://www.tiktok.com/@creator/live",runId:"test",cancelled:false};
   const context=vm.createContext({root:{},scrollX:0,scrollY:0,innerHeight:800,location:{href:run.sourceUrl},Date,MouseEvent:class{},setTimeout:fn=>{fn();return 1;},
    window:{scrollX:0,scrollY:0,innerHeight:800,scrollTo(){},scrollBy(){}}, scrollTo(){},scrollBy(){}, activeRecommendationScan:run,
    RECOMMENDATION_SCAN_MAX_ROUNDS:12,RECOMMENDATION_SCAN_MAX_MS:45000,core:require(path.join(root,"browser-extension/content-core.js")),
    recommendationCards:()=>cards,recommendationItem:(e,p)=>({handle:e.handle,position:p,title:"x".repeat(300)}),text:String,
    emit:(type,p)=>updates.push(structuredClone(p)),emitRecommendationProgress:async(r,status,items)=>updates.push(structuredClone({status,items}))});
   vm.runInContext(code,context);await context.scanRecommendations(run);
   assert.equal(updates.at(-1).status,"complete");assert.equal(updates.at(-1).items.length,Math.min(n,300));
   assert.equal(updates.at(-1).items.at(-1).position,Math.min(n,300));
  }
  console.log("PASS synthetic production scan loop: "+file+"; 1,50,51,299,300,301");
 }
})();
