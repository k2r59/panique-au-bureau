#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
godot_bin=${GODOT_BIN:-/Applications/Godot.app/Contents/MacOS/Godot}
mkdir -p "$project_dir/build/web"
"$godot_bin" --headless --path "$project_dir" --editor --import
"$godot_bin" --headless --path "$project_dir" --export-release 'Web PWA'
