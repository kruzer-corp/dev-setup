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

_apt_run() {
  if [ "$(id -u)" -eq 0 ]; then
    DEBIAN_FRONTEND=noninteractive apt-get "$@"
  else
    sudo env DEBIAN_FRONTEND=noninteractive apt-get "$@"
  fi
}

_is_debian_family() {
  [ -r /etc/os-release ] || return 1
  # shellcheck source=/dev/null
  . /etc/os-release
  case "${ID:-}" in
    ubuntu | debian) return 0 ;;
    *) return 1 ;;
  esac
}

_ensure_tar() {
  command -v tar >/dev/null 2>&1 && return 0
  if _is_debian_family && command -v apt-get >/dev/null 2>&1; then
    if [ "$(id -u)" -ne 0 ] && ! command -v sudo >/dev/null 2>&1; then
      echo "Erro: tar nao encontrado e sudo nao esta disponivel para instalar." >&2
      return 1
    fi
    echo "Instalando tar (apt)..."
    _apt_run update -qq
    _apt_run install -y -qq tar
  fi
  command -v tar >/dev/null 2>&1
}

_ensure_curl_or_wget() {
  command -v curl >/dev/null 2>&1 && return 0
  command -v wget >/dev/null 2>&1 && return 0

  if _is_debian_family && command -v apt-get >/dev/null 2>&1; then
    if [ "$(id -u)" -ne 0 ] && ! command -v sudo >/dev/null 2>&1; then
      echo "Erro: instale curl ou wget, ou use uma conta com sudo:" >&2
      echo "  apt update && apt install -y curl ca-certificates" >&2
      return 1
    fi
    echo "Instalando curl e certificados (apt) para baixar o repositorio..."
    _apt_run update -qq
    _apt_run install -y -qq curl ca-certificates
  fi

  command -v curl >/dev/null 2>&1 || command -v wget >/dev/null 2>&1
}

# Stream do tarball para stdout
download_tarball() {
  local url="$1"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO- "$url"
  else
    echo "Erro: nem curl nem wget disponiveis apos tentativa automatica." >&2
    echo "Instale manualmente: sudo apt update && sudo apt install -y curl" >&2
    exit 1
  fi
}

if ! _ensure_tar; then
  echo "Erro: o comando tar e necessario para extrair o pacote." >&2
  exit 1
fi

if ! _ensure_curl_or_wget; then
  echo "Erro: curl ou wget e necessario para baixar o repositorio." >&2
  exit 1
fi

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
if ! download_tarball "$DOWNLOAD_URL" | tar -xz --strip-components=1 -C "$DEST"; then
  echo "Erro ao baixar ou extrair. Verifique a rede, a versao e tente novamente."
  exit 1
fi

echo ""
echo "Instalado em $DEST"
INSTALLED_VERSION="$(cat "$DEST/VERSION" 2>/dev/null || echo "unknown")"
echo "Versao: $INSTALLED_VERSION"
echo ""
echo "Proximo passo:"
echo "  cd $DEST && bash bootstrap/install.sh"
echo ""
