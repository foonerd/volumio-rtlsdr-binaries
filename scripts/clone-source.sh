#!/bin/bash
# volumio-rtlsdr-binaries scripts/clone-source.sh
# Clone dab-cmdline source repository

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"

cd "$REPO_DIR"

DAB_REPO="https://github.com/JvanKatwijk/dab-cmdline.git"
SOURCE_DIR="source/dab-cmdline"

echo "[+] Cloning dab-cmdline source..."
echo "    Repository: $DAB_REPO"
echo "    Target: $SOURCE_DIR"
echo ""

# Create source directory
mkdir -p source

# Clone repository
if [ -d "$SOURCE_DIR" ]; then
  echo "[!] Source directory already exists: $SOURCE_DIR"
  echo "[!] Remove it first or skip cloning"
  exit 1
fi

git clone --depth 1 "$DAB_REPO" "$SOURCE_DIR"

echo ""
echo "[+] Source cloned successfully"
echo "    Location: $SOURCE_DIR"
