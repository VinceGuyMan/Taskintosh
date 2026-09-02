#!/bin/bash
set -e

echo "==> Building Taskintosh..."
swift build -c release

echo "==> Build complete."
