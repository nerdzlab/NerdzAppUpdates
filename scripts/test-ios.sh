#!/bin/bash
# Build and run the NerdzAppUpdates test suite on an iOS Simulator.
# This library imports UIKit and Firebase, so it cannot be built or tested on
# the macOS host via `swift test`. Tests run on a simulator via xcodebuild.
#
# `xcodebuild test` with a concrete destination fails on this bare SPM library
# scheme ("Supported platforms ... is empty"), so we split into build-for-testing
# (generic destination) then test-without-building (concrete simulator).
#
# Optional env:
#   SIM_NAME   simulator device name (default "iPhone 16 Pro")
#   COVERAGE   set to 1 to enable code coverage
set -euo pipefail

SCHEME="NerdzAppUpdates"
DD=".build/dd"
SIM_NAME="${SIM_NAME:-iPhone 16 Pro}"
COV_FLAG=""
if [ "${COVERAGE:-0}" = "1" ]; then
    COV_FLAG="-enableCodeCoverage YES"
fi

echo "==> build-for-testing ($SCHEME, generic iOS Simulator)"
# shellcheck disable=SC2086
xcodebuild build-for-testing \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DD" \
    -skipPackagePluginValidation \
    $COV_FLAG

SIM_ID=$(xcrun simctl list devices available | grep "$SIM_NAME (" | head -1 | grep -oE '[0-9A-Fa-f-]{36}')
if [ -z "$SIM_ID" ]; then
    echo "No available simulator named '$SIM_NAME'." >&2
    exit 1
fi
echo "==> booting $SIM_NAME ($SIM_ID)"
xcrun simctl boot "$SIM_ID" 2>/dev/null || true

echo "==> test-without-building on $SIM_NAME"
# shellcheck disable=SC2086
xcodebuild test-without-building \
    -scheme "$SCHEME" \
    -destination "platform=iOS Simulator,id=$SIM_ID" \
    -derivedDataPath "$DD" \
    -skipPackagePluginValidation \
    $COV_FLAG
