#!/bin/bash
# volumio-rtlsdr-binaries scripts/build-binaries.sh
# Build dab-rtlsdr-3 and dab-scanner-3 binaries
# Runs inside Docker container

set -e

ARCH="$1"
if [ -z "$ARCH" ]; then
  echo "Usage: $0 <arch>"
  echo "  arch: armv6, armhf, arm64, amd64"
  exit 1
fi

echo "========================================"
echo "Building dab-cmdline binaries for $ARCH"
echo "========================================"
echo ""

SOURCE_DIR="/build/source/dab-cmdline"
BUILD_DIR="/build/build"
OUTPUT_DIR="/build/output"

if [ ! -d "$SOURCE_DIR" ]; then
  echo "[!] Source directory not found: $SOURCE_DIR"
  exit 1
fi

mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

# CXXFLAGS already set by run-docker-dab.sh
echo "    CXXFLAGS: $CXXFLAGS"
echo ""

# Build dab-rtlsdr-3 (example-3)
echo "[+] Building dab-rtlsdr-3 (example-3)..."
mkdir -p "$BUILD_DIR/example-3"
cd "$BUILD_DIR/example-3"
cmake "$SOURCE_DIR/example-3" -DRTLSDR=ON
make -j$(nproc)

if [ ! -f "dab-rtlsdr-3" ]; then
  echo "[!] Build failed: dab-rtlsdr-3 not found"
  exit 1
fi

strip dab-rtlsdr-3
cp dab-rtlsdr-3 "$OUTPUT_DIR/"
SIZE=$(stat -c%s "$OUTPUT_DIR/dab-rtlsdr-3")
echo "    Built: dab-rtlsdr-3 ($SIZE bytes)"
echo ""

# Build dab-scanner-3 (dab-scanner)
echo "[+] Building dab-scanner-3 (dab-scanner)..."
mkdir -p "$BUILD_DIR/dab-scanner"
cd "$BUILD_DIR/dab-scanner"
cmake "$SOURCE_DIR/dab-scanner" -DRTLSDR=ON
make -j$(nproc)

# Find the scanner binary (name may vary)
SCANNER_BIN=""
if [ -f "dab-scanner-rtlsdr" ]; then
  SCANNER_BIN="dab-scanner-rtlsdr"
elif [ -f "dab-scanner-3" ]; then
  SCANNER_BIN="dab-scanner-3"
elif [ -f "dab-scanner" ]; then
  SCANNER_BIN="dab-scanner"
fi

if [ -z "$SCANNER_BIN" ]; then
  echo "[!] Build failed: scanner binary not found"
  exit 1
fi

strip "$SCANNER_BIN"
cp "$SCANNER_BIN" "$OUTPUT_DIR/dab-scanner-3"
SIZE=$(stat -c%s "$OUTPUT_DIR/dab-scanner-3")
echo "    Built: dab-scanner-3 ($SIZE bytes)"
echo ""

echo "========================================"
echo "Build complete for $ARCH"
echo "========================================"
echo ""
echo "Output binaries in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"
