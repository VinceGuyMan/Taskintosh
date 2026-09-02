#!/bin/bash
cd "$(dirname "$0")"
./scripts/package-app.sh
echo "==> Launching Taskintosh..."
open build/Taskintosh.app
