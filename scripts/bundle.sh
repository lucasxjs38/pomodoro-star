#!/bin/bash
# Build PomodoroStar and assemble build/PomodoroStar.app
set -euo pipefail

# Move to the package root (parent of this script's directory).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

swift build -c release

# Fixed path under build/ inside the package root.
APP="build/PomodoroStar.app"
rm -rf "$APP"

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp .build/release/PomodoroStar "$APP/Contents/MacOS/PomodoroStar"
chmod +x "$APP/Contents/MacOS/PomodoroStar"

# 图标：若 icon/AppIcon.icns 存在则一并打包
if [ -f icon/AppIcon.icns ]; then
  cp icon/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
fi

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>PomodoroStar</string>
  <key>CFBundleIdentifier</key><string>com.xujiashun.pomodorostar</string>
  <key>CFBundleName</key><string>番茄小星球</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>CFBundleIconFile</key><string>AppIcon</string>
</dict>
</plist>
PLIST

echo "Built $APP"
