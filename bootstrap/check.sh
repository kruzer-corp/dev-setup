#!/bin/bash
# bootstrap/check.sh - Validacao completa do ambiente de desenvolvimento
# Verifica todas as ferramentas instaladas e gera relatorio JSON.

DEVSETUP_DIR="${DEVSETUP_DIR:-$HOME/.dev-setup}"
LOG_DIR="$DEVSETUP_DIR/logs"
mkdir -p "$LOG_DIR"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

FAIL_COUNT=0
WARN_COUNT=0
PASS_COUNT=0
JSON_ITEMS=()

check_cmd() {
  local name="$1"
  local cmd="${2:-$1}"
  local version_cmd="${3:-}"

  if command -v "$cmd" >/dev/null 2>&1; then
    local version="unknown"
    if [ -n "$version_cmd" ]; then
      version="$(eval "$version_cmd" 2>/dev/null | head -1 || echo "unknown")"
    fi
    echo -e "  ${GREEN}[OK]${NC}   $name ($version)"
    PASS_COUNT=$((PASS_COUNT + 1))
    JSON_ITEMS+=("{\"name\":\"$name\",\"status\":\"ok\",\"version\":\"$version\"}")
  else
    echo -e "  ${RED}[FAIL]${NC} $name nao encontrado"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    JSON_ITEMS+=("{\"name\":\"$name\",\"status\":\"fail\",\"version\":null}")
  fi
}

check_app() {
  local name="$1"
  local app_path="$2"

  if [ -d "$app_path" ]; then
    echo -e "  ${GREEN}[OK]${NC}   $name"
    PASS_COUNT=$((PASS_COUNT + 1))
    JSON_ITEMS+=("{\"name\":\"$name\",\"status\":\"ok\",\"version\":\"installed\"}")
  else
    echo -e "  ${RED}[FAIL]${NC} $name nao encontrado"
    FAIL_COUNT=$((FAIL_COUNT + 1))
    JSON_ITEMS+=("{\"name\":\"$name\",\"status\":\"fail\",\"version\":null}")
  fi
}

check_optional_app() {
  local name="$1"
  local app_path="$2"

  if [ -d "$app_path" ]; then
    echo -e "  ${GREEN}[OK]${NC}   $name"
    PASS_COUNT=$((PASS_COUNT + 1))
    JSON_ITEMS+=("{\"name\":\"$name\",\"status\":\"ok\",\"version\":\"installed\"}")
  else
    echo -e "  ${YELLOW}[ - ]${NC} $name (nao instalado)"
    JSON_ITEMS+=("{\"name\":\"$name\",\"status\":\"skipped\",\"version\":null}")
  fi
}

check_service() {
  local name="$1"
  local check_cmd="$2"

  if eval "$check_cmd" >/dev/null 2>&1; then
    echo -e "  ${GREEN}[OK]${NC}   $name rodando"
    PASS_COUNT=$((PASS_COUNT + 1))
    JSON_ITEMS+=("{\"name\":\"$name\",\"status\":\"ok\",\"version\":null}")
  else
    echo -e "  ${YELLOW}[WARN]${NC} $name nao esta rodando"
    WARN_COUNT=$((WARN_COUNT + 1))
    JSON_ITEMS+=("{\"name\":\"$name\",\"status\":\"warn\",\"version\":null}")
  fi
}

echo ""
echo "Verificando ambiente de desenvolvimento..."
echo ""

# CLI Tools
echo "  CLI Tools"
echo "  ---------"
check_cmd "git"     "git"     "git --version"
check_cmd "gh"      "gh"      "gh --version"
check_cmd "jq"      "jq"      "jq --version"
check_cmd "fzf"     "fzf"     "fzf --version"
check_cmd "eza"     "eza"     "eza --version"
check_cmd "zoxide"  "zoxide"  "zoxide --version"
check_cmd "direnv"  "direnv"  "direnv version"
echo ""

# Runtime
echo "  Runtime"
echo "  -------"

# nvm e uma funcao shell - checa pelo diretorio
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -d "$NVM_DIR/versions/node" ] && [ "$(ls -A "$NVM_DIR/versions/node" 2>/dev/null)" ]; then
  nvm_versions="$(ls "$NVM_DIR/versions/node" | wc -l | tr -d ' ') versoes"
  echo -e "  ${GREEN}[OK]${NC}   nvm ($nvm_versions)"
  PASS_COUNT=$((PASS_COUNT + 1))
  JSON_ITEMS+=("{\"name\":\"nvm\",\"status\":\"ok\",\"version\":\"$nvm_versions\"}")

  # node via nvm: busca o binario na versao default
  default_node="$(ls -d "$NVM_DIR/versions/node/"* 2>/dev/null | sort -V | tail -1)"
  if [ -n "$default_node" ] && [ -x "$default_node/bin/node" ]; then
    node_ver="$("$default_node/bin/node" --version 2>/dev/null)"
    echo -e "  ${GREEN}[OK]${NC}   node ($node_ver via nvm)"
    PASS_COUNT=$((PASS_COUNT + 1))
    JSON_ITEMS+=("{\"name\":\"node\",\"status\":\"ok\",\"version\":\"$node_ver\"}")
  fi
elif [ -d "$NVM_DIR" ] && [ -f "$NVM_DIR/nvm.sh" ]; then
  echo -e "  ${YELLOW}[WARN]${NC} nvm instalado mas sem versoes do Node"
  WARN_COUNT=$((WARN_COUNT + 1))
  JSON_ITEMS+=("{\"name\":\"nvm\",\"status\":\"warn\",\"version\":\"no versions\"}")
else
  echo -e "  ${RED}[FAIL]${NC} nvm nao encontrado"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  JSON_ITEMS+=("{\"name\":\"nvm\",\"status\":\"fail\",\"version\":null}")

  # tenta node global como fallback
  check_cmd "node" "node" "node --version"
fi
echo ""

# Aplicacoes (essenciais)
echo "  Aplicacoes"
echo "  ----------"
check_app "iTerm2"          "/Applications/iTerm.app"
check_app "Slack"           "/Applications/Slack.app"
check_app "Claude Desktop"  "/Applications/Claude.app"
check_cmd "Claude Code" "claude" "claude --version"
check_app "OpenVPN Connect" "/Applications/OpenVPN Connect/OpenVPN Connect.app"
check_cmd "VS Code"  "code" "code --version"
check_cmd "Docker"   "docker" "docker --version"
echo ""

# Aplicacoes (opcionais)
echo "  Aplicacoes (opcionais)"
echo "  ----------------------"
check_optional_app "Google Chrome"    "/Applications/Google Chrome.app"
check_optional_app "MongoDB Compass"  "/Applications/MongoDB Compass.app"
check_optional_app "Redis Insight"    "/Applications/Redis Insight.app"
check_optional_app "Postman"          "/Applications/Postman.app"
echo ""

# Servicos
echo "  Servicos"
echo "  --------"
check_service "Docker daemon" "docker info"
echo ""

# Configuracao corporativa
CORP_DOMAIN="kruzer.ai"

echo "  Configuracao (@${CORP_DOMAIN})"
echo "  --------"

# Git email
git_email="$(git config --global user.email 2>/dev/null || echo "")"
if [ -n "$git_email" ] && [[ "$git_email" == *"@${CORP_DOMAIN}" ]]; then
  echo -e "  ${GREEN}[OK]${NC}   git email ($git_email)"
  PASS_COUNT=$((PASS_COUNT + 1))
  JSON_ITEMS+=("{\"name\":\"git_email\",\"status\":\"ok\",\"version\":\"$git_email\"}")
elif [ -n "$git_email" ]; then
  echo -e "  ${YELLOW}[WARN]${NC} git email ($git_email) - esperado @${CORP_DOMAIN}"
  WARN_COUNT=$((WARN_COUNT + 1))
  JSON_ITEMS+=("{\"name\":\"git_email\",\"status\":\"warn\",\"version\":\"$git_email\"}")
else
  echo -e "  ${RED}[FAIL]${NC} git email nao configurado"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  JSON_ITEMS+=("{\"name\":\"git_email\",\"status\":\"fail\",\"version\":null}")
fi

# Git name
git_name="$(git config --global user.name 2>/dev/null || echo "")"
if [ -n "$git_name" ]; then
  echo -e "  ${GREEN}[OK]${NC}   git name ($git_name)"
  PASS_COUNT=$((PASS_COUNT + 1))
  JSON_ITEMS+=("{\"name\":\"git_name\",\"status\":\"ok\",\"version\":\"$git_name\"}")
else
  echo -e "  ${RED}[FAIL]${NC} git name nao configurado"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  JSON_ITEMS+=("{\"name\":\"git_name\",\"status\":\"fail\",\"version\":null}")
fi

# GitHub CLI auth
gh_user="$(gh auth status 2>&1 || true)"
if echo "$gh_user" | grep -q "Logged in"; then
  gh_account="$(echo "$gh_user" | grep -o 'account [^ ]*' | head -1 | cut -d' ' -f2)"
  echo -e "  ${GREEN}[OK]${NC}   gh auth ($gh_account)"
  PASS_COUNT=$((PASS_COUNT + 1))
  JSON_ITEMS+=("{\"name\":\"gh_auth\",\"status\":\"ok\",\"version\":\"$gh_account\"}")
else
  echo -e "  ${YELLOW}[WARN]${NC} gh nao autenticado - execute: gh auth login"
  WARN_COUNT=$((WARN_COUNT + 1))
  JSON_ITEMS+=("{\"name\":\"gh_auth\",\"status\":\"warn\",\"version\":null}")
fi

# NPM_TOKEN
if [ -n "${NPM_TOKEN:-}" ]; then
  echo -e "  ${GREEN}[OK]${NC}   NPM_TOKEN configurado"
  PASS_COUNT=$((PASS_COUNT + 1))
  JSON_ITEMS+=("{\"name\":\"npm_token\",\"status\":\"ok\",\"version\":\"set\"}")
else
  echo -e "  ${RED}[FAIL]${NC} NPM_TOKEN nao definido - necessario para pacotes privados"
  FAIL_COUNT=$((FAIL_COUNT + 1))
  JSON_ITEMS+=("{\"name\":\"npm_token\",\"status\":\"fail\",\"version\":null}")
fi
echo ""

# Dotfiles
echo "  Dotfiles"
echo "  --------"
if [ -L "$HOME/.zshrc" ]; then
  zshrc_target="$(readlink "$HOME/.zshrc")"
  echo -e "  ${GREEN}[OK]${NC}   .zshrc -> $zshrc_target"
  PASS_COUNT=$((PASS_COUNT + 1))
else
  echo -e "  ${YELLOW}[WARN]${NC} .zshrc nao e um symlink (dotfiles nao configurados)"
  WARN_COUNT=$((WARN_COUNT + 1))
fi
echo ""

# Proximos passos (so mostra se tem pendencias de configuracao)
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

if [ -d "/Applications/OpenVPN Connect/OpenVPN Connect.app" ] && ! ls ~/Library/Application\ Support/OpenVPN\ Connect/profiles/*.ovpn >/dev/null 2>&1; then
  NEXT_STEPS+=("  Configurar VPN: abra OpenVPN Connect e importe o perfil .ovpn (solicite ao time de infra)")
fi

if [ ${#NEXT_STEPS[@]} -gt 0 ]; then
  echo "  Proximos passos"
  echo "  ----------------"
  for step in "${NEXT_STEPS[@]}"; do
    echo -e "  ${YELLOW}▸${NC}$step"
  done
  echo ""
fi

# Resumo
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Passou: $PASS_COUNT  |  Avisos: $WARN_COUNT  |  Falhou: $FAIL_COUNT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Gera JSON report
REPORT_FILE="$LOG_DIR/check-result.json"
{
  echo "{"
  echo "  \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\","
  echo "  \"os\": \"$(uname -s) $(uname -r)\","
  echo "  \"arch\": \"$(uname -m)\","
  echo "  \"version\": \"$(cat "$DEVSETUP_DIR/VERSION" 2>/dev/null || echo "unknown")\","
  echo "  \"passed\": $PASS_COUNT,"
  echo "  \"warnings\": $WARN_COUNT,"
  echo "  \"failed\": $FAIL_COUNT,"
  echo "  \"checks\": ["
  # Join array with commas
  for i in "${!JSON_ITEMS[@]}"; do
    if [ "$i" -lt $((${#JSON_ITEMS[@]} - 1)) ]; then
      echo "    ${JSON_ITEMS[$i]},"
    else
      echo "    ${JSON_ITEMS[$i]}"
    fi
  done
  echo "  ]"
  echo "}"
} > "$REPORT_FILE"

echo "Relatorio salvo em $REPORT_FILE"
echo ""

if [ $FAIL_COUNT -gt 0 ]; then
  exit 1
else
  exit 0
fi
