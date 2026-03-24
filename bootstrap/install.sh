#!/bin/bash
# bootstrap/install.sh - Orquestrador principal do dev-setup
# Detecta o OS e executa o setup apropriado.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export DEVSETUP_DIR="${DEVSETUP_DIR:-$HOME/.dev-setup}"

source "$DEVSETUP_DIR/lib/common.sh"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Dev Setup v${DEVSETUP_VERSION}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

OS="$(uname)"

case "$OS" in
  Darwin)
    log_info "macOS detectado"
    bash "$SCRIPT_DIR/macos.sh"
    ;;
  *)
    log_error "Sistema nao suportado: $OS"
    log_info "Atualmente apenas macOS e suportado."
    exit 1
    ;;
esac

echo ""
log_info "Validando instalacao..."
bash "$SCRIPT_DIR/check.sh"

# Resumo final (do macos.sh via common.sh)
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setup finalizado!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Reinicie o terminal para aplicar todas as configuracoes."
log_info "Log completo: $LOG_FILE"
echo ""
