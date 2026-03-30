# Dev Setup

Setup automatizado para maquinas de desenvolvimento - Kruzer.

## Instalacao

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/kruzer-corp/dev-setup/main/install.sh | bash
cd ~/.dev-setup && ./bootstrap/install.sh
```

### Linux (Ubuntu / Debian)

Requisitos: `sudo`, `curl`, `systemd` (Docker como servico), arquitetura suportada pelos repositorios oficiais (Docker, VS Code, GitHub CLI).

```bash
curl -fsSL https://raw.githubusercontent.com/kruzer-corp/dev-setup/main/install.sh | bash
cd ~/.dev-setup && ./bootstrap/install.sh
```

Outras distribuicoes: o script informa que ainda nao sao suportadas.

### Variaveis de ambiente (macOS e Linux)

| Variavel | Efeito |
|----------|--------|
| `DEVSETUP_NONINTERACTIVE=1` | Nao pergunta por apps opcionais; pula a menos que `DEVSETUP_INSTALL_OPTIONAL=1`. |
| `DEVSETUP_INSTALL_OPTIONAL=1` | Com nao interativo, instala apps opcionais (casks no macOS; snap/.deb no Linux quando disponivel). |

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

No Linux, **eza** e **zoxide** dependem do que o `apt` da sua versao oferece; se nao houver pacote, o setup apenas avisa (e o `check` marca aviso, nao falha critica).

### Aplicacoes (macOS)

| App | Para que serve |
|-----|----------------|
| **iTerm2** | Terminal avancado para macOS |
| **Slack** | Comunicacao do time |
| **Claude Desktop** | Assistente IA (chat) |
| **Claude Code** | Assistente IA no terminal |
| **OpenVPN Connect** | Cliente VPN para acesso a rede interna |
| **VS Code** | Editor de codigo |
| **Docker Desktop** | Containers para servicos locais |

### Aplicacoes (Linux)

| App | Para que serve |
|-----|----------------|
| **Slack** | Via `snap` quando disponivel |
| **VS Code** | Pacote `code` (repositorio Microsoft) |
| **Docker Engine** | `docker-ce` + plugin Compose (repositorio Docker) — nao e Docker Desktop |
| **Claude Desktop / OpenVPN Connect** | Nao automatizados nesta versao; use o cliente indicado pela infra |

### Aplicacoes opcionais (pergunta antes)

| App | Para que serve |
|-----|----------------|
| **Google Chrome** | Navegador web |
| **MongoDB Compass** | GUI para bancos MongoDB |
| **Redis Insight** | GUI para instancias Redis |
| **Postman** | Teste de APIs |

No Linux, opcionais usam principalmente **snap** (e Chrome via `.deb` em amd64 quando selecionado).

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

Necessario para pacotes privados. Solicite ao time de infra e adicione ao `~/.zshrc.local`:

```bash
echo 'export NPM_TOKEN="seu-token"' >> ~/.zshrc.local
source ~/.zshrc.local
```

### OpenVPN

**macOS:** solicite o `.ovpn`, abra o OpenVPN Connect e importe o perfil.

**Linux:** depende do padrao da empresa (NetworkManager, `openvpn3`, etc.); o README do time de infra deve ser seguido.

### Docker

**macOS:** o setup tenta abrir o Docker Desktop. Para reiniciar:

```bash
open -a Docker
```

**Linux:** o usuario e adicionado ao grupo `docker`; em geral e preciso **logout/login** (ou novo shell) para `docker` sem `sudo`. Servico: `sudo systemctl status docker`.

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

Requer **jq** instalado (gera JSON com strings escapadas corretamente). Relatorio: `~/.dev-setup/logs/check-result.json`.

## Estrutura

```
dev-setup/
  install.sh           # Entrypoint (curl | bash)
  VERSION              # Versao semver
  lib/common.sh        # Logging e utils
  packages/
    linux/
      ubuntu-packages.txt   # Lista apt base (Linux)
  bootstrap/
    install.sh         # Orquestrador (macOS / Linux)
    macos.sh           # Setup macOS
    linux.sh           # Detecta distro Linux
    linux-ubuntu.sh    # Setup Ubuntu/Debian
    Brewfile           # Pacotes Homebrew (macOS)
    check.sh           # Validacao
    check-lib.sh       # Helpers do check + JSON (jq)
  dotfiles/zsh/
    .zshrc             # Config do shell
    aliases.zsh        # Atalhos do time
    functions.zsh      # Funcoes utilitarias
```
