#!/bin/bash
# Builds Pomodoro.app into ./build using Swift Package Manager (no Xcode required).
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Pomodoro.app"
swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$(swift build -c release --show-bin-path)/Pomodoro" "$APP/Contents/MacOS/Pomodoro"

# Regenerate the icon if it's missing or the drawing script changed.
if [[ ! -f Resources/AppIcon.icns || scripts/make-icon.swift -nt Resources/AppIcon.icns ]]; then
    mkdir -p Resources
    swift scripts/make-icon.swift Resources/AppIcon.icns
fi
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Pomodoro</string>
    <key>CFBundleDisplayName</key><string>Pomodoro</string>
    <key>CFBundleIdentifier</key><string>com.lawrencewu.pomodoro</string>
    <key>CFBundleExecutable</key><string>Pomodoro</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"
echo "Built $APP"
