#!/usr/bin/env bash
# install.sh - Entrypoint remoto do dev-setup
# Uso: curl -fsSL https://raw.githubusercontent.com/kruzer-corp/dev-setup/main/install.sh | bash
# Uso com versao: DEVSETUP_VERSION=1.2.0 curl -fsSL ... | bash
#
# Nao use "sh install.sh": no Ubuntu /bin/sh e dash e nao suporta "set -o pipefail".
# Use: bash install.sh   ou   chmod +x install.sh && ./install.sh

if [ -z "${BASH_VERSION:-}" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

set -euo pipefail

REPO="https://github.com/kruzer-corp/dev-setup"
DEST="$HOME/.dev-setup"
VERSION="${DEVSETUP_VERSION:-latest}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Dev Setup - Kruzer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Determina URL de download baseado na versao
if [ "$VERSION" = "latest" ]; then
  DOWNLOAD_URL="$REPO/archive/refs/heads/main.tar.gz"
  echo "Versao: latest (main)"
else
  DOWNLOAD_URL="$REPO/archive/refs/tags/v${VERSION}.tar.gz"
  echo "Versao: $VERSION"
fi

echo "Destino: $DEST"
echo ""

# Backup se ja existe
if [ -d "$DEST" ]; then
  BACKUP="$DEST.backup.$(date +%Y%m%d%H%M%S)"
  echo "Backup do setup anterior em $BACKUP"
  mv "$DEST" "$BACKUP"
fi

mkdir -p "$DEST"

echo "Baixando dev-setup..."
if ! curl -fsSL "$DOWNLOAD_URL" | tar -xz --strip-components=1 -C "$DEST"; then
  echo "Erro ao baixar. Verifique a versao e tente novamente."
  exit 1
fi

echo ""
echo "Instalado em $DEST"
INSTALLED_VERSION="$(cat "$DEST/VERSION" 2>/dev/null || echo "unknown")"
echo "Versao: $INSTALLED_VERSION"
echo ""
echo "Proximo passo:"
echo "  cd $DEST && ./bootstrap/install.sh"
echo ""
