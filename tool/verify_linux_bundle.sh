#!/usr/bin/env bash
set -euo pipefail

bundle="${1:-build/linux/x64/release/bundle}"

test -x "$bundle/ripme"
test -d "$bundle/lib"
test -f "$bundle/lib/libflutter_linux_gtk.so"
test -d "$bundle/data/flutter_assets"
test -f "$bundle/LICENSE.txt"
test -f "$bundle/share/applications/ripme.desktop"
test -f "$bundle/share/icons/hicolor/256x256/apps/ripme.png"
test -f "$bundle/share/metainfo/com.rarchives.ripme.metainfo.xml"

grep -Fxq 'Exec=ripme' "$bundle/share/applications/ripme.desktop"
grep -Fxq 'TryExec=ripme' "$bundle/share/applications/ripme.desktop"
grep -Fq '<binary>ripme</binary>' \
  "$bundle/share/metainfo/com.rarchives.ripme.metainfo.xml"

printf 'Linux release bundle verified: %s\n' "$bundle"
