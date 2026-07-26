#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INFO_PLIST="$PROJECT_ROOT/StudyBlock/Resources/Info.plist"
APP_NAME="Study Block"
VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")"
APP_BUNDLE="$PROJECT_ROOT/.build/Release/$APP_NAME.app"
OUTPUT_DMG="$PROJECT_ROOT/dist/Study-Block-$VERSION.dmg"
STAGING_DIR="$(mktemp -d "${TMPDIR:-/tmp}/study-block-release.XXXXXX")"
SKIP_BUILD=false

if [[ "${1:-}" == "--skip-build" ]]; then
  SKIP_BUILD=true
elif [[ $# -gt 0 ]]; then
  echo "usage: $0 [--skip-build]" >&2
  exit 2
fi

cleanup() {
  rm -rf "$STAGING_DIR"
}
trap cleanup EXIT

if [[ "$SKIP_BUILD" == false ]]; then
  "$PROJECT_ROOT/script/build_and_run.sh" --release --verify
fi

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Release app not found at $APP_BUNDLE" >&2
  exit 1
fi

mkdir -p "$PROJECT_ROOT/dist"
cp -R "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

rm -f "$OUTPUT_DMG"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  "$OUTPUT_DMG"
hdiutil verify "$OUTPUT_DMG"

printf '%s\n' "$OUTPUT_DMG"
