#!/bin/bash
set -euo pipefail

PROJECT="OneStep.xcodeproj"
SCHEME="OneStep"
CONFIG="Release"
BUILD_DIR=".build"
DIST_DIR="dist"
PBXPROJ="$PROJECT/project.pbxproj"
BUILD_LOG="$DIST_DIR/xcodebuild.log"

cd "$(dirname "$0")/.."

# Version handling
if [ -n "${1:-}" ]; then
  if [[ ! "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: version must use numeric MAJOR.MINOR.PATCH format, for example 0.0.3" >&2
    exit 1
  fi

  VERSION="$1"
else
  VERSION=$(grep -m1 'MARKETING_VERSION' "$PBXPROJ" | sed 's/.*= //;s/;//')
  echo "==> Using project version: $VERSION"
fi

if ! command -v create-dmg >/dev/null 2>&1; then
  echo "Error: create-dmg is required. Install it before running this release script." >&2
  exit 1
fi

if [ -n "${1:-}" ]; then
  echo "==> Setting version to $1..."
  sed -i '' "s/MARKETING_VERSION = [^;]*;/MARKETING_VERSION = $1;/g" "$PBXPROJ"
fi

echo "==> Cleaning old build artifacts..."
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "==> Building $SCHEME ($CONFIG)..."
xcodebuild -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration "$CONFIG" \
  -derivedDataPath "$BUILD_DIR" \
  clean build \
  2>&1 | tee "$BUILD_LOG"

APP_PATH="$BUILD_DIR/Build/Products/$CONFIG/OneStep.app"
if [ ! -d "$APP_PATH" ]; then
  echo "Error: OneStep.app not found at $APP_PATH" >&2
  exit 1
fi

DMG_NAME="OneStep-$VERSION.dmg"

echo "==> Creating DMG: $DMG_NAME"
create-dmg \
  --volname "OneStep" \
  --window-pos 200 120 \
  --window-size 600 400 \
  --icon-size 100 \
  --icon "OneStep.app" 150 200 \
  --app-drop-link 450 200 \
  "$DIST_DIR/$DMG_NAME" \
  "$APP_PATH"

echo "==> Done: $DIST_DIR/$DMG_NAME"
