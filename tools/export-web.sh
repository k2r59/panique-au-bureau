#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
godot_bin=${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}
mkdir -p "$project_dir/build/web"
"$godot_bin" --headless --path "$project_dir" --editor --import
"$godot_bin" --headless --path "$project_dir" --export-release 'Web PWA'

cp "$project_dir/web/install.js" "$project_dir/build/web/index.install.js"
cp "$project_dir/web/install.css" "$project_dir/build/web/index.install.css"
cp "$project_dir/web/update.js" "$project_dir/build/web/index.update.js"
cp "$project_dir/web/viewport.js" "$project_dir/build/web/index.viewport.js"
python3 - "$project_dir/build/web/index.service.worker.js" <<'PY'
import sys
from pathlib import Path
p = Path(sys.argv[1])
s = p.read_text().replace('const CACHED_FILES = [', 'const CACHED_FILES = ["index.update.js","index.viewport.js","index.install.js","index.install.css",', 1)
old = 'event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES)));'
assert old in s, 'Godot service worker install hook changed'
s = s.replace(old, "event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(FULL_CACHE.map(file => new Request(file, {cache: 'reload'})))).then(() => self.skipWaiting()));")
old = "// Enable navigation preload if available."
assert old in s
s = s.replace(old, "await self.clients.claim();\n\t\t" + old).replace(
    ").then(function () {", ").then(async function () {", 1)
p.write_text(s)
PY
