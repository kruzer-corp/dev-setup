#!/bin/bash
# bootstrap/macos.sh - Setup completo para macOS
# Instala ferramentas via Homebrew, configura dotfiles e valida o ambiente.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVSETUP_DIR="${DEVSETUP_DIR:-$HOME/.dev-setup}"

source "$DEVSETUP_DIR/lib/common.sh"
require_macos

# ─── Etapa 1: Xcode CLI Tools ─────────────────────────────────────────────────

install_xcode_tools() {
  if ! xcode-select -p >/dev/null 2>&1; then
    log_info "Instalando Xcode CLI tools (pode pedir senha de admin)..."
    xcode-select --install 2>/dev/null || true
    log_warn "Aguarde a instalacao do Xcode CLI tools e re-execute o script"
    exit 1
  fi
  log_success "Xcode CLI tools ja instalado"
}

# ─── Etapa 2: Homebrew ────────────────────────────────────────────────────────

install_homebrew() {
  # Checa o binario direto em vez de PATH (pode nao estar no PATH em sessao limpa)
  if [ ! -f "/opt/homebrew/bin/brew" ] && [ ! -f "/usr/local/bin/brew" ]; then
    log_info "Instalando Homebrew (pode pedir senha de admin)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # Garante brew no PATH para esta sessao
  if [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -f "/usr/local/bin/brew" ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi

  log_success "Homebrew $(brew --version | head -1)"
  brew update
}

# ─── Etapa 3: Pacotes via Brewfile ─────────────────────────────────────────────

install_packages() {
  log_info "Instalando pacotes via Brewfile..."
  brew bundle --file="$SCRIPT_DIR/Brewfile"
}

# ─── Etapa 4: Oh My Zsh ────────────────────────────────────────────────────────

install_ohmyzsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log_success "Oh My Zsh ja instalado"
    return 0
  fi

  log_info "Instalando Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  log_success "Oh My Zsh instalado"
}

# ─── Etapa 5: Dotfiles ────────────────────────────────────────────────────────

setup_dotfiles() {
  local ZSHRC="$HOME/.zshrc"
  local TARGET="$DEVSETUP_DIR/dotfiles/zsh/.zshrc"

  if [ ! -f "$TARGET" ]; then
    log_error "Arquivo .zshrc nao encontrado em $TARGET"
    return 1
  fi

  # Backup com timestamp (nunca perde o original)
  if [ -f "$ZSHRC" ] && [ ! -L "$ZSHRC" ]; then
    local backup="$ZSHRC.backup.$(date +%Y%m%d%H%M%S)"
    mv "$ZSHRC" "$backup"
    log_info "Backup do .zshrc criado em $backup"
  fi

  ln -sf "$TARGET" "$ZSHRC"
  log_success "Dotfiles configurados (.zshrc -> $TARGET)"
}

# ─── Etapa 5: Docker ──────────────────────────────────────────────────────────

start_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    log_warn "Docker nao encontrado - pulando"
    return 0
  fi

  if ! docker info >/dev/null 2>&1; then
    log_info "Iniciando Docker Desktop..."
    open -a Docker || true
    log_warn "Aguarde o Docker iniciar completamente"
  else
    log_success "Docker daemon rodando"
  fi
}

# ─── Etapa 6: NVM + Node ──────────────────────────────────────────────────────

setup_nvm() {
  export NVM_DIR="$HOME/.nvm"
  mkdir -p "$NVM_DIR"

  # Carrega nvm para a sessao atual (Apple Silicon / Intel Homebrew)
  local NVM_SH=""
  if [ -s "/opt/homebrew/opt/nvm/nvm.sh" ]; then
    NVM_SH="/opt/homebrew/opt/nvm/nvm.sh"
  elif [ -s "/usr/local/opt/nvm/nvm.sh" ]; then
    NVM_SH="/usr/local/opt/nvm/nvm.sh"
  fi
  if [ -n "$NVM_SH" ]; then
    # shellcheck source=/dev/null
    source "$NVM_SH"
  fi

  if command -v nvm >/dev/null 2>&1; then
    log_info "Instalando Node LTS via nvm..."
    nvm install --lts
    nvm alias default lts/*
    log_success "Node $(node --version) instalado"
  else
    log_warn "nvm nao encontrado. Reinicie o terminal e execute: nvm install --lts"
  fi
}

# ─── Etapa 8: Apps opcionais (prompt interativo) ──────────────────────────────

OPTIONAL_APPS=(
  "google-chrome:Google Chrome:Navegador web"
  "mongodb-compass:MongoDB Compass:GUI para gerenciar bancos MongoDB"
  "redis-insight:Redis Insight:GUI para gerenciar instancias Redis"
  "postman:Postman:Teste e documentacao de APIs"
)

install_optional_apps() {
  if [ "${DEVSETUP_NONINTERACTIVE:-0}" = "1" ]; then
    if [ "${DEVSETUP_INSTALL_OPTIONAL:-0}" = "1" ]; then
      log_info "Modo nao interativo: instalando todos os apps opcionais (DEVSETUP_INSTALL_OPTIONAL=1)..."
      local to_install_all=()
      for entry in "${OPTIONAL_APPS[@]}"; do
        local cask_all="${entry%%:*}"
        if ! brew list --cask "$cask_all" >/dev/null 2>&1; then
          to_install_all+=("$cask_all")
        fi
      done
      for cask in "${to_install_all[@]}"; do
        log_info "Instalando $cask..."
        brew install --cask "$cask"
      done
    else
      log_info "Modo nao interativo: pulando apps opcionais (defina DEVSETUP_INSTALL_OPTIONAL=1 para instalar)"
    fi
    return 0
  fi

  log_info "Apps opcionais disponiveis:"
  echo ""

  local to_install=()

  for entry in "${OPTIONAL_APPS[@]}"; do
    local cask="${entry%%:*}"
    local rest="${entry#*:}"
    local name="${rest%%:*}"
    local desc="${rest#*:}"

    # Pula se ja esta instalado
    if brew list --cask "$cask" >/dev/null 2>&1; then
      log_success "$name ja instalado"
      continue
    fi

    printf "  Instalar %s (%s)? [s/N] " "$name" "$desc"
    read -r answer </dev/tty
    if [[ "$answer" =~ ^[sS]$ ]]; then
      to_install+=("$cask")
    fi
  done

  if [ ${#to_install[@]} -gt 0 ]; then
    for cask in "${to_install[@]}"; do
      log_info "Instalando $cask..."
      brew install --cask "$cask"
    done
  else
    log_info "Nenhum app opcional selecionado"
  fi
}

# ─── Execucao ──────────────────────────────────────────────────────────────────

run_step "Xcode CLI Tools" install_xcode_tools
run_step "Homebrew" install_homebrew

# Garante brew no PATH para todas as etapas seguintes
# (necessario quando Homebrew acabou de ser instalado nesta sessao)
if [ -f "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

run_step "Pacotes (Brewfile)" install_packages
run_step "Oh My Zsh" install_ohmyzsh
run_step "Dotfiles" setup_dotfiles
run_step "Docker" start_docker
run_step "NVM + Node" setup_nvm
run_step "Apps opcionais" install_optional_apps

print_summary || exit 1
