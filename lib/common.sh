#!/bin/bash
# lib/common.sh - Biblioteca compartilhada do dev-setup
# Fornece logging, timing, error handling e utilidades comuns.

set -uo pipefail

# Diretorio base do dev-setup
DEVSETUP_DIR="${DEVSETUP_DIR:-$HOME/.dev-setup}"
DEVSETUP_VERSION="$(cat "$DEVSETUP_DIR/VERSION" 2>/dev/null || echo "unknown")"

# Logging
LOG_DIR="$DEVSETUP_DIR/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d%H%M%S).log"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores de resultado
_STEPS_PASSED=0
_STEPS_FAILED=0
_STEPS_RESULTS=()

_log() {
  local level="$1"
  local color="$2"
  shift 2
  local msg="$*"
  local timestamp
  timestamp="$(date +%H:%M:%S)"
  echo -e "${color}[${level}]${NC} ${msg}"
  echo "[${timestamp}] [${level}] ${msg}" >> "$LOG_FILE"
}

log_info() {
  _log "INFO" "$BLUE" "$@"
}

log_success() {
  _log " OK " "$GREEN" "$@"
}

log_warn() {
  _log "WARN" "$YELLOW" "$@"
}

log_error() {
  _log "FAIL" "$RED" "$@"
}

# run_step: Executa uma funcao com timing e captura de erro.
# Nao aborta em caso de falha - acumula resultados para o resumo final.
#
# Uso: run_step "Nome do passo" funcao_a_executar
run_step() {
  local name="$1"
  shift
  local start_time
  start_time=$(date +%s)

  log_info "Iniciando: ${name}..."

  local exit_code=0
  "$@" > >(tee -a "$LOG_FILE") 2>&1 || exit_code=$?

  local end_time
  end_time=$(date +%s)
  local duration=$((end_time - start_time))

  if [ $exit_code -eq 0 ]; then
    log_success "${name} (${duration}s)"
    _STEPS_PASSED=$((_STEPS_PASSED + 1))
    _STEPS_RESULTS+=("[OK]   ${name} (${duration}s)")
  else
    log_error "${name} falhou (exit code: ${exit_code}, ${duration}s)"
    _STEPS_FAILED=$((_STEPS_FAILED + 1))
    _STEPS_RESULTS+=("[FAIL] ${name} (${duration}s)")
  fi

  return 0  # Nunca aborta - acumula para o resumo
}

# print_summary: Imprime o resumo de todos os passos executados.
print_summary() {
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "  Dev Setup v${DEVSETUP_VERSION} - Resumo"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

  for result in "${_STEPS_RESULTS[@]}"; do
    if [[ "$result" == *"[FAIL]"* ]]; then
      echo -e "  ${RED}${result}${NC}"
    else
      echo -e "  ${GREEN}${result}${NC}"
    fi
  done

  echo ""
  echo "  Passou: ${_STEPS_PASSED}  |  Falhou: ${_STEPS_FAILED}"
  echo ""

  if [ $_STEPS_FAILED -gt 0 ]; then
    log_warn "Algumas etapas falharam. Veja o log completo em:"
    log_warn "$LOG_FILE"
    echo ""
    return 1
  else
    log_success "Todas as etapas concluidas com sucesso!"
    echo ""
    return 0
  fi
}

# require_macos: Verifica se estamos em macOS.
require_macos() {
  if [ "$(uname)" != "Darwin" ]; then
    log_error "Este script requer macOS"
    exit 1
  fi
}
