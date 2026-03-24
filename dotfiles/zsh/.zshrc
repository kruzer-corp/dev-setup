export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"

eval "$(direnv hook zsh)"
eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"

HISTSIZE=10000
SAVEHIST=10000
setopt SHARE_HISTORY

autoload -Uz compinit && compinit

source ~/dotfiles/zsh/aliases.zsh
source ~/dotfiles/zsh/functions.zsh
