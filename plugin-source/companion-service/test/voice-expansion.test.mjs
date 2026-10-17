import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs/promises';
import os from 'node:os';
import path from 'node:path';
import {listVoiceCatalog,listSherpaVoices} from '../server.mjs';

const catalogPath=new URL('../voice-catalog.json',import.meta.url);
test('voice expansion adds three per script and five distinct styles while preserving existing IDs',async()=>{
 const {voices}=JSON.parse(await fs.readFile(catalogPath));
 const baseline=JSON.parse(await fs.readFile(new URL('./voice-ids-build16.json',import.meta.url)));
 const ids=voices.map(v=>v.id);
 assert.equal(new Set(ids).size,ids.length);
 for(const id of baseline)assert.ok(ids.includes(id),id);
 const added=voices.filter(v=>!baseline.includes(v.id));
 assert.equal(added.length,17);
 for(const group of ['Kyrillisch','Asiatisch','Abjad','Indisch'])assert.equal(added.filter(v=>v.group===group).length,3);
 const styles=added.filter(v=>v.group==='Effekt Stimmen');
 assert.deepEqual(styles.map(v=>v.sid),[5,6,7,8,9]);
 assert.deepEqual(styles.map(v=>v.name),['Stil 1','Stil 2','Stil 3','Stil 4','Stil 5']);
 assert.equal(new Set(added.filter(v=>v.family==='supertonic').map(v=>v.model)).size,1);
 for(const v of added){assert.match(v.sha256,/^[a-f0-9]{64}$/);assert.ok(v.bytes>0);assert.ok(v.license.source.startsWith('https://'));assert.ok(v.sid>=0&&v.sid<v.speakers);}
});
test('catalog and installed answers retain optional group and accept older configurations',async(t)=>{
 const dir=await fs.mkdtemp(path.join(os.tmpdir(),'tlc-voice-group-'));t.after(()=>fs.rm(dir,{recursive:true,force:true}));
 const config=path.join(dir,'voices.json');
 await fs.writeFile(config,JSON.stringify({voices:[{id:'old',name:'Old',modelDir:dir},{id:'new',name:'Style',group:'Effekt Stimmen',modelDir:dir}]}));
 const installed=await listSherpaVoices(config);
 assert.equal(installed[0].group,'');assert.equal(installed[1].group,'Effekt Stimmen');
 const catalog=await listVoiceCatalog(catalogPath,async()=>[{id:'sherpa-de-supertonic-5'}]);
 assert.equal(catalog.find(v=>v.id==='sherpa-de-supertonic-5').group,'Effekt Stimmen');
 assert.equal(catalog.find(v=>v.id==='sherpa-de-supertonic-5').installed,true);
});
