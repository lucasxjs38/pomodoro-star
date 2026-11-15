#!/bin/bash
# 将已构建的 .app 打包成 DMG（含「拖到应用程序」快捷方式）
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

APP_NAME="PomodoroStar"
VERSION="${1:-1.0.0}"
ARCH="$(uname -m)"
APP="build/${APP_NAME}.app"
DMG="build/${APP_NAME}-v${VERSION}-macOS-${ARCH}.dmg"
STAGE="build/dmg"

if [ ! -d "$APP" ]; then
  echo "缺少 $APP，请先运行 scripts/bundle.sh" >&2
  exit 1
fi

rm -rf "$STAGE" "$DMG"
mkdir -p "$STAGE"

ditto "$APP" "$STAGE/${APP_NAME}.app"
ln -s /Applications "$STAGE/Applications"

hdiutil create \
  -volname "番茄小星球" \
  -srcfolder "$STAGE" \
  -ov \
  -format UDZO \
  "$DMG"

rm -rf "$STAGE"
echo "已生成: $DMG"
