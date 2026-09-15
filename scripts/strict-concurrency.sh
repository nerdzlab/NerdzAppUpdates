#!/bin/bash
# Build NerdzAppUpdates for the iOS Simulator under complete strict concurrency
# checking and fail if the compiler emits any concurrency warning.
#
# The library cannot build on the macOS host (UIKit + Firebase), so this uses
# xcodebuild against a generic iOS Simulator destination.
set -euo pipefail

SCHEME="NerdzAppUpdates"
DD=".build/dd-strict"
LOG="${LOG:-.build/strict-concurrency.log}"

echo "==> strict-concurrency build ($SCHEME)"
mkdir -p "$(dirname "$LOG")"
set +e
xcodebuild build \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DD" \
    -skipPackagePluginValidation \
    SWIFT_STRICT_CONCURRENCY=complete > "$LOG" 2>&1
STATUS=$?
set -e

if [ "$STATUS" -ne 0 ]; then
    echo "Build failed. Tail:" >&2
    tail -40 "$LOG" >&2
    exit "$STATUS"
fi

# Only count warnings from our own Sources, not from dependencies.
WARN=$(grep -E "NerdzAppUpdates/Sources/.*warning:" "$LOG" | grep -iE "concurrency|sendable|data race|actor-isolated|main actor" || true)
if [ -n "$WARN" ]; then
    echo "Strict concurrency warnings found:" >&2
    echo "$WARN" >&2
    exit 1
fi
echo "strict-concurrency clean"
