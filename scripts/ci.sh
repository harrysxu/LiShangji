#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/LiShangJi/LiShangJi.xcodeproj"
SCHEME="LiShangJi"
DESTINATION="${DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"

xcodebuild -version
xcodebuild build -project "$PROJECT" -scheme "$SCHEME" \
  -destination "generic/platform=iOS Simulator" CODE_SIGNING_ALLOWED=NO
xcodebuild test -project "$PROJECT" -scheme "$SCHEME" \
  -destination "$DESTINATION" CODE_SIGNING_ALLOWED=NO
xcodebuild archive -project "$PROJECT" -scheme "$SCHEME" \
  -destination "generic/platform=iOS" -archivePath "$ROOT/build/LiShangJi.xcarchive" \
  CODE_SIGNING_ALLOWED=NO SKIP_INSTALL=NO
