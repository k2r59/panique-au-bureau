const vm = require('node:vm');
const fs = require('node:fs');
const assert = require('node:assert/strict');
const listeners = {}, viewListeners = {}, frames = [];
const done = {style:{},hidden:true,setAttribute(){},addEventListener(n,f){this[n]=f}};
const canvas = { style: {}, width: 0, height: 0 };
const viewport = {height: 780, offsetTop: 0, addEventListener: (n,f) => viewListeners[n] = f};
const document = { createElement:()=>done, body:{append(){}}, activeElement: null, documentElement: {clientWidth: 390, style: {setProperty(){}}}, getElementById: id => id === 'canvas' ? canvas : null, addEventListener:(n,f)=>listeners[n]=f };
vm.runInNewContext(fs.readFileSync('web/viewport.js','utf8'), {window:{visualViewport:viewport,addEventListener(){}}, document, innerHeight:780, devicePixelRatio:3, requestAnimationFrame:f=>(frames.push(f),frames.length)});
const resize = height => {viewport.height=height;viewListeners.resize();while(frames.length)frames.shift()();};
assert.equal(canvas.height,2340);
document.activeElement={tagName:'INPUT',blur(){document.activeElement=null;}};listeners.focusin({target:document.activeElement});
for (const height of [775,760,730,700,650,440,410]) { resize(height); assert.equal(canvas.height,2340, "Preserve baseline during progressive keyboard opening"); }
assert.equal(canvas.height,2340,'Keyboard must not shrink Godot buffer');
assert.ok(parseFloat(canvas.style.top)<0,'Input is lifted above keyboard');
document.activeElement=null;listeners.focusout({target:{tagName:"INPUT"}});while(frames.length)frames.shift()();
resize(540);assert.equal(canvas.height,2340,'Keep baseline during keyboard dismissal');
resize(780);assert.equal(canvas.style.top,'0px');assert.equal(canvas.height,2340);
resize(730);assert.equal(canvas.height,2190,'Normal browser chrome resize still works');
document.activeElement={tagName:'INPUT',blur(){document.activeElement=null;}};
listeners.focusin({target:document.activeElement});resize(390);
assert.equal(done.hidden,false);
done.click();assert.equal(document.activeElement,null);assert.equal(done.hidden,true);
resize(730);assert.equal(canvas.style.top,'0px');
console.log('Viewport keyboard regression: PASS');
for (const key of ['Enter','Escape']) {
 document.activeElement={tagName:'INPUT',blur(){document.activeElement=null;}};
 listeners.focusin({target:document.activeElement});resize(390);
 let prevented=false;
 listeners.keydown({target:document.activeElement,key,isComposing:true,preventDefault(){throw Error('Composition interrupted')},stopImmediatePropagation(){}});
 assert.ok(document.activeElement,'Composition must keep input focused');
 listeners.keydown({target:document.activeElement,key,isComposing:false,preventDefault(){prevented=true},stopImmediatePropagation(){}});
 assert.equal(document.activeElement,null);assert.ok(prevented);resize(730);
}
console.log('Keyboard Enter/Escape/composition regression: PASS');
