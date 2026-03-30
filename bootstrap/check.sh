#!/bin/bash
# bootstrap/check.sh - Validacao do ambiente; comum + macOS ou Linux; JSON via jq.

DEVSETUP_DIR="${DEVSETUP_DIR:-$HOME/.dev-setup}"
LOG_DIR="$DEVSETUP_DIR/logs"
mkdir -p "$LOG_DIR"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=check-lib.sh
source "$SCRIPT_DIR/check-lib.sh"

if ! command -v jq >/dev/null 2>&1; then
  echo "Erro: jq e necessario para gerar check-result.json. Instale jq e tente de novo."
  exit 2
fi

OS="$(uname -s)"

echo ""
echo "Verificando ambiente de desenvolvimento..."
echo ""

# --- CLI Tools ---
echo "  CLI Tools"
echo "  ---------"
check_cmd "git" "git" "git --version"
check_cmd "gh" "gh" "gh --version"
check_cmd "jq" "jq" "jq --version"
check_cmd "fzf" "fzf" "fzf --version"
if [ "$OS" = "Darwin" ]; then
  check_cmd "eza" "eza" "eza --version"
else
  check_cmd_warn_if_missing "eza" "eza" "eza --version"
fi
if [ "$OS" = "Darwin" ]; then
  check_cmd "zoxide" "zoxide" "zoxide --version"
else
  check_cmd_warn_if_missing "zoxide" "zoxide" "zoxide --version"
fi
check_cmd "direnv" "direnv" "direnv version"
echo ""

# --- Runtime (nvm / node) ---
echo "  Runtime"
echo "  -------"

NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -d "$NVM_DIR/versions/node" ] && [ "$(ls -A "$NVM_DIR/versions/node" 2>/dev/null)" ]; then
  nvm_versions="$(ls "$NVM_DIR/versions/node" | wc -l | tr -d ' ') versoes"
  echo -e "  ${GREEN}[OK]${NC}   nvm ($nvm_versions)"
  PASS_COUNT=$((PASS_COUNT + 1))
  _check_json_row "nvm" "ok" str "$nvm_versions"

  default_node="$(ls -d "$NVM_DIR/versions/node/"* 2>/dev/null | sort -V | tail -1)"
  if [ -n "$default_node" ] && [ -x "$default_node/bin/node" ]; then
    node_ver="$("$default_node/bin/node" --version 2>/dev/null)"
    echo -e "  ${GREEN}[OK]${NC}   node ($node_ver via nvm)"
    PASS_COUNT=$((PASS_COUNT + 1))
    _check_json_row "node" "ok" str "$node_ver"
  fi
elif [ -d "$NVM_DIR" ] && [ -f "$NVM_DIR/nvm.sh" ]; then
  echo -e "  ${YELLOW}[WARN]${NC} nvm instalado mas sem versoes do Node"
  WARN_COUNT=$((WARN_COUNT + 1))
  _check_json_row "nvm" "warn" str "no versions"
else
  echo -e "  ${RED}[FAIL]${NC} nvm nao encontrado"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  _check_json_row "nvm" "fail" null
  check_cmd "node" "node" "node --version"
fi
echo ""

# --- Aplicacoes (plataforma) ---
echo "  Aplicacoes"
echo "  ----------"
if [ "$OS" = "Darwin" ]; then
  check_app "iTerm2" "/Applications/iTerm.app"
  check_app "Slack" "/Applications/Slack.app"
  check_app "Claude Desktop" "/Applications/Claude.app"
  check_cmd "Claude Code" "claude" "claude --version"
  check_app "OpenVPN Connect" "/Applications/OpenVPN Connect/OpenVPN Connect.app"
elif [ "$OS" = "Linux" ]; then
  echo -e "  ${YELLOW}[ - ]${NC} iTerm2 (macOS apenas)"
  _check_json_row "iTerm2" "skipped" null
  check_linux_slack
  echo -e "  ${YELLOW}[ - ]${NC} Claude Desktop (nao automatizado no Linux)"
  _check_json_row "Claude Desktop" "skipped" null
  check_cmd_warn_if_missing "Claude Code" "claude" "claude --version"
  check_linux_openvpn_note
fi
check_cmd "VS Code" "code" "code --version"
check_cmd "Docker" "docker" "docker --version"
echo ""

# --- Aplicacoes opcionais ---
echo "  Aplicacoes (opcionais)"
echo "  ----------------------"
if [ "$OS" = "Darwin" ]; then
  check_optional_app "Google Chrome" "/Applications/Google Chrome.app"
  check_optional_app "MongoDB Compass" "/Applications/MongoDB Compass.app"
  check_optional_app "Redis Insight" "/Applications/Redis Insight.app"
  check_optional_app "Postman" "/Applications/Postman.app"
else
  check_optional_linux_gui "Google Chrome" "command -v google-chrome >/dev/null 2>&1 || command -v google-chrome-stable >/dev/null 2>&1"
  check_optional_linux_gui "MongoDB Compass" "command -v snap >/dev/null 2>&1 && snap list mongodb-compass >/dev/null 2>&1"
  check_optional_linux_gui "Redis Insight" "command -v snap >/dev/null 2>&1 && snap list redisinsight >/dev/null 2>&1"
  check_optional_linux_gui "Postman" "command -v snap >/dev/null 2>&1 && snap list postman >/dev/null 2>&1"
fi
echo ""

# --- Servicos ---
echo "  Servicos"
echo "  --------"
check_service "Docker daemon" "docker info"
if [ "$OS" = "Linux" ] && command -v systemctl >/dev/null 2>&1; then
  check_service "Docker (systemd)" "systemctl is-active --quiet docker"
fi
echo ""

# --- Configuracao corporativa ---
CORP_DOMAIN="kruzer.ai"

echo "  Configuracao (@${CORP_DOMAIN})"
echo "  --------"

git_email="$(git config --global user.email 2>/dev/null || echo "")"
if [ -n "$git_email" ] && [[ "$git_email" == *"@${CORP_DOMAIN}" ]]; then
  echo -e "  ${GREEN}[OK]${NC}   git email ($git_email)"
  PASS_COUNT=$((PASS_COUNT + 1))
  _check_json_row "git_email" "ok" str "$git_email"
elif [ -n "$git_email" ]; then
  echo -e "  ${YELLOW}[WARN]${NC} git email ($git_email) - esperado @${CORP_DOMAIN}"
  WARN_COUNT=$((WARN_COUNT + 1))
  _check_json_row "git_email" "warn" str "$git_email"
else
  echo -e "  ${RED}[FAIL]${NC} git email nao configurado"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  _check_json_row "git_email" "fail" null
fi

git_name="$(git config --global user.name 2>/dev/null || echo "")"
if [ -n "$git_name" ]; then
  echo -e "  ${GREEN}[OK]${NC}   git name ($git_name)"
  PASS_COUNT=$((PASS_COUNT + 1))
  _check_json_row "git_name" "ok" str "$git_name"
else
  echo -e "  ${RED}[FAIL]${NC} git name nao configurado"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  _check_json_row "git_name" "fail" null
fi

gh_user=""
if command -v gh >/dev/null 2>&1; then
  gh_user="$(gh auth status 2>&1 || true)"
fi
if echo "$gh_user" | grep -q "Logged in"; then
  gh_account="$(echo "$gh_user" | grep -o 'account [^ ]*' | head -1 | cut -d' ' -f2)"
  echo -e "  ${GREEN}[OK]${NC}   gh auth ($gh_account)"
  PASS_COUNT=$((PASS_COUNT + 1))
  _check_json_row "gh_auth" "ok" str "$gh_account"
else
  echo -e "  ${YELLOW}[WARN]${NC} gh nao autenticado - execute: gh auth login"
  WARN_COUNT=$((WARN_COUNT + 1))
  _check_json_row "gh_auth" "warn" null
fi

if [ -n "${NPM_TOKEN:-}" ]; then
  echo -e "  ${GREEN}[OK]${NC}   NPM_TOKEN configurado"
  PASS_COUNT=$((PASS_COUNT + 1))
  _check_json_row "npm_token" "ok" str "set"
else
  echo -e "  ${RED}[FAIL]${NC} NPM_TOKEN nao definido - necessario para pacotes privados"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  _check_json_row "npm_token" "fail" null
fi
echo ""

# --- Dotfiles ---
echo "  Dotfiles"
echo "  --------"
if [ -L "$HOME/.zshrc" ]; then
  zshrc_target="$(readlink "$HOME/.zshrc")"
  echo -e "  ${GREEN}[OK]${NC}   .zshrc -> $zshrc_target"
  PASS_COUNT=$((PASS_COUNT + 1))
  _check_json_row "dotfiles_zshrc" "ok" str "$zshrc_target"
else
  echo -e "  ${YELLOW}[WARN]${NC} .zshrc nao e um symlink (dotfiles nao configurados)"
  WARN_COUNT=$((WARN_COUNT + 1))
  _check_json_row "dotfiles_zshrc" "warn" null
fi
echo ""

# --- Proximos passos ---
NEXT_STEPS=()

if [ -z "$git_name" ]; then
  NEXT_STEPS+=("  git config --global user.name \"Seu Nome\"")
fi

if [ -z "$git_email" ] || [[ "$git_email" != *"@${CORP_DOMAIN}" ]]; then
  NEXT_STEPS+=("  git config --global user.email \"seu@${CORP_DOMAIN}\"")
fi

if ! echo "$gh_user" | grep -q "Logged in"; then
  NEXT_STEPS+=("  gh auth login")
fi

if [ -z "${NPM_TOKEN:-}" ]; then
  NEXT_STEPS+=("  echo 'export NPM_TOKEN=\"seu-token\"' >> ~/.zshrc.local && source ~/.zshrc.local")
fi

if [ "$OS" = "Darwin" ]; then
  if [ -d "/Applications/OpenVPN Connect/OpenVPN Connect.app" ] && ! ls ~/Library/Application\ Support/OpenVPN\ Connect/profiles/*.ovpn >/dev/null 2>&1; then
    NEXT_STEPS+=("  Configurar VPN: abra OpenVPN Connect e importe o perfil .ovpn (solicite ao time de infra)")
  fi
else
  NEXT_STEPS+=("  VPN Linux: configure com o cliente indicado pela infra (OpenVPN/NetworkManager/openvpn3)")
fi

if [ ${#NEXT_STEPS[@]} -gt 0 ]; then
  echo "  Proximos passos"
  echo "  ----------------"
  for step in "${NEXT_STEPS[@]}"; do
    echo -e "  ${YELLOW}▸${NC}$step"
  done
  echo ""
fi

# --- Resumo + JSON ---
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Passou: $PASS_COUNT  |  Avisos: $WARN_COUNT  |  Falhou: $FAIL_COUNT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

REPORT_FILE="$LOG_DIR/check-result.json"
write_check_json_report "$REPORT_FILE"

echo "Relatorio salvo em $REPORT_FILE"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
  exit 1
fi
exit 0
