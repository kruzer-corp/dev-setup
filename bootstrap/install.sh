#!/bin/bash
set -e

echo "🔍 Detecting OS..."
OS="$(uname)"

if [[ "$OS" == "Darwin" ]]; then
  echo "🍎 macOS detected"
  bash bootstrap/macos.sh
else
  echo "❌ OS not supported yet"
  exit 1
fi
