#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
port=${PORT:-8765}
printf 'Ouvrir http://localhost:%s\n' "$port"
exec python3 -m http.server "$port" --bind 127.0.0.1 --directory "$project_dir/build/web"
