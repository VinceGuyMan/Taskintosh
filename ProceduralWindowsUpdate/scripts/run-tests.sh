#!/bin/bash
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH_DIR="/tmp/pwu-scratch"

echo "Building and running ProceduralWindowsUpdate Test Suite..."
swift build --package-path "$DIR" --scratch-path "$SCRATCH_DIR" --disable-sandbox
"$SCRATCH_DIR/out/Products/Debug/ProceduralWindowsUpdateTestRunner"
