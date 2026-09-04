#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="Finder Color Tagger"
BUILD_CONFIG="${1:-release}"
APP_DIR="$ROOT_DIR/build/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

cd "$ROOT_DIR"
swift build -c "$BUILD_CONFIG"

rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$CONTENTS_DIR/Resources"

cp ".build/$BUILD_CONFIG/FinderColorTagger" "$MACOS_DIR/FinderColorTagger"
cp "Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "Resources/ColorTagger.icns" "$CONTENTS_DIR/Resources/ColorTagger.icns"

chmod +x "$MACOS_DIR/FinderColorTagger"

echo "$APP_DIR"
