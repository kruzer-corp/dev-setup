#!/bin/bash
# bootstrap/check-lib.sh - Funcoes compartilhadas para check.sh (contadores + JSON via jq).

: "${DEVSETUP_DIR:=$HOME/.dev-setup}"
: "${LOG_DIR:=$DEVSETUP_DIR/logs}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

FAIL_COUNT=0
WARN_COUNT=0
PASS_COUNT=0
JSON_ITEMS=()

_check_json_row() {
  local name="$1"
  local status="$2"
  local version_kind="$3"
  local version_val="${4:-}"
  case "$version_kind" in
    null)
      JSON_ITEMS+=("$(jq -n --arg name "$name" --arg status "$status" '{name: $name, status: $status, version: null}')")
      ;;
    str)
      JSON_ITEMS+=("$(jq -n --arg name "$name" --arg status "$status" --arg ver "$version_val" '{name: $name, status: $status, version: $ver}')")
      ;;
  esac
}

_run_version_cmd() {
  local version_cmd="$1"
  [ -z "$version_cmd" ] && echo "unknown" && return 0
  bash -c "$version_cmd" 2>/dev/null | head -1 || echo "unknown"
}

check_cmd() {
  local name="$1"
  local cmd="${2:-$1}"
  local version_cmd="${3:-}"

  if command -v "$cmd" >/dev/null 2>&1; then
    local version
    version="$(_run_version_cmd "$version_cmd")"
    echo -e "  ${GREEN}[OK]${NC}   $name ($version)"
    PASS_COUNT=$((PASS_COUNT + 1))
    _check_json_row "$name" "ok" str "$version"
  else
    echo -e "  ${RED}[FAIL]${NC} $name nao encontrado"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    _check_json_row "$name" "fail" null
  fi
}

# eza (etc.): falha vira aviso em vez de FAIL
check_cmd_warn_if_missing() {
  local name="$1"
  local cmd="${2:-$1}"
  local version_cmd="${3:-}"

  if command -v "$cmd" >/dev/null 2>&1; then
    local version
    version="$(_run_version_cmd "$version_cmd")"
    echo -e "  ${GREEN}[OK]${NC}   $name ($version)"
    PASS_COUNT=$((PASS_COUNT + 1))
    _check_json_row "$name" "ok" str "$version"
  else
    echo -e "  ${YELLOW}[WARN]${NC} $name nao encontrado (opcional nesta plataforma)"
    WARN_COUNT=$((WARN_COUNT + 1))
    _check_json_row "$name" "warn" null
  fi
}

check_app() {
  local name="$1"
  local app_path="$2"

  if [ -d "$app_path" ]; then
    echo -e "  ${GREEN}[OK]${NC}   $name"
    PASS_COUNT=$((PASS_COUNT + 1))
    _check_json_row "$name" "ok" str "installed"
  else
    echo -e "  ${RED}[FAIL]${NC} $name nao encontrado"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    _check_json_row "$name" "fail" null
  fi
}

check_optional_app() {
  local name="$1"
  local app_path="$2"

  if [ -d "$app_path" ]; then
    echo -e "  ${GREEN}[OK]${NC}   $name"
    PASS_COUNT=$((PASS_COUNT + 1))
    _check_json_row "$name" "ok" str "installed"
  else
    echo -e "  ${YELLOW}[ - ]${NC} $name (nao instalado)"
    _check_json_row "$name" "skipped" null
  fi
}

check_service() {
  local name="$1"
  local run_cmd="$2"

  if bash -c "$run_cmd" >/dev/null 2>&1; then
    echo -e "  ${GREEN}[OK]${NC}   $name rodando"
    PASS_COUNT=$((PASS_COUNT + 1))
    _check_json_row "$name" "ok" null
  else
    echo -e "  ${YELLOW}[WARN]${NC} $name nao esta rodando"
    WARN_COUNT=$((WARN_COUNT + 1))
    _check_json_row "$name" "warn" null
  fi
}

check_linux_slack() {
  if command -v slack >/dev/null 2>&1; then
    echo -e "  ${GREEN}[OK]${NC}   Slack (binario)"
    PASS_COUNT=$((PASS_COUNT + 1))
    _check_json_row "Slack" "ok" str "installed"
  elif command -v snap >/dev/null 2>&1 && snap list slack >/dev/null 2>&1; then
    echo -e "  ${GREEN}[OK]${NC}   Slack (snap)"
    PASS_COUNT=$((PASS_COUNT + 1))
    _check_json_row "Slack" "ok" str "snap"
  else
    echo -e "  ${RED}[FAIL]${NC} Slack nao encontrado"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    _check_json_row "Slack" "fail" null
  fi
}

check_linux_openvpn_note() {
  echo -e "  ${YELLOW}[ - ]${NC} OpenVPN (Linux): configure conforme o cliente usado pela empresa (NetworkManager/openvpn3)"
  _check_json_row "OpenVPN" "skipped" null
}

# Uso: check_optional_linux_gui "Nome" 'bash -c compatible test'
check_optional_linux_gui() {
  local name="$1"
  local test_cmd="$2"

  if bash -c "$test_cmd" >/dev/null 2>&1; then
    echo -e "  ${GREEN}[OK]${NC}   $name"
    PASS_COUNT=$((PASS_COUNT + 1))
    _check_json_row "$name" "ok" str "installed"
  else
    echo -e "  ${YELLOW}[ - ]${NC} $name (nao instalado)"
    _check_json_row "$name" "skipped" null
  fi
}

write_check_json_report() {
  local report_file="$1"
  local checks_json
  if [ ${#JSON_ITEMS[@]} -eq 0 ]; then
    checks_json='[]'
  else
    checks_json="$(printf '%s\n' "${JSON_ITEMS[@]}" | jq -s -c '.')"
  fi

  local ver
  ver="$(cat "$DEVSETUP_DIR/VERSION" 2>/dev/null || echo "unknown")"

  jq -n \
    --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    --arg os "$(uname -s) $(uname -r)" \
    --arg arch "$(uname -m)" \
    --arg version "$ver" \
    --argjson passed "$PASS_COUNT" \
    --argjson warnings "$WARN_COUNT" \
    --argjson failed "$FAIL_COUNT" \
    --argjson checks "$checks_json" \
    '{
      timestamp: $ts,
      os: $os,
      arch: $arch,
      version: $version,
      passed: $passed,
      warnings: $warnings,
      failed: $failed,
      checks: $checks
    }' > "$report_file"
}
