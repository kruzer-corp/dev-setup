# Dev Setup

Setup automatizado para maquinas de desenvolvimento - Kruzer.

## Instalacao rapida

```bash
curl -fsSL https://raw.githubusercontent.com/kruzer-corp/dev-setup/main/install.sh | bash
cd ~/.dev-setup && ./bootstrap/install.sh
```

### Versao especifica

```bash
DEVSETUP_VERSION=1.0.0 curl -fsSL https://raw.githubusercontent.com/kruzer-corp/dev-setup/main/install.sh | bash
```

## O que e instalado

### CLI Tools (automatico)

| Ferramenta | O que faz |
|-----------|-----------|
| **git** | Controle de versao |
| **gh** | GitHub CLI - PRs, issues e code review pelo terminal |
| **jq** | Processador JSON para linha de comando (util para debug de APIs) |
| **fzf** | Busca fuzzy no terminal (historico, arquivos, branches) |
| **eza** | Substituto moderno do `ls` com cores e integracao git |
| **zoxide** | `cd` inteligente - aprende os diretorios que voce mais usa |
| **nvm** | Gerenciador de versoes do Node.js (troca automatica via `.nvmrc`) |
| **direnv** | Carrega variaveis de ambiente automaticamente por diretorio (`.envrc`) |

### Aplicacoes (automatico)

| App | O que faz |
|-----|-----------|
| **iTerm2** | Terminal avancado para macOS |
| **VS Code** | Editor de codigo padrao do time |
| **Docker Desktop** | Containers para rodar servicos localmente |

### Aplicacoes (opcional - pergunta antes de instalar)

| App | O que faz |
|-----|-----------|
| **Google Chrome** | Navegador web |
| **MongoDB Compass** | Interface grafica para gerenciar bancos MongoDB |
| **Redis Insight** | Interface grafica para gerenciar instancias Redis |
| **Postman** | Teste e documentacao de APIs |

### Configuracoes de shell

- Aliases compartilhados (`gs`, `d`, `dc`, `ll`)
- Troca automatica de versao do Node via `.nvmrc`
- Zoxide para navegacao rapida entre diretorios
- Direnv para variaveis de ambiente por projeto
- Node LTS pre-instalado via nvm

## Validacao

Apos a instalacao, o `check.sh` valida automaticamente todas as ferramentas.
Para re-executar manualmente:

```bash
~/.dev-setup/bootstrap/check.sh
```

O relatorio JSON e salvo em `~/.dev-setup/logs/check-result.json`.

## Estrutura

```
dev-setup/
  VERSION              # Versao semver
  install.sh           # Entrypoint remoto (curl | bash)
  lib/
    common.sh          # Logging, timing, error handling
  bootstrap/
    install.sh         # Orquestrador principal
    macos.sh           # Setup macOS
    Brewfile            # Fonte unica de pacotes
    check.sh           # Validacao do ambiente
  dotfiles/zsh/
    .zshrc             # Config principal do shell
    aliases.zsh        # Atalhos compartilhados
    functions.zsh      # Funcoes utilitarias
```

## Logs

Cada execucao gera um log em `~/.dev-setup/logs/` com timestamp.
