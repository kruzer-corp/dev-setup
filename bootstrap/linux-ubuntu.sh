#!/bin/bash
# bootstrap/linux-ubuntu.sh - Setup Ubuntu/Debian via apt, Docker Engine, VS Code, nvm.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEVSETUP_DIR="${DEVSETUP_DIR:-$HOME/.dev-setup}"

# shellcheck source=../lib/common.sh
source "$DEVSETUP_DIR/lib/common.sh"

if [ "$(uname)" != "Linux" ]; then
  log_error "linux-ubuntu.sh requer Linux"
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  log_error "sudo e necessario para instalar pacotes"
  exit 1
fi

# Prefer non-interactive apt when requested
export DEBIAN_FRONTEND=noninteractive

apt_update() {
  sudo apt-get update -y
}

apt_install() {
  sudo apt-get install -y "$@"
}

# Pacotes base (arquivo em packages/linux; fallback se path errado)
install_base_packages() {
  local list_file="$DEVSETUP_DIR/packages/linux/ubuntu-packages.txt"
  if [ ! -f "$list_file" ]; then
    log_error "Arquivo de pacotes nao encontrado: $list_file"
    return 1
  fi
  local pkgs
  pkgs="$(grep -v '^#' "$list_file" | grep -v '^[[:space:]]*$' | tr '\n' ' ')"
  if [ -z "${pkgs// }" ]; then
    log_warn "Nenhum pacote listado em $list_file"
    return 0
  fi
  log_info "Instalando pacotes base (apt)..."
  apt_install $pkgs
}

# eza: disponivel em versoes recentes do Ubuntu; ignorar falha em distros antigas
try_install_eza() {
  if command -v eza >/dev/null 2>&1; then
    log_success "eza ja instalado"
    return 0
  fi
  if apt-cache show eza >/dev/null 2>&1; then
    apt_install eza && log_success "eza instalado" || log_warn "Falha ao instalar eza (opcional)"
  else
    log_warn "Pacote eza nao disponivel nesta distro - pulando (opcional)"
  fi
  return 0
}

try_install_zoxide() {
  if command -v zoxide >/dev/null 2>&1; then
    log_success "zoxide ja instalado"
    return 0
  fi
  if apt-cache show zoxide >/dev/null 2>&1; then
    apt_install zoxide && log_success "zoxide instalado" || log_warn "Falha ao instalar zoxide (opcional)"
  else
    log_warn "Pacote zoxide nao disponivel no apt - instale manualmente ou use backports (opcional)"
  fi
  return 0
}

setup_docker_apt_repo() {
  local docker_distro="ubuntu"
  [ "$ID" = "debian" ] && docker_distro="debian"

  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL "https://download.docker.com/linux/${docker_distro}/gpg" -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${docker_distro} ${VERSION_CODENAME} stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
}

setup_microsoft_code_repo() {
  local ms_gpg="/etc/apt/trusted.gpg.d/microsoft-code.gpg"
  if [ -f "$ms_gpg" ]; then
    return 0
  fi
  curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o "$ms_gpg"
  echo "deb [arch=$(dpkg --print-architecture) signed-by=${ms_gpg}] https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
}

setup_github_cli_repo() {
  if [ -f /etc/apt/sources.list.d/github-cli.list ]; then
    return 0
  fi
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
}

install_third_party_stack() {
  # shellcheck source=/dev/null
  source /etc/os-release
  setup_github_cli_repo
  setup_microsoft_code_repo
  setup_docker_apt_repo
  apt_update
  apt_install gh code docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_ohmyzsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log_success "Oh My Zsh ja instalado"
    return 0
  fi
  log_info "Instalando Oh My Zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  log_success "Oh My Zsh instalado"
}

setup_dotfiles() {
  local ZSHRC="$HOME/.zshrc"
  local TARGET="$DEVSETUP_DIR/dotfiles/zsh/.zshrc"

  if [ ! -f "$TARGET" ]; then
    log_error "Arquivo .zshrc nao encontrado em $TARGET"
    return 1
  fi

  if [ -f "$ZSHRC" ] && [ ! -L "$ZSHRC" ]; then
    local backup="$ZSHRC.backup.$(date +%Y%m%d%H%M%S)"
    mv "$ZSHRC" "$backup"
    log_info "Backup do .zshrc criado em $backup"
  fi

  ln -sf "$TARGET" "$ZSHRC"
  log_success "Dotfiles configurados (.zshrc -> $TARGET)"
}

install_nvm_and_node() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
  if [ ! -s "$NVM_DIR/nvm.sh" ]; then
    log_info "Instalando nvm..."
    curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  fi
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

  if command -v nvm >/dev/null 2>&1; then
    log_info "Instalando Node LTS via nvm..."
    nvm install --lts
    nvm alias default 'lts/*'
    log_success "Node $(node --version) instalado"
  else
    log_warn "nvm nao carregado nesta sessao; abra um novo terminal e rode: nvm install --lts"
  fi
}

configure_docker_service() {
  if ! command -v docker >/dev/null 2>&1; then
    log_warn "Docker CLI nao encontrado - pulando servico"
    return 0
  fi
  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable docker >/dev/null 2>&1 || true
    sudo systemctl start docker || true
  fi
  if id -nG "$USER" | tr ' ' '\n' | grep -qx docker; then
    log_success "Usuario ja no grupo docker"
  else
    sudo usermod -aG docker "$USER"
    log_warn "Usuario adicionado ao grupo docker - faca logout/login para usar docker sem sudo"
  fi
  if docker info >/dev/null 2>&1; then
    log_success "Docker daemon acessivel"
  else
    log_warn "Docker instalado mas daemon nao acessivel nesta sessao (tente novo login ou sudo docker info)"
  fi
}

install_slack() {
  if command -v slack >/dev/null 2>&1 || snap list slack >/dev/null 2>&1; then
    log_success "Slack parece disponivel"
    return 0
  fi
  if command -v snap >/dev/null 2>&1; then
    sudo snap install slack --classic || log_warn "Falha ao instalar Slack via snap"
  else
    log_warn "Instale Slack manualmente (snap recomendado: sudo snap install slack --classic)"
  fi
  return 0
}

OPTIONAL_SNAPS=(
  "mongodb-compass:MongoDB Compass"
  "redisinsight:Redis Insight"
  "postman:Postman"
)

install_optional_apps_linux() {
  if [ "${DEVSETUP_NONINTERACTIVE:-0}" = "1" ]; then
    if [ "${DEVSETUP_INSTALL_OPTIONAL:-0}" = "1" ]; then
      log_info "Modo nao interativo: instalando opcionais via snap quando disponivel..."
      if command -v snap >/dev/null 2>&1; then
        for entry in "${OPTIONAL_SNAPS[@]}"; do
          local snap_name="${entry%%:*}"
          if ! snap list "$snap_name" >/dev/null 2>&1; then
            sudo snap install "$snap_name" || log_warn "Falha ao instalar snap $snap_name"
          fi
        done
        if [ "$(dpkg --print-architecture)" = "amd64" ]; then
          local chrome_deb
          chrome_deb="$(mktemp /tmp/google-chrome.XXXXXX.deb)"
          curl -fsSL -o "$chrome_deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
          sudo apt-get install -y "$chrome_deb" || log_warn "Falha ao instalar Google Chrome"
          rm -f "$chrome_deb"
        else
          log_warn "Google Chrome .deb pulado (arquitetura nao amd64)"
        fi
      else
        log_warn "snap nao encontrado - opcionais nao instalados"
      fi
    else
      log_info "Modo nao interativo: pulando apps opcionais (DEVSETUP_INSTALL_OPTIONAL=1 para instalar)"
    fi
    return 0
  fi

  log_info "Apps opcionais (snap / Chrome):"
  echo ""
  if command -v snap >/dev/null 2>&1; then
    for entry in "${OPTIONAL_SNAPS[@]}"; do
      local sname="${entry%%:*}"
      local sdesc="${entry#*:}"
      if snap list "$sname" >/dev/null 2>&1; then
        log_success "$sdesc ja instalado"
        continue
      fi
      printf "  Instalar %s? [s/N] " "$sdesc"
      read -r answer </dev/tty
      if [[ "$answer" =~ ^[sS]$ ]]; then
        sudo snap install "$sname"
      fi
    done
  else
    log_warn "snap nao encontrado - pulei snaps opcionais"
  fi

  if [ "$(dpkg --print-architecture)" = "amd64" ] && ! command -v google-chrome >/dev/null 2>&1; then
    printf "  Instalar Google Chrome? [s/N] "
    read -r answer </dev/tty
    if [[ "$answer" =~ ^[sS]$ ]]; then
      local chrome_deb
      chrome_deb="$(mktemp /tmp/google-chrome.XXXXXX.deb)"
      curl -fsSL -o "$chrome_deb" https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
      sudo apt-get install -y "$chrome_deb"
      rm -f "$chrome_deb"
    fi
  fi
}

log_corporate_skips() {
  log_warn "Claude Desktop/OpenVPN Connect nao sao automatizados no Linux nesta versao - veja README."
  return 0
}

# shellcheck source=/dev/null
source /etc/os-release

run_step "Atualizar apt" apt_update
run_step "Pacotes base (ubuntu-packages.txt)" install_base_packages
run_step "eza (opcional)" try_install_eza
run_step "zoxide (opcional)" try_install_zoxide
run_step "Repos Docker / VS Code / gh + instalacao" install_third_party_stack
run_step "Oh My Zsh" install_ohmyzsh
run_step "Dotfiles" setup_dotfiles
run_step "Docker (servico e grupo)" configure_docker_service
run_step "Slack (snap se disponivel)" install_slack
run_step "NVM + Node" install_nvm_and_node
run_step "Apps opcionais" install_optional_apps_linux
run_step "Avisos corporativos" log_corporate_skips

print_summary || exit 1
