# Homebrew (precisa ser primeiro - coloca /opt/homebrew/bin no PATH)
if [ -f "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Oh My Zsh
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git docker docker-compose)
[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

# Zoxide
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# Direnv
command -v direnv >/dev/null 2>&1 && eval "$(direnv hook zsh)"

# Load modules
DOTFILES_DIR="$HOME/.dev-setup/dotfiles/zsh"

[ -f "$DOTFILES_DIR/aliases.zsh" ] && source "$DOTFILES_DIR/aliases.zsh"
[ -f "$DOTFILES_DIR/functions.zsh" ] && source "$DOTFILES_DIR/functions.zsh"

# Auto use Node version (so ativa se nvm estiver carregado)
if type nvm >/dev/null 2>&1; then
  autoload -U add-zsh-hook

  load-nvmrc() {
    local node_version="$(nvm version)"
    local nvmrc_path="$(nvm_find_nvmrc)"

    if [ -n "$nvmrc_path" ]; then
      local nvmrc_node_version=$(nvm version "$(cat "$nvmrc_path")")

      if [ "$nvmrc_node_version" = "N/A" ]; then
        nvm install
      elif [ "$nvmrc_node_version" != "$node_version" ]; then
        nvm use
      fi
    fi
  }

  add-zsh-hook chpwd load-nvmrc
  load-nvmrc
fi
