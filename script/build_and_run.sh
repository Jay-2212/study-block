#!/usr/bin/env bash
set -euo pipefail

MODE="run"
CONFIGURATION="Debug"
APP_NAME="Study Block"
PROJECT_NAME="StudyBlock"
BUNDLE_ID="com.jay.studyblock"

for argument in "$@"; do
  case "$argument" in
    run|--debug|debug|--logs|logs|--telemetry|telemetry|--verify|verify)
      MODE="$argument"
      ;;
    --release|release)
      CONFIGURATION="Release"
      ;;
    *)
      echo "usage: $0 [run|--debug|--logs|--telemetry|--verify] [--release]" >&2
      exit 2
      ;;
  esac
done

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_PATH="$PROJECT_ROOT/StudyBlock.xcodeproj"
LOCAL_BUILD_DIR="$PROJECT_ROOT/.build"
DERIVED_DATA_DIR="$LOCAL_BUILD_DIR/DerivedData"
FALLBACK_APP="$LOCAL_BUILD_DIR/$CONFIGURATION/$APP_NAME.app"

running_dev_pids() {
  /usr/bin/osascript -l JavaScript - "$BUNDLE_ID" "$LOCAL_BUILD_DIR" <<'JXA'
ObjC.import("AppKit");

function run(arguments) {
  const bundleIdentifier = arguments[0];
  const buildRoot = arguments[1].replace(/\/+$/, "");
  return $.NSRunningApplication
    .runningApplicationsWithBundleIdentifier(bundleIdentifier)
    .js
    .filter((application) => {
      const bundleURL = application.bundleURL;
      return bundleURL && bundleURL.path.js.startsWith(`${buildRoot}/`);
    })
    .map((application) => application.processIdentifier)
    .join("\n");
}
JXA
}

stop_running_dev_instances() {
  local pids
  pids="$(running_dev_pids)"
  [[ -z "$pids" ]] && return

  /usr/bin/osascript -l JavaScript - "$BUNDLE_ID" "$LOCAL_BUILD_DIR" <<'JXA'
ObjC.import("AppKit");

function run(arguments) {
  const bundleIdentifier = arguments[0];
  const buildRoot = arguments[1].replace(/\/+$/, "");
  const applications = $.NSRunningApplication
    .runningApplicationsWithBundleIdentifier(bundleIdentifier)
    .js
    .filter((application) => {
      const bundleURL = application.bundleURL;
      return bundleURL && bundleURL.path.js.startsWith(`${buildRoot}/`);
    });

  for (const application of applications) {
    if (!application.terminate) {
      throw new Error(
        `Study Block dev process ${application.processIdentifier} refused to quit.`,
      );
    }
  }
}
JXA

  for _ in {1..20}; do
    [[ -z "$(running_dev_pids)" ]] && return
    sleep 0.25
  done

  echo "A Study Block dev instance did not quit cleanly; refusing to force-kill it." >&2
  exit 1
}

stop_running_dev_instances

resolve_xcode_developer_dir() {
  if xcodebuild -version >/dev/null 2>&1; then
    xcode-select -p
    return
  fi

  local candidate
  for candidate in /Applications/Xcode.app /Applications/Xcode-beta.app; do
    if [[ -x "$candidate/Contents/Developer/usr/bin/xcodebuild" ]]; then
      printf '%s\n' "$candidate/Contents/Developer"
      return
    fi
  done
  return 1
}

build_with_xcode() {
  local developer_dir="$1"
  DEVELOPER_DIR="$developer_dir" xcodebuild \
    -project "$PROJECT_PATH" \
    -scheme "$PROJECT_NAME" \
    -configuration "$CONFIGURATION" \
    -destination "platform=macOS" \
    -derivedDataPath "$DERIVED_DATA_DIR" \
    build
  APP_BUNDLE="$DERIVED_DATA_DIR/Build/Products/$CONFIGURATION/$APP_NAME.app"
  APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"
}

build_with_command_line_tools() {
  local sdk_path
  sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
  APP_BUNDLE="$FALLBACK_APP"
  APP_BINARY="$APP_BUNDLE/Contents/MacOS/$APP_NAME"

  rm -rf "$APP_BUNDLE"
  mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources"
  cp "$PROJECT_ROOT/StudyBlock/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
  cp "$PROJECT_ROOT/StudyBlock/Resources/StudyBlock.icns" \
    "$APP_BUNDLE/Contents/Resources/StudyBlock.icns"
  /usr/libexec/PlistBuddy \
    -c "Add :CFBundleIconFile string StudyBlock.icns" \
    "$APP_BUNDLE/Contents/Info.plist"

  local sources=()
  while IFS= read -r source; do
    sources+=("$source")
  done < <(find "$PROJECT_ROOT/StudyBlock" -name '*.swift' -type f | sort)

  local optimization_flags=()
  if [[ "$CONFIGURATION" == "Release" ]]; then
    optimization_flags=(-O -whole-module-optimization)
  else
    optimization_flags=(-Onone)
  fi

  xcrun swiftc \
    -parse-as-library \
    -sdk "$sdk_path" \
    -target arm64-apple-macos15.0 \
    "${optimization_flags[@]}" \
    -framework AppKit \
    -framework SwiftUI \
    -framework Foundation \
    -framework Charts \
    "${sources[@]}" \
    -o "$APP_BINARY"

  codesign --force --sign - \
    --entitlements "$PROJECT_ROOT/StudyBlock/Resources/StudyBlock.entitlements" \
    "$APP_BUNDLE" >/dev/null
}

if developer_dir="$(resolve_xcode_developer_dir)"; then
  build_with_xcode "$developer_dir"
else
  echo "Xcode is not installed; using the Command Line Tools fallback." >&2
  build_with_command_line_tools
fi

open_app() {
  /usr/bin/open "$APP_BUNDLE"
}

verify_dev_instance() {
  for _ in {1..20}; do
    if [[ -n "$(running_dev_pids)" ]]; then
      echo "$APP_NAME launched successfully from $APP_BUNDLE."
      return
    fi
    sleep 0.25
  done
  echo "$APP_NAME did not launch from $APP_BUNDLE." >&2
  exit 1
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BINARY"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    verify_dev_instance
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify] [--release]" >&2
    exit 2
    ;;
esac
