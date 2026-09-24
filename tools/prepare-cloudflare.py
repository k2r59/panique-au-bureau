"""Prepare only public web exports; gzip the Godot engine to fit the asset limit."""
from pathlib import Path
import gzip
import shutil
source = Path(__file__).resolve().parent.parent / 'build/web'
target = source.parent / 'cloudflare'
target.mkdir(parents=True, exist_ok=True)
for file in target.iterdir():
    if file.is_file():
        file.unlink()
for file in source.glob('index.*'):
    if file.suffix == '.wasm':
        (target / 'index.wasm.gz').write_bytes(gzip.compress(file.read_bytes(), compresslevel=9, mtime=0))
    elif file.suffix not in ('.tmp', '.import', '.uid'):
        shutil.copy2(file, target / file.name)
for file in target.iterdir():
    if file.stat().st_size > 25 * 1024 * 1024:
        raise SystemExit(f'Cloudflare asset exceeds 25 MiB: {file.name}')
print('Cloudflare web assets prepared.')
