# Dev Setup

Bootstrap para configurar ambiente de desenvolvimento (Mac).

## 🚀 Setup rápido

```bash
git clone <repo>
cd dev-setup
chmod +x bootstrap/install.sh
./bootstrap/install.sh
./check.sh
```

## 📦 O que será instalado

### CLI
- git
- wget
- jq
- htop
- fzf
- zoxide
- nvm
- direnv

### Apps
- Google Chrome
- iTerm2
- VS Code
- Docker
- MongoDB Compass
- Redis Insight

## ⚡ Node automático por projeto

```bash
echo "18" > .nvmrc
echo "use_nvm" > .envrc
direnv allow
```

## 🧭 Recomendações

- Use `z` para navegar
- Use `Ctrl + R` para histórico
- Use `node-init` para setup inicial
