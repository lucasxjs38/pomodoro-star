#!/bin/bash
# 从 icon-1024.png 生成 macOS AppIcon.icns
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC="$ROOT/icon/icon-1024.png"
ICONSET="$ROOT/icon/AppIcon.iconset"
OUT="$ROOT/icon/AppIcon.icns"

if [ ! -f "$SRC" ]; then
  echo "缺少源图: $SRC" >&2
  exit 1
fi

rm -rf "$ICONSET"
mkdir -p "$ICONSET"

emit() {
  local size="$1"
  local name="$2"
  sips -z "$size" "$size" "$SRC" --out "$ICONSET/$name" >/dev/null
}

emit 16   icon_16x16.png
emit 32   icon_16x16@2x.png
emit 32   icon_32x32.png
emit 64   icon_32x32@2x.png
emit 128  icon_128x128.png
emit 256  icon_128x128@2x.png
emit 256  icon_256x256.png
emit 512  icon_256x256@2x.png
emit 512  icon_512x512.png
emit 1024 icon_512x512@2x.png

iconutil -c icns "$ICONSET" -o "$OUT"
echo "已生成: $OUT"
ls -1 "$ICONSET"
