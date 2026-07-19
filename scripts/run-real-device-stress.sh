#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/LiShangJi/LiShangJi.xcodeproj"
DEVICE_ID="${DEVICE_ID:-00008110-000A2D043C8A401E}"
DURATION_SECONDS="${DURATION_SECONDS:-7200}"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-/tmp/lsj-upgrade-test/dd-candidate-1205-iphone14-final-r2}"
RESULT_ROOT="${RESULT_ROOT:-/tmp/lsj-upgrade-test/stress-2026071205-iphone14}"

mkdir -p "$RESULT_ROOT"

started_at="$(date +%s)"
deadline="$((started_at + DURATION_SECONDS))"
iteration=0

while (( $(date +%s) < deadline )); do
    iteration="$((iteration + 1))"
    result_path="$RESULT_ROOT/iteration-$(printf '%03d' "$iteration").xcresult"
    echo "STRESS iteration=$iteration started=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

    xcodebuild -quiet test-without-building \
        -project "$PROJECT" \
        -scheme LiShangJi \
        -configuration Debug \
        -destination "platform=iOS,id=$DEVICE_ID" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        -resultBundlePath "$result_path" \
        -only-testing:LiShangJiUITests \
        -allowProvisioningUpdates

    xcrun xcresulttool get test-results summary --path "$result_path"
done

finished_at="$(date +%s)"
echo "STRESS completed iterations=$iteration elapsed_seconds=$((finished_at - started_at))"
