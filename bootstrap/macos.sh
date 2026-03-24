#!/bin/bash
set -e

echo "🔧 Installing Homebrew..."
if ! command -v brew &> /dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "📦 Installing packages..."
brew bundle --file=bootstrap/Brewfile

echo "⚙️ Installing Xcode CLI tools..."
xcode-select --install || true

echo "📁 Setting up dotfiles..."
mkdir -p ~/dotfiles
cp -r dotfiles/* ~/dotfiles/

ln -sf ~/dotfiles/zsh/.zshrc ~/.zshrc

echo "🐳 Starting Docker..."
open -a Docker || true

echo "✅ Setup completed!"
