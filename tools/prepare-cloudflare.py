"""Prepare only public web exports; gzip the Godot engine to fit the asset limit."""
from pathlib import Path
import gzip
import shutil
import json
source = Path(__file__).resolve().parent.parent / 'build/web'
target = source.parent / 'cloudflare'
target.mkdir(parents=True, exist_ok=True)
for file in target.iterdir():
    if file.is_dir():
        shutil.rmtree(file)
    else:
        file.unlink()
play = target / "play"
play.mkdir()
for file in source.glob('index.*'):
    if file.suffix == '.wasm':
        (play / 'index.wasm.gz').write_bytes(gzip.compress(file.read_bytes(), compresslevel=9, mtime=0))
    elif file.suffix not in ('.tmp', '.import', '.uid'):
        shutil.copy2(file, play / file.name)
html = play / 'index.html'
html.write_text(html.read_text().replace('<head>', '<head><base href="/play/"><meta name="robots" content="noindex,nofollow">', 1))
manifest = play / 'index.manifest.json'
data = json.loads(manifest.read_text())
data['start_url'] = '/play/'
data['scope'] = '/play/'
manifest.write_text(json.dumps(data))
# Retire the old root-scoped PWA without touching saved profiles in IndexedDB.
(target / 'index.service.worker.js').write_text("""self.addEventListener('install', () => self.skipWaiting());
self.addEventListener('activate', event => event.waitUntil((async () => {
 for (const key of await caches.keys()) if (key.startsWith('Panique au burea-sw-cache-')) await caches.delete(key);
 await self.registration.unregister();
 for (const client of await self.clients.matchAll({type:'window'})) {
  const url = new URL(client.url);
  if (url.pathname === '/' || url.pathname === '/index.html') await client.navigate('/');
 }
})()));""")
(target / 'robots.txt').write_text('User-agent: *\nDisallow: /\n')
for file in target.rglob('*'):
    if file.is_file() and file.stat().st_size > 25 * 1024 * 1024:
        raise SystemExit(f'Cloudflare asset exceeds 25 MiB: {file.name}')
print('Cloudflare web assets prepared.')
