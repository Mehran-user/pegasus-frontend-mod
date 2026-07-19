#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/build"

echo "==> Initializing git submodules..."
cd "$SCRIPT_DIR"
git submodule update --init

echo "==> Configuring build..."
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
qmake .. 2>&1 | tee "$BUILD_DIR/build.log"

echo "==> Building ($(nproc) cores)..."
make -j"$(nproc)" 2>&1 | tee -a "$BUILD_DIR/build.log"

echo "==> Build complete! Running pegasus-fe..."
cd "$SCRIPT_DIR"
./build/src/app/pegasus-fe
