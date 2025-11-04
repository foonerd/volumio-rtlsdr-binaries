#!/bin/bash
# volumio-rtlsdr-binaries build-matrix.sh
# Builds dab-cmdline binaries for all supported architectures

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

VERBOSE=""
if [ "$1" = "--verbose" ] || [ "$1" = "-v" ]; then
  VERBOSE="--verbose"
fi

echo "========================================"
echo "volumio-rtlsdr-binaries build matrix"
echo "========================================"
echo ""

# Clone source if not present
if [ ! -d "source/dab-cmdline" ]; then
  echo "[+] Cloning dab-cmdline source..."
  ./scripts/clone-source.sh
  echo ""
fi

# Build all architectures
ARCHS="armv6 armhf arm64 amd64"

for ARCH in $ARCHS; do
  echo "[+] Building for: $ARCH"
  ./docker/run-docker-dab.sh dab $ARCH $VERBOSE
  echo ""
done

echo "========================================"
echo "Build matrix complete"
echo "========================================"
echo ""
echo "Output binaries:"
for ARCH in $ARCHS; do
  echo "  out/$ARCH/"
  if [ -f "out/$ARCH/dab-rtlsdr-3" ]; then
    SIZE=$(stat -f%z "out/$ARCH/dab-rtlsdr-3" 2>/dev/null || stat -c%s "out/$ARCH/dab-rtlsdr-3" 2>/dev/null || echo "?")
    echo "    dab-rtlsdr-3 ($SIZE bytes)"
  fi
  if [ -f "out/$ARCH/dab-scanner-3" ]; then
    SIZE=$(stat -f%z "out/$ARCH/dab-scanner-3" 2>/dev/null || stat -c%s "out/$ARCH/dab-scanner-3" 2>/dev/null || echo "?")
    echo "    dab-scanner-3 ($SIZE bytes)"
  fi
done
echo ""
