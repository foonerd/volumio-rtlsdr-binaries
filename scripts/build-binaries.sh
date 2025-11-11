#!/bin/bash
# volumio-rtlsdr-binaries build-binaries.sh
# Builds dab-cmdline binaries for specified architecture

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

# Patch upstream source (run once)
echo "[+] Patching upstream source..."
PATCH_MARKER="$SOURCE_DIR/.volumio_patched"
if [ ! -f "$PATCH_MARKER" ]; then
  # Remove -fsanitize=address and debug flags
  sed -i 's/-fsanitize=address//g' "$SOURCE_DIR/example-3/CMakeLists.txt"
  sed -i 's/ -g / /g' "$SOURCE_DIR/example-3/CMakeLists.txt"
  sed -i 's/-fsanitize=address//g' "$SOURCE_DIR/dab-scanner/CMakeLists.txt"
  sed -i 's/ -g / /g' "$SOURCE_DIR/dab-scanner/CMakeLists.txt"

  # CRITICAL FIX: Redirect all stdout debug output to stderr
  # This prevents debug messages from corrupting the PCM audio stream on stdout
  echo "    Redirecting debug output from stdout to stderr..."

  # Find and patch ALL C/C++ source files
  find "$SOURCE_DIR" \( -name "*.cpp" -o -name "*.c" \) -type f | while read -r file; do
    # Replace fprintf(stdout, with fprintf(stderr,
    sed -i 's/fprintf[[:space:]]*([[:space:]]*stdout[[:space:]]*,/fprintf(stderr,/g' "$file"
    # Replace standalone printf( with fprintf(stderr,
    sed -i '/fprintf/!s/printf[[:space:]]*(/fprintf(stderr, /g' "$file"
  done

  # Fix DEBUG_PRINT macros in device-handler.h files
  find "$SOURCE_DIR" -name "device-handler.h" -type f | while read -r file; do
    sed -i 's/printf(__VA_ARGS__);/fprintf(stderr, __VA_ARGS__);/g' "$file"
  done

  echo "    Patched $(find "$SOURCE_DIR" \( -name "*.cpp" -o -name "*.c" \) -type f | wc -l) source files"
  touch "$PATCH_MARKER"
  echo "    Source patched: ASan removed, debug output redirected to stderr"
else
  echo "    Source already patched"
fi

# Apply arm64-specific pthread fix (separate from ASan patching)
if [ "$ARCH" = "arm64" ]; then
  ARM64_MARKER="$SOURCE_DIR/.volumio_arm64_pthread"
  if [ ! -f "$ARM64_MARKER" ]; then
    echo "    Applying arm64-specific pthread fix"
    sed -i '/find_library (PTHREADS pthread)/a set(PTHREADS "pthread")' "$SOURCE_DIR/example-3/CMakeLists.txt"
    sed -i '/find_library (PTHREADS pthread)/a set(PTHREADS "pthread")' "$SOURCE_DIR/dab-scanner/CMakeLists.txt"
    touch "$ARM64_MARKER"
  fi
fi
echo ""

mkdir -p "$BUILD_DIR"
mkdir -p "$OUTPUT_DIR"

# Build configuration (set by run-docker-dab.sh)
echo "    CXXFLAGS: $CXXFLAGS"
echo "    CMAKE_TRIPLET: $CMAKE_TRIPLET"
echo "    CMAKE_PROCESSOR: $CMAKE_PROCESSOR"
echo ""

# Build dab-rtlsdr-3 (example-3)
echo "[+] Building dab-rtlsdr-3 (example-3)..."
mkdir -p "$BUILD_DIR/example-3"
cd "$BUILD_DIR/example-3"

# CMake with explicit configuration
if [ "$ARCH" = "arm64" ]; then
  # arm64 requires explicit library paths due to broken CMake FindModules
  cmake "$SOURCE_DIR/example-3" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR="$CMAKE_PROCESSOR" \
    -DCMAKE_C_COMPILER=/usr/bin/gcc \
    -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
    -DRTLSDR=ON \
    -DFFTW3F_INCLUDE_DIR=/usr/include \
    -DFFTW3F_LIBRARIES=/usr/lib/aarch64-linux-gnu/libfftw3f.so \
    -DFAAD_INCLUDE_DIR=/usr/include \
    -DFAAD_LIBRARY=/usr/lib/aarch64-linux-gnu/libfaad.so \
    -DLIBSAMPLERATE_INCLUDE_DIR=/usr/include \
    -DLIBSAMPLERATE_LIBRARY=/usr/lib/aarch64-linux-gnu/libsamplerate.so \
    -DPORTAUDIO_INCLUDE_DIR=/usr/include \
    -DPORTAUDIO_LIBRARIES=/usr/lib/aarch64-linux-gnu/libportaudio.so \
    -DRTLSDR_INCLUDE_DIR=/usr/include \
    -DRTLSDR_LIBRARY=/usr/lib/aarch64-linux-gnu/librtlsdr.so \
    -DRTLSDR_LIBRARIES=/usr/lib/aarch64-linux-gnu/librtlsdr.so \
    -DLIBRTLSDR_INCLUDE_DIR=/usr/include \
    -DLIBRTLSDR_LIBRARY=/usr/lib/aarch64-linux-gnu/librtlsdr.so \
    -DLIBRTLSDR_LIBRARIES=/usr/lib/aarch64-linux-gnu/librtlsdr.so \
    -DLIBSNDFILE_INCLUDE_DIR=/usr/include \
    -DLIBSNDFILE_LIBRARY=/usr/lib/aarch64-linux-gnu/libsndfile.so \
    -DSNDFILE_INCLUDE_DIR=/usr/include \
    -DSNDFILE_LIBRARY=/usr/lib/aarch64-linux-gnu/libsndfile.so \
    -DZLIB_INCLUDE_DIR=/usr/include \
    -DZLIB_LIBRARY=/usr/lib/aarch64-linux-gnu/libz.so \
    -DPTHREADS=/usr/lib/aarch64-linux-gnu/libpthread.so
else
  cmake "$SOURCE_DIR/example-3" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR="$CMAKE_PROCESSOR" \
    -DCMAKE_C_COMPILER=/usr/bin/gcc \
    -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
    -DRTLSDR=ON
fi

if [ $? -ne 0 ]; then
  echo "[!] CMake configuration failed for dab-rtlsdr-3"
  exit 1
fi

make -j$(nproc)
if [ $? -ne 0 ]; then
  echo "[!] Build failed for dab-rtlsdr-3"
  exit 1
fi

# Strip binary
strip dab-rtlsdr-3

# Copy to output
cp dab-rtlsdr-3 "$OUTPUT_DIR/"
SIZE=$(stat -c%s "$OUTPUT_DIR/dab-rtlsdr-3")
echo "    Built: dab-rtlsdr-3 ($SIZE bytes)"
echo ""

# Build dab-scanner-3 (dab-scanner)
echo "[+] Building dab-scanner-3 (dab-scanner)..."
mkdir -p "$BUILD_DIR/dab-scanner"
cd "$BUILD_DIR/dab-scanner"

# CMake with explicit configuration
if [ "$ARCH" = "arm64" ]; then
  # arm64 requires explicit library paths due to broken CMake FindModules
  cmake "$SOURCE_DIR/dab-scanner" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR="$CMAKE_PROCESSOR" \
    -DCMAKE_C_COMPILER=/usr/bin/gcc \
    -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
    -DRTLSDR=ON \
    -DFFTW3F_INCLUDE_DIR=/usr/include \
    -DFFTW3F_LIBRARIES=/usr/lib/aarch64-linux-gnu/libfftw3f.so \
    -DFAAD_INCLUDE_DIR=/usr/include \
    -DFAAD_LIBRARY=/usr/lib/aarch64-linux-gnu/libfaad.so \
    -DRTLSDR_INCLUDE_DIR=/usr/include \
    -DRTLSDR_LIBRARY=/usr/lib/aarch64-linux-gnu/librtlsdr.so \
    -DRTLSDR_LIBRARIES=/usr/lib/aarch64-linux-gnu/librtlsdr.so \
    -DLIBRTLSDR_INCLUDE_DIR=/usr/include \
    -DLIBRTLSDR_LIBRARY=/usr/lib/aarch64-linux-gnu/librtlsdr.so \
    -DLIBRTLSDR_LIBRARIES=/usr/lib/aarch64-linux-gnu/librtlsdr.so \
    -DLIBSNDFILE_INCLUDE_DIR=/usr/include \
    -DLIBSNDFILE_LIBRARY=/usr/lib/aarch64-linux-gnu/libsndfile.so \
    -DSNDFILE_INCLUDE_DIR=/usr/include \
    -DSNDFILE_LIBRARY=/usr/lib/aarch64-linux-gnu/libsndfile.so \
    -DZLIB_INCLUDE_DIR=/usr/include \
    -DZLIB_LIBRARY=/usr/lib/aarch64-linux-gnu/libz.so \
    -DPTHREADS=/usr/lib/aarch64-linux-gnu/libpthread.so
else
  cmake "$SOURCE_DIR/dab-scanner" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_SYSTEM_NAME=Linux \
    -DCMAKE_SYSTEM_PROCESSOR="$CMAKE_PROCESSOR" \
    -DCMAKE_C_COMPILER=/usr/bin/gcc \
    -DCMAKE_CXX_COMPILER=/usr/bin/g++ \
    -DRTLSDR=ON
fi

if [ $? -ne 0 ]; then
  echo "[!] CMake configuration failed for dab-scanner-3"
  exit 1
fi

make -j$(nproc)
if [ $? -ne 0 ]; then
  echo "[!] Build failed for dab-scanner-3"
  exit 1
fi

# Strip binary
strip dab-scanner-rtlsdr

# Copy to output (note: binary is dab-scanner-rtlsdr, we rename to dab-scanner-3)
cp dab-scanner-rtlsdr "$OUTPUT_DIR/dab-scanner-3"
SIZE=$(stat -c%s "$OUTPUT_DIR/dab-scanner-3")
echo "    Built: dab-scanner-3 ($SIZE bytes)"
echo ""

echo "========================================"
echo "Build complete for $ARCH"
echo "========================================"
echo ""
echo "Output binaries in: $OUTPUT_DIR"
ls -lh "$OUTPUT_DIR"
echo ""
