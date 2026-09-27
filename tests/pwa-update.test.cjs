const {test} = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
test('update reloads home but preserves game and profile; first install does not reload', () => {
 for (const initial of [false,true]) {
  const listeners = {}, swEvents = {}; let reloads=0;
  const sw = {controller:initial?{}:null,addEventListener:(n,f)=>swEvents[n]=f,ready:new Promise(()=>{})};
  vm.runInNewContext(fs.readFileSync('web/update.js','utf8'), {navigator:{serviceWorker:sw},document:{hidden:false,addEventListener(){}},addEventListener:(n,f)=>listeners[n]=f,location:{reload(){reloads++}},Date});
  listeners['panique-screen']({detail:'game'});swEvents.controllerchange();assert.equal(reloads,0);
  listeners['panique-screen']({detail:'profile'});assert.equal(reloads,0);
  listeners['panique-screen']({detail:'home'});assert.equal(reloads,initial?1:0);
 }
});
test('worker activates only after all assets cache successfully, then claims clients', async () => {
 const source=fs.readFileSync('build/web/index.service.worker.js','utf8');
 for (const fail of [false,true]) {
  const handlers={};let skipped=false,claimed=false,files=[];
  vm.runInNewContext(source,{self:{addEventListener:(n,f)=>handlers[n]=f,skipWaiting:async()=>{skipped=true},clients:{claim:async()=>{claimed=true}},registration:{}},caches:{open:async()=>({addAll:async list=>{files=list;if(fail)throw Error('offline')}}),keys:async()=>[]},Request:class {constructor(url,options){this.url=url;this.cache=options.cache}}});
  let work;handlers.install({waitUntil:p=>work=p});
  if(fail){await assert.rejects(work);assert.equal(skipped,false);continue;}
  await work;assert.equal(skipped,true);
  assert.ok(files.some(f=>f.url==='index.pck'));assert.ok(files.some(f=>f.url==='index.wasm'));assert.ok(files.every(f=>f.cache==='reload'));
  handlers.activate({waitUntil:p=>work=p});await work;assert.equal(claimed,true);
 }
});
