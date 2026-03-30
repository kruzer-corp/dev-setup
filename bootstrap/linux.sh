#!/bin/bash
# bootstrap/linux.sh - Detecta distribuicao e delega o setup Linux.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVSETUP_DIR="${DEVSETUP_DIR:-$HOME/.dev-setup}"

# shellcheck source=../lib/common.sh
source "$DEVSETUP_DIR/lib/common.sh"

if [ ! -r /etc/os-release ]; then
  log_error "Nao foi possivel ler /etc/os-release"
  exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release

log_info "Distribuicao: ${PRETTY_NAME:-$ID}"

case "$ID" in
  ubuntu | debian)
    bash "$SCRIPT_DIR/linux-ubuntu.sh"
    ;;
  *)
    log_error "Distribuicao nao suportada: $ID"
    log_info "v1 suporta apenas Ubuntu e Debian (apt + systemd)."
    exit 1
    ;;
esac
