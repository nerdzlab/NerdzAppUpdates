#!/bin/bash
# Build NerdzAppUpdates under complete strict concurrency checking and fail if the
# compiler emits ANY diagnostic for this package's own sources.
#
# Equivalent of the `swift build --build-tests -Xswiftc -strict-concurrency=complete`
# gate used by the other libraries in this organization. This package is iOS only
# (UIKit + Firebase), so it cannot build on the macOS host and uses xcodebuild with
# SWIFT_STRICT_CONCURRENCY=complete instead.
#
# The package targets swift-tools-version 5.9, so Swift 6 concurrency violations are
# reported as warnings rather than errors and xcodebuild still exits 0. The gate is
# therefore the log scan below, not the xcodebuild exit status alone.
#
# Two rules keep this honest:
#   1. Fail on any warning, not on a hand-maintained keyword allowlist. Diagnostic
#      wording drifts (for example "concurrently-executing code" never contained the
#      substring "concurrency"), so an allowlist silently stops matching.
#   2. Always build from a clean derived data directory. An incremental build reuses
#      cached object files and re-emits nothing, which hides every existing warning.
#
# Diagnostics are scoped to "$PWD/Sources/" so dependency checkouts, which live under
# "$DD/SourcePackages/checkouts/", are never counted and never "fixed".
set -euo pipefail

SCHEME="NerdzAppUpdates"
DD=".build/dd-strict"
LOG="${LOG:-.build/strict-concurrency.log}"
DESTINATION="${DESTINATION:-generic/platform=iOS}"
OWN_SOURCES="$PWD/Sources/"

echo "==> strict-concurrency build ($SCHEME, $DESTINATION)"
mkdir -p "$(dirname "$LOG")"
rm -rf "$DD"

set +e
xcodebuild build \
    -scheme "$SCHEME" \
    -destination "$DESTINATION" \
    -derivedDataPath "$DD" \
    -skipPackagePluginValidation \
    SWIFT_STRICT_CONCURRENCY=complete \
    CODE_SIGNING_ALLOWED=NO > "$LOG" 2>&1
STATUS=$?
set -e

if [ "$STATUS" -ne 0 ]; then
    echo "Build failed. Tail:" >&2
    tail -40 "$LOG" >&2
    exit "$STATUS"
fi

DIAGNOSTICS=$(grep -E "^${OWN_SOURCES}.*: (warning|error): " "$LOG" | sort -u || true)
if [ -n "$DIAGNOSTICS" ]; then
    COUNT=$(printf '%s\n' "$DIAGNOSTICS" | wc -l | tr -d ' ')
    echo "Strict concurrency build produced $COUNT diagnostic(s) in $OWN_SOURCES:" >&2
    printf '%s\n' "$DIAGNOSTICS" | sed "s|${OWN_SOURCES}|Sources/|" >&2
    exit 1
fi

echo "strict-concurrency clean"
