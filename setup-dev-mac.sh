#!/usr/bin/env bash
# =============================================================================
#  macOS Developer Machine Setup Script
#  Author: Generated for your MacBook Pro clean install
#  Run: chmod +x setup-dev-mac.sh && ./setup-dev-mac.sh
# =============================================================================

set -uo pipefail  # Fail on unset vars and pipe errors, but NOT on individual command failures

# ─────────────────────────────────────────────────────────────────────────────
# LOGGING — everything goes to terminal AND ~/dev-setup.log
# ─────────────────────────────────────────────────────────────────────────────
LOG_FILE="$HOME/dev-setup.log"
exec > >(tee -a "$LOG_FILE") 2>&1
echo "━━━ Setup started at $(date) ━━━"

# Quiet Homebrew during this run (the .zshrc heredoc sets these for future shells too)
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

# ─────────────────────────────────────────────────────────────────────────────
# COLORS & HELPERS
# ─────────────────────────────────────────────────────────────────────────────
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
RESET='\033[0m'

CHECKMARK="${GREEN}✔${RESET}"
ARROW="${CYAN}➜${RESET}"
WARN="${YELLOW}⚠${RESET}"
XMARK="${RED}✘${RESET}"

# Track failures so we can summarize at the end
FAILED_STEPS=()

section() {
  local title="$1"
  local width=54
  [[ ${#title} -ge $width ]] && width=$(( ${#title} + 2 ))
  local border
  border=$(printf '═%.0s' $(seq 1 $width))
  local pad
  pad=$(printf '%*s' $(( width - ${#title} )) '')
  echo ""
  echo -e "${BOLD}${BLUE}  ╔${border}╗${RESET}"
  echo -e "${BOLD}${BLUE}  ║ ${BOLD}${WHITE}${title}${pad}${BLUE} ║${RESET}"
  echo -e "${BOLD}${BLUE}  ╚${border}╝${RESET}"
  echo ""
}

info()    { echo -e "  ${ARROW} $1"; }
success() { echo -e "  ${CHECKMARK} $1"; }
warn()    { echo -e "  ${WARN}  ${YELLOW}$1${RESET}"; }
error()   { echo -e "  ${XMARK}  ${RED}$1${RESET}"; FAILED_STEPS+=("$1"); }

# Safe installer wrappers — log failures but never abort the whole script
install_brew_cask() {
  local pkg="$1"
  if brew list --cask "$pkg" &>/dev/null; then
    success "$pkg already installed"
  else
    info "Installing $pkg..."
    if brew install --cask "$pkg" --quiet 2>>"$LOG_FILE"; then
      success "$pkg"
    else
      error "brew cask install failed: $pkg (see $LOG_FILE)"
    fi
  fi
}

install_brew() {
  local pkg="$1"
  if brew list "$pkg" &>/dev/null; then
    success "$pkg already installed"
  else
    info "Installing $pkg..."
    if brew install "$pkg" --quiet 2>>"$LOG_FILE"; then
      success "$pkg"
    else
      error "brew install failed: $pkg (see $LOG_FILE)"
    fi
  fi
}

# ─────────────────────────────────────────────────────────────────────────────
# BANNER
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}  ██████╗ ███████╗██╗   ██╗    ███████╗███╗   ██╗██╗   ██╗${RESET}"
echo -e "${BOLD}${CYAN}  ██╔══██╗██╔════╝██║   ██║    ██╔════╝████╗  ██║██║   ██║${RESET}"
echo -e "${BOLD}${CYAN}  ██║  ██║█████╗  ██║   ██║    █████╗  ██╔██╗ ██║██║   ██║${RESET}"
echo -e "${BOLD}${CYAN}  ██║  ██║██╔══╝  ╚██╗ ██╔╝    ██╔══╝  ██║╚██╗██║╚██╗ ██╔╝${RESET}"
echo -e "${BOLD}${CYAN}  ██████╔╝███████╗ ╚████╔╝     ███████╗██║ ╚████║ ╚████╔╝ ${RESET}"
echo -e "${BOLD}${CYAN}  ╚═════╝ ╚══════╝  ╚═══╝      ╚══════╝╚═╝  ╚═══╝  ╚═══╝  ${RESET}"
echo ""
echo -e "${BOLD}${CYAN}  ╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${CYAN}  ║       macOS Developer Machine Setup                          ║${RESET}"
echo -e "${BOLD}${CYAN}  ║       Clean install -- fully loaded dev box                  ║${RESET}"
echo -e "${BOLD}${CYAN}  ╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${DIM}This script will set up your MacBook Pro for software development.${RESET}"
echo -e "  ${DIM}Estimated time: 20–40 minutes depending on your internet speed.${RESET}"
echo ""
echo -e "  ${WARN}  ${YELLOW}sudo access is required. You may be prompted for your password.${RESET}"
echo ""
read -rp "  Press ENTER to begin or Ctrl+C to cancel..."

# ─────────────────────────────────────────────────────────────────────────────
# 1. SUDO KEEPALIVE
# ─────────────────────────────────────────────────────────────────────────────
sudo -v
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# ─────────────────────────────────────────────────────────────────────────────
# 2. HOMEBREW (installs Xcode CLT automatically via NONINTERACTIVE)
# ─────────────────────────────────────────────────────────────────────────────
section "»  Homebrew"

if command -v brew &>/dev/null; then
  success "Homebrew already installed"
  info "Updating Homebrew..."
  brew update --quiet 2>>"$LOG_FILE" || warn "brew update failed — proceeding with cached formulae"
else
  info "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon
  if [[ "$(uname -m)" == "arm64" ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  success "Homebrew installed"
fi

brew analytics off   # Disable telemetry

# ─────────────────────────────────────────────────────────────────────────────
# 3. CLI TOOLS
# ─────────────────────────────────────────────────────────────────────────────
section "»  CLI Tools"

CLI_TOOLS=(
  # Core utilities (git/curl/zsh kept for latest versions over Apple's bundled ones)
  "zsh"              # Latest zsh (macOS ships older version)
  "git"              # Version control (newer than Xcode CLT version)
  "git-lfs"          # Git Large File Storage
  "gh"               # GitHub CLI
  "curl"             # HTTP client (newer than macOS bundled)
  "wget"             # File downloader
  "jq"               # JSON processor
  "yq"               # YAML processor
  "tree"             # Directory tree viewer
  "btop"             # Process monitor (modern top replacement)
  "bat"              # cat with syntax highlighting
  "eza"              # ls with superpowers (exa replacement)
  "fd"               # find alternative
  "fzf"              # Fuzzy finder
  "ripgrep"          # rg — fast grep
  "atuin"            # Magical shell history search with optional sync
  "delta"            # Better git diffs
  "tldr"             # Simplified man pages
  "hyperfine"        # Benchmarking tool
  "glow"             # Markdown in terminal
  "lazygit"          # Terminal UI for git
  "lazydocker"       # Terminal UI for Docker
  "zellij"           # Terminal multiplexer (modern tmux alternative)
  "micro"            # Friendly non-modal terminal editor
  "zoxide"           # Smarter cd command
  "direnv"           # Per-directory env vars
  "mkcert"           # Local HTTPS certs
  "httpie"           # User-friendly HTTP client
  "grpcurl"          # curl for gRPC
  "watch"            # Run commands periodically
  "yazi"             # Modern terminal file manager (Rust)
  "ncdu"             # Disk usage analyzer
  "duf"              # Better df
  "dust"             # Better du
  "procs"            # Better ps
  "gnu-sed"          # GNU sed (gsed)
  "coreutils"        # GNU core utilities
  "cmake"            # Build system
  "openssl"          # TLS/SSL toolkit
  "awscli"           # AWS CLI
  "azure-cli"        # Azure CLI
)

for tool in "${CLI_TOOLS[@]}"; do
  install_brew "$tool"
done

# ─────────────────────────────────────────────────────────────────────────────
# 4. SHELL: ZSH + OH MY ZSH + PLUGINS
# ─────────────────────────────────────────────────────────────────────────────
section "»  Shell: Zsh + Oh My Zsh + Plugins"

# Oh My Zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
  success "Oh My Zsh already installed"
else
  info "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  success "Oh My Zsh"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Powerlevel10k theme
if [ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
  success "Powerlevel10k already installed"
else
  info "Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$ZSH_CUSTOM/themes/powerlevel10k" --quiet
  success "Powerlevel10k"
fi

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  info "Installing zsh-autosuggestions..."
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions" --quiet
  success "zsh-autosuggestions"
else
  success "zsh-autosuggestions already installed"
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  info "Installing zsh-syntax-highlighting..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" --quiet
  success "zsh-syntax-highlighting"
else
  success "zsh-syntax-highlighting already installed"
fi

# zsh-completions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-completions" ]; then
  info "Installing zsh-completions..."
  git clone https://github.com/zsh-users/zsh-completions "$ZSH_CUSTOM/plugins/zsh-completions" --quiet
  success "zsh-completions"
else
  success "zsh-completions already installed"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 5. LANGUAGES & RUNTIMES
# ─────────────────────────────────────────────────────────────────────────────
section "»  Languages & Runtimes"

# Node.js via fnm (fast Node manager — 10-40x faster than nvm)
install_brew "fnm"
eval "$(fnm env)"
if fnm list 2>/dev/null | grep -qE 'v[0-9]+\.[0-9]+\.[0-9]+'; then
  success "Node.js already installed via fnm ($(fnm current 2>/dev/null || echo 'unknown'))"
else
  info "Installing Node.js LTS via fnm..."
  fnm install --lts
  fnm use lts-latest
  fnm default lts-latest
  success "Node.js LTS"
fi

# Python via uv (replaces pyenv + pip + poetry + pipx + virtualenv — 10-100x faster)
if command -v uv &>/dev/null; then
  success "uv already installed ($(uv --version))"
else
  info "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
  source "$HOME/.local/bin/env" 2>/dev/null || export PATH="$HOME/.local/bin:$PATH"
  success "uv — $(uv --version)"
fi

info "Installing latest Python via uv..."
uv python install 2>>"$LOG_FILE" && success "Python installed via uv" || error "Python install failed"

# Rust
if command -v rustup &>/dev/null; then
  success "Rust already installed"
else
  info "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --quiet
  source "$HOME/.cargo/env"
  success "Rust"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 6. PACKAGE MANAGERS & BUILD TOOLS
# ─────────────────────────────────────────────────────────────────────────────
section "»  Package Managers & Build Tools"

npm_globals=(
  "pnpm"          # Fast package manager
  "typescript"    # TypeScript compiler
  "tsx"           # TypeScript executor (replaces ts-node)
  "nodemon"       # Auto-restart Node
  "pm2"           # Process manager
  "serve"         # Static file server
  "vercel"        # Vercel CLI
)

for pkg in "${npm_globals[@]}"; do
  info "Installing npm global: $pkg..."
  npm install -g "$pkg" --quiet 2>>"$LOG_FILE" && success "$pkg" || warn "Failed: $pkg (see $LOG_FILE)"
done

# Python tools via uv (isolated, no pip needed)
UV_TOOLS=(
  "ruff"     # Linter + formatter (replaces black, isort, flake8)
  "mypy"     # Type checker
  "httpx"    # HTTP client
  "rich"     # Beautiful terminal output
  "ipython"  # Better Python REPL
)

for tool in "${UV_TOOLS[@]}"; do
  info "Installing uv tool: $tool..."
  uv tool install "$tool" 2>>"$LOG_FILE" && success "$tool" || warn "Failed: $tool (see $LOG_FILE)"
done

# ─────────────────────────────────────────────────────────────────────────────
# 7. GUI APPLICATIONS (via Homebrew Cask)
# ─────────────────────────────────────────────────────────────────────────────
section "»  Applications"

# ── Browsers ──────────────────────────────────────────────────────────────────
echo -e "  ${DIM}── Browsers${RESET}"
install_brew_cask "brave-browser"   # Brave

# ── IDEs & Editors ────────────────────────────────────────────────────────────
echo -e "  ${DIM}── IDEs & Editors${RESET}"
install_brew_cask "visual-studio-code"   # VS Code
install_brew_cask "jetbrains-toolbox"    # All JetBrains IDEs manager

# Ensure VS Code's `code` CLI is on PATH for this script run (the cask doesn't
# add it automatically — VS Code normally adds it via the GUI Command Palette).
VSCODE_BIN="/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
[[ -d "$VSCODE_BIN" ]] && export PATH="$VSCODE_BIN:$PATH"

# ── Terminals ─────────────────────────────────────────────────────────────────
echo -e "  ${DIM}── Terminals${RESET}"
install_brew_cask "warp"      # AI terminal
install_brew_cask "ghostty"   # Fast GPU terminal

# ── API & Network ─────────────────────────────────────────────────────────────
echo -e "  ${DIM}── API & Network${RESET}"
install_brew_cask "bruno"       # API client (open source, git-friendly)
install_brew_cask "proxyman"    # HTTP debugger / proxy
install_brew_cask "wireshark"   # Network analyzer

# ── Productivity ──────────────────────────────────────────────────────────────
echo -e "  ${DIM}── Productivity${RESET}"
install_brew_cask "raycast"   # Launcher + clipboard + window management + AI
install_brew_cask "slack"     # Team comms
install_brew_cask "zoom"      # Video calls
install_brew_cask "spotify"   # Music

# ── Utilities & System ────────────────────────────────────────────────────────
echo -e "  ${DIM}── Utilities${RESET}"
install_brew_cask "jordanbaird-ice" # Menu bar organizer (open-source Bartender alternative)
install_brew_cask "imageoptim"      # Image compression
install_brew_cask "istat-menus"     # System monitoring menubar
install_brew_cask "keka"            # File archiver (zip/rar/7z)
install_brew_cask "appcleaner"      # Uninstaller
install_brew_cask "alt-tab"         # Windows-style app switcher
install_brew_cask "utm"             # VM runner for Mac
install_brew_cask "orbstack"        # Docker engine + Linux VMs (Docker Desktop replacement)
install_brew_cask "1password"       # Password manager
install_brew_cask "transmit"        # File transfer (SFTP/S3)
install_brew_cask "cleanshot"       # Screenshot tool (license required)
install_brew_cask "claude"          # Anthropic's official Claude desktop app

# ── Fonts ─────────────────────────────────────────────────────────────────────
echo -e "  ${DIM}── Developer Fonts${RESET}"
install_brew_cask "font-jetbrains-mono-nerd-font"
install_brew_cask "font-fira-code-nerd-font"
install_brew_cask "font-hack-nerd-font"
install_brew_cask "font-cascadia-code-nerd-font"
install_brew_cask "font-meslo-lg-nerd-font"

# ─────────────────────────────────────────────────────────────────────────────
# 8. VS CODE EXTENSIONS
# ─────────────────────────────────────────────────────────────────────────────
section "»  VS Code Extensions"

if command -v code &>/dev/null; then
  EXTENSIONS=(
    "esbenp.prettier-vscode"
    "dbaeumer.vscode-eslint"
    "eamodio.gitlens"
    "mhutchie.git-graph"
    "github.copilot"
    "github.copilot-chat"
    "bradlc.vscode-tailwindcss"
    "ms-vscode.vscode-typescript-next"
    "prisma.prisma"
    "ms-python.python"
    "charliermarsh.ruff"
    "ms-python.mypy-type-checker"
    "rust-lang.rust-analyzer"
    "tamasfe.even-better-toml"
    "ms-vscode-remote.remote-ssh"
    "ms-vscode-remote.remote-containers"
    "ms-azuretools.vscode-docker"
    "redhat.vscode-yaml"
    "yzhang.markdown-all-in-one"
    "gruntfuggly.todo-tree"
    "streetsidesoftware.code-spell-checker"
    "usernamehw.errorlens"
    "formulahendry.auto-rename-tag"
    "christian-kohler.path-intellisense"
    "mikestead.dotenv"
    "yoavbls.pretty-ts-errors"
  )

  for ext in "${EXTENSIONS[@]}"; do
    code --install-extension "$ext" --force &>/dev/null && success "$ext" || warn "Skipped: $ext"
  done
else
  warn "VS Code CLI not found, skipping extensions (launch VS Code once first)"
fi

# ─────────────────────────────────────────────────────────────────────────────
# 9. GIT GLOBAL CONFIG
# ─────────────────────────────────────────────────────────────────────────────
section "»  Git Configuration"

GIT_NAME="Christopher Escalon"
GIT_EMAIL="escalonc@users.noreply.github.com"

git config --global user.name  "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

git config --global core.editor          "code --wait"
git config --global core.autocrlf        "input"
git config --global core.excludesfile    "$HOME/.gitignore_global"
git config --global init.defaultBranch   "main"
git config --global push.default         "current"
git config --global pull.rebase          "true"
git config --global rebase.autoStash     "true"
git config --global fetch.prune          "true"
git config --global diff.colorMoved      "default"
git config --global rerere.enabled       "true"
git config --global help.autocorrect     "1"
git config --global color.ui             "auto"

# Delta as pager
git config --global core.pager           "delta"
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate       "true"
git config --global delta.light          "false"
git config --global delta.side-by-side   "true"
git config --global delta.line-numbers   "true"

# Useful aliases
git config --global alias.st   "status -sb"
git config --global alias.co   "checkout"
git config --global alias.br   "branch"
git config --global alias.lg   "log --oneline --graph --decorate --all"
git config --global alias.undo "reset HEAD~1 --mixed"
git config --global alias.wip  "commit -am 'WIP'"
git config --global alias.oops "commit --amend --no-edit"

# Global .gitignore
cat > "$HOME/.gitignore_global" << 'GITIGNORE'
# macOS
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
.AppleDouble
.LSOverride
Icon?
.DocumentRevisions-V100
.fseventsd
.TemporaryItems
.VolumeIcon.icns
.com.apple.timemachine.donotpresent
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk

# Editor
.vscode/settings.json
.idea/
*.swp
*.swo
*~
.netrwhist

# Environment
.env
.env.local
.env.*.local
.envrc

# Logs & deps
*.log
node_modules/
npm-debug.log*
.pnpm-debug.log*
dist/
build/
.next/
.nuxt/
.cache/
coverage/

# Secrets
*.pem
*.key
.secrets
GITIGNORE

success "Git configured for $GIT_NAME <$GIT_EMAIL>"

# ─────────────────────────────────────────────────────────────────────────────
# 10. SSH — 1PASSWORD AGENT
# ─────────────────────────────────────────────────────────────────────────────
section "»  SSH — 1Password Agent"

mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"

SSH_CONFIG="$HOME/.ssh/config"

if grep -q "1password" "$SSH_CONFIG" 2>/dev/null; then
  success "1Password SSH agent already configured"
else
  cat >> "$SSH_CONFIG" << 'SSHCONF'
Host *
  IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
SSHCONF
  chmod 600 "$SSH_CONFIG"
  success "SSH config written"
fi

echo ""
warn "Manual steps required after install:"
info "1. Open 1Password → Settings → Developer → enable 'Use the SSH agent'"
info "2. Create or import your SSH keys inside 1Password (New Item → SSH Key)"
info "3. Copy the public key from 1Password → add to GitHub/GitLab"
info "4. Test with: ssh -T git@github.com"
echo ""

# ─────────────────────────────────────────────────────────────────────────────
# 11. ZSHRC CONFIGURATION
# ─────────────────────────────────────────────────────────────────────────────
section "»  Shell Configuration (.zshrc)"

ZSHRC="$HOME/.zshrc"
ZSHRC_BACKUP="$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"

[ -f "$ZSHRC" ] && cp "$ZSHRC" "$ZSHRC_BACKUP" && info "Backed up existing .zshrc → $ZSHRC_BACKUP"

cat > "$ZSHRC" << 'ZSHRCEOF'
# =============================================================================
# .zshrc — Developer Shell Configuration
# =============================================================================

# ── Powerlevel10k instant prompt (must stay near the top) ────────────────────
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── Oh My Zsh ────────────────────────────────────────────────────────────────
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Auto-update OMZ silently in the background, weekly
zstyle ':omz:update' mode auto
zstyle ':omz:update' frequency 7
zstyle ':omz:update' verbose silent

plugins=(
  git
  git-lfs
  gh
  zsh-autosuggestions
  zsh-syntax-highlighting
  zsh-completions
  docker
  docker-compose
  node
  npm
  python
  rust
  brew
  macos
  vscode
  fzf
  colored-man-pages
  command-not-found
  sudo
  copybuffer
  copypath
  web-search
  encode64
)

source "$ZSH/oh-my-zsh.sh"

# ── PATH ─────────────────────────────────────────────────────────────────────
# Homebrew (Apple Silicon)
if [[ "$(uname -m)" == "arm64" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/usr/local/bin/brew shellenv)"
fi
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# VS Code CLI (cask doesn't add `code` to PATH; this makes it work from any shell)
[[ -d "/Applications/Visual Studio Code.app/Contents/Resources/app/bin" ]] && \
  export PATH="/Applications/Visual Studio Code.app/Contents/Resources/app/bin:$PATH"

# ── Language Managers ────────────────────────────────────────────────────────
# fnm (Node)
eval "$(fnm env --use-on-cd)"

# uv (Python — replaces pyenv, pip, poetry, pipx, virtualenv)
eval "$(uv generate-shell-completion zsh 2>/dev/null || true)"

# ── Tool Config ──────────────────────────────────────────────────────────────
# zoxide (smart cd)
eval "$(zoxide init zsh)"

# atuin (shell history)
eval "$(atuin init zsh)"

# direnv
eval "$(direnv hook zsh)"

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --reverse --border --preview "bat --style=numbers --color=always --line-range :500 {}"'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# bat (cat replacement)
export BAT_THEME="Dracula"
alias cat="bat"
alias less="bat --paging=always"

# ── Aliases ──────────────────────────────────────────────────────────────────

# List files (eza)
alias ls="eza --icons --group-directories-first"
alias ll="eza -la --icons --group-directories-first --git"
alias la="eza -a --icons"
alias lt="eza --tree --icons --level=2"
alias ltt="eza --tree --icons --level=3"

# Docker (extras on top of OMZ docker plugin's defaults)
alias d="docker"
alias dc="docker compose"
alias dex="docker exec -it"
alias drmi="docker rmi"
alias dprune="docker system prune -a"

# Python / uv
alias venv="uv venv && source .venv/bin/activate"
alias activate="source .venv/bin/activate"

# Misc
alias reload="source ~/.zshrc"
alias zshconfig="code ~/.zshrc"
alias hosts="sudo code /etc/hosts"
alias ip="curl -s ifconfig.me"
alias localip="ipconfig getifaddr en0"
alias flushdns="sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder && echo 'DNS flushed'"
alias cleanup="find . -name '.DS_Store' -delete"
alias brewup="brew update && brew upgrade && brew cleanup && brew doctor"
alias ports="sudo lsof -i -P -n | grep LISTEN"
alias myip="curl -s api.ipify.org; echo"

# ── Functions ────────────────────────────────────────────────────────────────
# yazi — open file manager, cd to wherever you quit from
y() {
  local tmp; tmp=$(mktemp -t "yazi-cwd.XXXXXX")
  yazi "$@" --cwd-file="$tmp"
  local cwd; cwd=$(cat -- "$tmp") && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ] && cd -- "$cwd"
  rm -f -- "$tmp"
}

# Clone and cd into repo
gclone() { git clone "$1" && cd "$(basename "$1" .git)" || return; }

# Quick HTTP server in current dir
serve() { python3 -m http.server "${1:-8080}"; }

# Kill process on port
killport() { lsof -ti tcp:"$1" | xargs kill -9; }

# Find process using port
whatsport() { sudo lsof -i :"$1"; }

# Extract any archive
extract() {
  if [ -f "$1" ]; then
    case $1 in
      *.tar.bz2) tar xjf "$1"    ;;
      *.tar.gz)  tar xzf "$1"    ;;
      *.bz2)     bunzip2 "$1"    ;;
      *.gz)      gunzip "$1"     ;;
      *.tar)     tar xf "$1"     ;;
      *.tbz2)    tar xjf "$1"    ;;
      *.tgz)     tar xzf "$1"    ;;
      *.zip)     unzip "$1"      ;;
      *.Z)       uncompress "$1" ;;
      *)         echo "'$1' cannot be extracted (use Keka for .rar/.7z)" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Search history
hist() { history | grep "$1"; }

# Weather
weather() { curl "wttr.in/${1:-}"; }

# JWT decoder
jwt-decode() {
  jq -R 'split(".") | .[0],.[1] | @base64d | fromjson' <<< "$1"
}

# ── Environment ──────────────────────────────────────────────────────────────
export EDITOR="code --wait"
export VISUAL="$EDITOR"
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"
export HISTSIZE=50000
export SAVEHIST=50000
export HIST_STAMPS="yyyy-mm-dd"

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt SHARE_HISTORY

# ── Powerlevel10k config ─────────────────────────────────────────────────────
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# ── Local overrides ───────────────────────────────────────────────────────────
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
ZSHRCEOF

success ".zshrc written"

# ── Powerlevel10k config ──────────────────────────────────────────────────────
# Option A: run `p10k configure` after install to generate ~/.p10k.zsh via wizard.
# Option B: paste your dialed-in ~/.p10k.zsh below to apply it automatically.
#
# To embed your own config, replace the placeholder block below with the full
# contents of your ~/.p10k.zsh between the P10KEOF markers.
if [ -f "$HOME/.p10k.zsh" ]; then
  success "Existing ~/.p10k.zsh found — keeping it"
else
  info "No ~/.p10k.zsh yet — run 'p10k configure' after setup, or embed your config in this script"
  # cat > "$HOME/.p10k.zsh" << 'P10KEOF'
  # >>> PASTE YOUR ~/.p10k.zsh CONTENTS HERE <<<
  # P10KEOF
fi

# ─────────────────────────────────────────────────────────────────────────────
# 12. MACOS SYSTEM DEFAULTS
# ─────────────────────────────────────────────────────────────────────────────
section "»  macOS System Preferences"

# ── Dock ──────────────────────────────────────────────────────────────────────
info "Configuring Dock..."
defaults write com.apple.dock autohide               -bool true
defaults write com.apple.dock autohide-delay         -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock magnification          -bool false
defaults write com.apple.dock show-recents           -bool false
defaults write com.apple.dock minimize-to-application -bool true
defaults write com.apple.dock mineffect              -string "scale"   # Minimize: scale (vs default "genie")
defaults write com.apple.dock mru-spaces             -bool false       # Don't rearrange spaces
# Click wallpaper to reveal desktop: only when in Stage Manager (default in newer macOS is "always")
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
# Close windows when quitting an application (don't auto-restore them next launch)
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
success "Dock"

# ── Finder ────────────────────────────────────────────────────────────────────
info "Configuring Finder..."
defaults write com.apple.finder FXPreferredViewStyle        -string "Nlsv"  # List view
defaults write com.apple.finder FXDefaultSearchScope        -string "SCcf"  # Search current folder
defaults write com.apple.finder _FXSortFoldersFirst         -bool true
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop     -bool false
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write NSGlobalDomain AppleShowAllExtensions        -bool true
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
success "Finder"

# ── Keyboard & Input ──────────────────────────────────────────────────────────
info "Configuring keyboard..."
defaults write NSGlobalDomain KeyRepeat                -int 2
defaults write NSGlobalDomain InitialKeyRepeat         -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled  -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled   -bool false
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled     -bool false
defaults write NSGlobalDomain AppleKeyboardUIMode                  -int 3
success "Keyboard"

# ── Trackpad ─────────────────────────────────────────────────────────────────
info "Configuring trackpad..."
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true  # Tap to click
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false  # Natural scrolling off
# Three-finger drag must be enabled in System Settings → Accessibility →
# Pointer Control → Trackpad Options on macOS 11+.
success "Trackpad"

# ── Screenshots ───────────────────────────────────────────────────────────────
info "Configuring screenshots..."
mkdir -p "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture location "$HOME/Desktop/Screenshots"
defaults write com.apple.screencapture type     "png"
defaults write com.apple.screencapture disable-shadow -bool true
success "Screenshots → ~/Desktop/Screenshots"

# ── Menu Bar & UI ─────────────────────────────────────────────────────────────
info "Configuring UI..."
defaults write NSGlobalDomain AppleInterfaceStyle    -string "Dark"    # Dark mode
defaults write NSGlobalDomain NSWindowResizeTime     -float 0.001       # Fast window resize
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint    -bool true
defaults write com.apple.universalaccess reduceMotion -bool true        # Reduce motion
defaults write com.apple.menuextra.clock DateFormat  -string "EEE MMM d  HH:mm:ss"
success "UI"

# ── Security ──────────────────────────────────────────────────────────────────
info "Configuring security..."
sudo defaults write /Library/Preferences/com.apple.loginwindow DisableConsoleAccess -bool true
defaults write com.apple.screensaver askForPassword        -int 1
defaults write com.apple.screensaver askForPasswordDelay   -int 0
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on &>/dev/null
success "Security"

# ── Activity Monitor ─────────────────────────────────────────────────────────
info "Configuring Activity Monitor..."
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor ShowCategory   -int 0
defaults write com.apple.ActivityMonitor SortColumn     -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection  -int 0
success "Activity Monitor"

# ── TextEdit ─────────────────────────────────────────────────────────────────
info "Configuring TextEdit..."
defaults write com.apple.TextEdit RichText       -int 0
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4
success "TextEdit"

# Apply changes
killall Dock    2>/dev/null || true
killall Finder  2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

success "macOS defaults applied"

# ─────────────────────────────────────────────────────────────────────────────
# 13. CLAUDE CODE
# ─────────────────────────────────────────────────────────────────────────────
section "»  Claude Code"

if command -v claude &>/dev/null; then
  success "Claude Code already installed ($(claude --version 2>/dev/null || echo 'unknown version'))"
else
  info "Installing Claude Code via native installer (recommended)..."
  if curl -fsSL https://claude.ai/install.sh | bash; then
    success "Claude Code installed"
    echo -e "  ${ARROW} To authenticate: run ${BOLD}claude${RESET} in your terminal"
    # Add to PATH if not already there (installer puts it in ~/.local/bin)
    if ! grep -q '\.local/bin' "$HOME/.zshrc" 2>/dev/null; then
      echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.zshrc"
    fi
  else
    warn "Native installer failed, falling back to npm..."
    if npm install -g @anthropic-ai/claude-code 2>>"$LOG_FILE"; then
      success "Claude Code installed via npm"
    else
      error "Claude Code installation failed — run manually: npm install -g @anthropic-ai/claude-code"
    fi
  fi
fi

# Claude Code VS Code extension
if command -v code &>/dev/null; then
  info "Installing Claude Code VS Code extension..."
  code --install-extension anthropic.claude-code --force &>/dev/null \
    && success "Claude Code VS Code extension" \
    || warn "Claude Code VS Code extension install skipped"
fi

info "Docs: https://docs.claude.com/en/docs/claude-code/overview"

# ─────────────────────────────────────────────────────────────────────────────
# 14. FINAL CLEANUP
# ─────────────────────────────────────────────────────────────────────────────
section "»  Cleanup"

info "Running brew cleanup..."
brew cleanup --quiet 2>>"$LOG_FILE" || warn "brew cleanup had issues (see $LOG_FILE)"
brew autoremove --quiet 2>>"$LOG_FILE" || warn "brew autoremove had issues (see $LOG_FILE)"

success "Done!"

# ─────────────────────────────────────────────────────────────────────────────
# SUMMARY
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo "━━━ Setup finished at $(date) ━━━" >> "$LOG_FILE"

if [ ${#FAILED_STEPS[@]} -gt 0 ]; then
  echo ""
  echo -e "${BOLD}${YELLOW}  ⚠  ${#FAILED_STEPS[@]} step(s) had issues:${RESET}"
  for step in "${FAILED_STEPS[@]}"; do
    echo -e "     ${RED}•${RESET} $step"
  done
  echo -e "  ${DIM}Full details in: $LOG_FILE${RESET}"
else
  echo -e "${BOLD}${GREEN}  ✔  All steps completed successfully!${RESET}"
fi

# ─────────────────────────────────────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}  ██████╗  ██████╗ ███╗   ██╗███████╗██╗${RESET}"
echo -e "${BOLD}${GREEN}  ██╔══██╗██╔═══██╗████╗  ██║██╔════╝██║${RESET}"
echo -e "${BOLD}${GREEN}  ██║  ██║██║   ██║██╔██╗ ██║█████╗  ██║${RESET}"
echo -e "${BOLD}${GREEN}  ██║  ██║██║   ██║██║╚██╗██║██╔══╝  ╚═╝${RESET}"
echo -e "${BOLD}${GREEN}  ██████╔╝╚██████╔╝██║ ╚████║███████╗██╗${RESET}"
echo -e "${BOLD}${GREEN}  ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚═╝${RESET}"
echo ""
echo -e "${BOLD}${GREEN}  ╔══════════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}${GREEN}  ║      Setup Complete! Your Mac is ready for development.      ║${RESET}"
echo -e "${BOLD}${GREEN}  ╚══════════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  ${BOLD}Next steps:${RESET}"
echo ""
echo -e "  ${CYAN} 1.${RESET} Restart your terminal (or run: ${BOLD}source ~/.zshrc${RESET})"
echo -e "  ${CYAN} 2.${RESET} Run ${BOLD}p10k configure${RESET} to set up your prompt (or embed your ~/.p10k.zsh)"
echo -e "  ${CYAN} 3.${RESET} Open ${BOLD}1Password${RESET} → Settings → Developer → enable SSH agent"
echo -e "  ${CYAN} 4.${RESET} Create your SSH key in ${BOLD}1Password${RESET} → add public key to GitHub/GitLab"
echo -e "  ${CYAN} 5.${RESET} Run ${BOLD}gh auth login${RESET} to authenticate the GitHub CLI"
echo -e "  ${CYAN} 6.${RESET} Run ${BOLD}claude${RESET} in your terminal to authenticate Claude Code"
echo -e "  ${CYAN} 7.${RESET} Open ${BOLD}OrbStack${RESET} and complete setup"
echo -e "  ${CYAN} 8.${RESET} Open ${BOLD}Raycast${RESET} and configure your extensions"
echo -e "  ${CYAN} 9.${RESET} Set ${BOLD}JetBrainsMono Nerd Font${RESET} in your terminal"
echo -e "  ${CYAN}10.${RESET} Run ${BOLD}atuin import auto${RESET} to import existing shell history (optional: ${BOLD}atuin register${RESET} for sync)"
echo -e "  ${CYAN}11.${RESET} Sign in to ${BOLD}CleanShot X${RESET} with your license"
echo -e "  ${CYAN}12.${RESET} Restart your Mac to apply all system changes"
echo ""
echo -e "  ${DIM}Full log saved to: $LOG_FILE${RESET}"
echo ""
