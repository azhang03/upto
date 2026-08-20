#!/bin/bash
# Runs the test suite. The Command Line Tools keep Swift Testing in a
# location that swift test does not search on its own, so this script
# passes the framework and library paths explicitly.
set -euo pipefail

cd "$(dirname "$0")/.."

FRAMEWORKS=/Library/Developer/CommandLineTools/Library/Developer/Frameworks
INTEROP=/Library/Developer/CommandLineTools/Library/Developer/usr/lib

swift test \
    -Xswiftc -F -Xswiftc "$FRAMEWORKS" \
    -Xlinker -F -Xlinker "$FRAMEWORKS" \
    -Xlinker -rpath -Xlinker "$FRAMEWORKS" \
    -Xlinker -rpath -Xlinker "$INTEROP" \
    "$@"
