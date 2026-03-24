#!/bin/bash

set -e

REPO_ZIP_URL="https://github.com/kruzer-corp/dev-setup/archive/refs/heads/main.zip"
TARGET_DIR="$HOME/.dev-setup"

echo "📦 Downloading dev-setup..."

TMP_ZIP="/tmp/dev-setup.zip"

curl -L "$REPO_ZIP_URL" -o "$TMP_ZIP"

echo "📂 Extracting..."

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

unzip -q "$TMP_ZIP" -d /tmp

mv /tmp/dev-setup-main/* "$TARGET_DIR"

cd "$TARGET_DIR"

echo "🚀 Running setup..."
bash bootstrap/install.sh
