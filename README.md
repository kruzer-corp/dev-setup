# Dev Setup

Setup automatizado para maquinas de desenvolvimento - Kruzer.

## Instalacao

```bash
curl -fsSL https://raw.githubusercontent.com/kruzer-corp/dev-setup/main/install.sh | bash
cd ~/.dev-setup && ./bootstrap/install.sh
```

## O que e instalado

### CLI Tools

| Ferramenta | Para que serve |
|-----------|----------------|
| **git** | Controle de versao |
| **gh** | GitHub CLI - PRs, issues e code review pelo terminal |
| **jq** | Processador JSON para linha de comando |
| **fzf** | Busca fuzzy (historico, arquivos, branches) |
| **eza** | Substituto moderno do `ls` com cores e git status |
| **zoxide** | `cd` inteligente - aprende os diretorios que voce mais usa |
| **nvm** | Gerenciador de versoes do Node.js (troca automatica via `.nvmrc`) |
| **direnv** | Carrega variaveis de ambiente automaticamente por diretorio |

### Aplicacoes

| App | Para que serve |
|-----|----------------|
| **iTerm2** | Terminal avancado para macOS |
| **Slack** | Comunicacao do time |
| **Claude Desktop** | Assistente IA (chat) |
| **Claude Code** | Assistente IA no terminal |
| **OpenVPN Connect** | Cliente VPN para acesso a rede interna |
| **VS Code** | Editor de codigo |
| **Docker Desktop** | Containers para servicos locais |

### Aplicacoes opcionais (pergunta antes)

| App | Para que serve |
|-----|----------------|
| **Google Chrome** | Navegador web |
| **MongoDB Compass** | GUI para bancos MongoDB |
| **Redis Insight** | GUI para instancias Redis |
| **Postman** | Teste de APIs |

## Pos-instalacao

Ao final, o setup mostra os passos pendentes. Referencia rapida:

### Git

```bash
git config --global user.name "Seu Nome"
git config --global user.email "seu@kruzer.ai"
```

### GitHub CLI

```bash
gh auth login
```

### NPM Token

Necessario para pacotes privados. Adicione ao `~/.zshrc.local`:

```bash
echo 'export NPM_TOKEN="seu-token"' >> ~/.zshrc.local
source ~/.zshrc.local
```

### OpenVPN

1. Solicite seu perfil `.ovpn` ao time de infra
2. Abra o OpenVPN Connect
3. Importe o arquivo `.ovpn`

### Docker

O setup inicia o Docker Desktop automaticamente. Se precisar reiniciar:

```bash
open -a Docker
```

## Customizacoes pessoais

O `.zshrc` do repo e compartilhado pelo time. Para adicionar configs pessoais (aliases, PATHs, tokens), crie o arquivo `~/.zshrc.local`:

```bash
# ~/.zshrc.local (nao versionado, so seu)
export MEU_TOKEN="xxx"
alias meuatalho="cd ~/projetos/meu-repo"
```

Esse arquivo e carregado automaticamente no final do `.zshrc`.

## Validacao

Para verificar se tudo esta configurado:

```bash
~/.dev-setup/bootstrap/check.sh
```

Relatorio salvo em `~/.dev-setup/logs/check-result.json`.

## Estrutura

```
dev-setup/
  install.sh           # Entrypoint (curl | bash)
  VERSION              # Versao semver
  lib/common.sh        # Logging e utils
  bootstrap/
    install.sh         # Orquestrador
    macos.sh           # Setup macOS
    Brewfile           # Pacotes Homebrew
    check.sh           # Validacao
  dotfiles/zsh/
    .zshrc             # Config do shell
    aliases.zsh        # Atalhos do time
    functions.zsh      # Funcoes utilitarias
```
