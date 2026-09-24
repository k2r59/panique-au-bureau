import {test} from 'node:test';
import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
const base = 'http://127.0.0.1:8787';
const token = randomBytes(32).toString('hex');
async function call(path, method = 'GET', body, auth = token) {
  return fetch(base + '/api/' + path, {method, headers: {'Content-Type':'application/json', Authorization:'Bearer '+auth}, body: body === undefined ? undefined : JSON.stringify(body)});
}
test('profiles, isolated identity, best scores and validation', async () => {
  assert.equal((await call('health')).status, 200);
  assert.equal((await call('profile', 'GET', undefined, 'invalid')).status, 401);
  assert.equal((await call('profile')).status, 404);
  assert.equal((await call('profile', 'PUT', {name:'A',avatar:1})).status, 400);
  const created = await (await call('profile','PUT',{name:'Test local',avatar:5})).json();
  assert.equal(created.player.avatar, 5);
  assert.equal(created.player.token_hash, undefined);
  assert.equal((await call('score','POST',{score:-1})).status,400);
  assert.equal((await call('score','POST',{score:100001})).status,400);
  assert.equal((await (await call('score','POST',{score:450})).json()).player.score,450);
  assert.equal((await (await call('score','POST',{score:100})).json()).player.score,450);
  const renamed = await (await call('profile','PUT',{name:'Test modifié',avatar:3})).json();
  assert.equal(renamed.player.id,created.player.id);
  assert.equal(renamed.player.score,450);
  assert.equal((await call('profile','GET',undefined,randomBytes(32).toString('hex'))).status,404);
  const leaders = await (await call('leaderboard')).json();
  assert(leaders.players.some(p=>p.id===created.player.id && p.avatar===3 && p.score===450));
  assert(leaders.players.every(p=>!('token_hash' in p)));
  const foreign = await fetch(base+'/api/score',{method:'POST',headers:{Origin:'https://foreign.example','Content-Type':'application/json',Authorization:'Bearer '+token},body:'{"score":500}'});
  assert.equal(foreign.status,403);
  const large = await fetch(base+'/api/profile',{method:'PUT',headers:{'Content-Type':'application/json',Authorization:'Bearer '+token},body:'x'.repeat(3000)});
  assert.equal(large.status,413);
});
test('engine is decoded to WebAssembly exactly once', async () => {
  const response = await fetch(base + '/play/index.wasm');
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('content-type'), 'application/wasm');
  const bytes = new Uint8Array(await response.arrayBuffer());
  assert.deepEqual([...bytes.slice(0,4)], [0,97,115,109]);
});

test('root is blank and game is available at /play', async () => {
  const root = await (await fetch(base + '/')).text();
  assert(!root.includes('<canvas'));
  assert(root.includes('background:white'));
  const old = await (await fetch(base + '/index.html')).text();
  assert(!old.includes('<canvas'));
  const play = await (await fetch(base + '/play')).text();
  assert(play.includes('<canvas'));
  assert(play.includes('<base href="/play/">'));
});
