#!/usr/bin/env bash
# bootstrap/install.sh - Orquestrador principal do dev-setup
# Detecta o OS e executa o setup apropriado.
# Requer bash (nao use "sh" — dash nao suporta pipefail).

if [ -z "${BASH_VERSION:-}" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

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
    bash "$SCRIPT_DIR/macos.sh" || exit $?
    ;;
  Linux)
    log_info "Linux detectado"
    bash "$SCRIPT_DIR/linux.sh" || exit $?
    ;;
  *)
    log_error "Sistema nao suportado: $OS"
    log_info "Atualmente macOS e Linux (Ubuntu/Debian) sao suportados."
    exit 1
    ;;
esac

echo ""
log_info "Validando instalacao..."
if ! bash "$SCRIPT_DIR/check.sh"; then
  echo ""
  log_error "Validacao falhou. Veja o relatorio em: $LOG_DIR/check-result.json"
  log_error "Log completo: $LOG_FILE"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setup finalizado!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
log_info "Reinicie o terminal para aplicar todas as configuracoes."
log_info "Log completo: $LOG_FILE"
echo ""
