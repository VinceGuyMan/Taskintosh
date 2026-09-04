#!/bin/bash
set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRATCH_DIR="/tmp/pwu-scratch"

echo "Building and launching FakeUpdatePreview standalone runner..."
swift build --package-path "$DIR" --scratch-path "$SCRATCH_DIR" --disable-sandbox
echo "Launching preview GUI..."
"$SCRATCH_DIR/out/Products/Debug/FakeUpdatePreview" &
