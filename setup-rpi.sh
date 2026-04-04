#!/bin/bash

# ─── Dotfiles bootstrap (Raspberry Pi / Debian) ──────────
# Installs dependencies and symlinks configs for tmux + nvim.
# Safe to re-run — skips anything already installed.
#
# Usage:
#   git clone <your-dotfiles-repo> ~/dotfiles
#   cd ~/dotfiles
#   chmod +x setup-rpi.sh
#   ./setup-rpi.sh

echo "Starting Raspberry Pi setup..."
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

### Helper functions
info()  { printf "\033[1;34m[info]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[ok]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[1;33m[warn]\033[0m  %s\n" "$1"; }
error() { printf "\033[1;31m[error]\033[0m %s\n" "$1"; exit 1; }

# ─── System update ────────────────────────────────────────
info "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y
ok "System updated"

# ─── Set hostname ─────────────────────────────────────────
info "Setting hostname..."
sudo hostnamectl set-hostname opoupier-rpi
ok "Hostname set to opoupier-rpi"

# ─── Git config ───────────────────────────────────────────
if [ -f "$DOTFILES_DIR/dotfiles/.gitconfig" ]; then
    info "Copying gitconfig..."
    cp "$DOTFILES_DIR/dotfiles/.gitconfig" "$HOME/.gitconfig"
    ok "gitconfig copied"
fi

# ─── APT packages ─────────────────────────────────────────
APT_PACKAGES=(
    wget
    curl
    git
    zsh
    tmux
    ripgrep
    fd-find
    nmap
    build-essential
    cmake
    unzip
    gettext        # needed to build neovim from source
    keychain       # SSH agent management
    openssh-client # provides ssh-keygen
)

info "Installing apt packages..."
for pkg in "${APT_PACKAGES[@]}"; do
    if dpkg -s "$pkg" &>/dev/null; then
        ok "$pkg already installed"
    else
        info "Installing $pkg..."
        sudo apt-get install -y "$pkg"
        ok "$pkg installed"
    fi
done

# Create fd symlink (Debian ships fd as fdfind)
if command -v fdfind &>/dev/null && ! command -v fd &>/dev/null; then
    sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
    ok "Created fd symlink"
fi

# ─── Oh My Zsh ───────────────────────────────────────────
if [ -d "$HOME/.oh-my-zsh" ]; then
    ok "Oh My Zsh already installed"
else
    info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    ok "Oh My Zsh installed"
fi

# ─── Zsh theme ───────────────────────────────────────────
info "Copying zsh theme..."
cp "$DOTFILES_DIR/dotfiles/opoupier.zsh-theme" "$HOME/.oh-my-zsh/custom/themes/opoupier.zsh-theme"
ok "opoupier.zsh-theme copied to oh-my-zsh custom themes"

# ─── Zsh config ─────────────────────────────────────────
info "Linking zshrc..."
if [[ -f "$HOME/.zshrc" || -L "$HOME/.zshrc" ]]; then
    warn "Backing up existing ~/.zshrc → ~/.zshrc.bak"
    mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
fi
ln -sf "$DOTFILES_DIR/dotfiles/zshrc-debian" "$HOME/.zshrc"
ok "~/.zshrc → $DOTFILES_DIR/dotfiles/zshrc-debian"

# ─── Set Zsh as default shell ────────────────────────────
if [ "$(basename "$SHELL")" != "zsh" ]; then
    info "Setting zsh as default shell..."
    sudo chsh -s "$(which zsh)" "$USER"
    ok "Default shell set to zsh"
else
    ok "Zsh is already the default shell"
fi

# ─── SSH key ─────────────────────────────────────────────
if [ -f "$HOME/.ssh/id_rsa" ]; then
    ok "SSH key already exists"
else
    info "Generating SSH key..."
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ""
    ok "SSH key generated at ~/.ssh/id_rsa"
fi

# ─── Neovim (build from source for latest version) ───────
if command -v nvim &>/dev/null; then
    ok "Neovim already installed"
else
    info "Building Neovim from source (this may take a while)..."
    NVIM_BUILD_DIR=$(mktemp -d)
    git clone --depth 1 https://github.com/neovim/neovim.git "$NVIM_BUILD_DIR"
    cd "$NVIM_BUILD_DIR"
    make CMAKE_BUILD_TYPE=Release || error "Neovim build failed"
    sudo make install
    cd "$DOTFILES_DIR"
    rm -rf "$NVIM_BUILD_DIR"
    ok "Neovim installed"
fi

# ─── Lazygit ──────────────────────────────────────────────
if command -v lazygit &>/dev/null; then
    ok "Lazygit already installed"
else
    info "Installing lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    ARCH=$(dpkg --print-architecture)
    if [ "$ARCH" = "armhf" ]; then
        LAZYGIT_ARCH="armv6"
    elif [ "$ARCH" = "arm64" ]; then
        LAZYGIT_ARCH="arm64"
    else
        LAZYGIT_ARCH="$ARCH"
    fi
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_${LAZYGIT_ARCH}.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit lazygit.tar.gz
    ok "Lazygit installed"
fi

# ─── Go ───────────────────────────────────────────────────
if command -v go &>/dev/null; then
    ok "Go already installed"
else
    info "Installing Go..."
    ARCH=$(dpkg --print-architecture)
    if [ "$ARCH" = "armhf" ]; then
        GO_ARCH="armv6l"
    elif [ "$ARCH" = "arm64" ]; then
        GO_ARCH="arm64"
    else
        GO_ARCH="$ARCH"
    fi
    GO_VERSION=$(curl -s https://go.dev/VERSION?m=text | head -1)
    curl -Lo go.tar.gz "https://go.dev/dl/${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf go.tar.gz
    rm go.tar.gz
    ok "Go installed"
fi

mkdir -p "$HOME/go/bin" "$HOME/go/src"

# ─── tmux config ──────────────────────────────────────────
info "Linking tmux config..."
if [[ -f "$HOME/.tmux.conf" || -L "$HOME/.tmux.conf" ]]; then
    warn "Backing up existing ~/.tmux.conf → ~/.tmux.conf.bak"
    mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.bak"
fi
ln -sf "$DOTFILES_DIR/dotfiles/.tmux.conf" "$HOME/.tmux.conf"
ok "~/.tmux.conf → $DOTFILES_DIR/dotfiles/.tmux.conf"

# ─── TPM (tmux plugin manager) ───────────────────────────
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ -d "$TPM_DIR" ]]; then
    ok "TPM already installed"
else
    info "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    ok "TPM installed"
fi

# ─── nvim config ──────────────────────────────────────────
info "Linking nvim config..."
NVIM_CONFIG_DIR="$HOME/.config/nvim"
mkdir -p "$HOME/.config"

if [[ -d "$NVIM_CONFIG_DIR" || -L "$NVIM_CONFIG_DIR" ]]; then
    if [[ -L "$NVIM_CONFIG_DIR" ]]; then
        rm "$NVIM_CONFIG_DIR"
    else
        warn "Backing up existing ~/.config/nvim → ~/.config/nvim.bak"
        mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.bak"
    fi
fi

# Symlink init.lua directly since nvim config is a single file
mkdir -p "$NVIM_CONFIG_DIR"
ln -sf "$DOTFILES_DIR/dotfiles/init.lua" "$NVIM_CONFIG_DIR/init.lua"
ok "~/.config/nvim/init.lua → $DOTFILES_DIR/dotfiles/init.lua"

# ─── Install nvim plugins (headless) ─────────────────────
info "Installing nvim plugins (this may take a moment)..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
ok "nvim plugins installed"

# ─── Install treesitter parsers ───────────────────────────
info "Installing treesitter parsers..."
PARSERS=(
    lua c_sharp typescript javascript
    html css json yaml markdown
    bash go sql dockerfile
)
for parser in "${PARSERS[@]}"; do
    nvim --headless "+TSInstall! $parser" +qa 2>/dev/null || true
done
ok "Treesitter parsers installed"

# ─── Install tmux plugins ────────────────────────────────
info "Installing tmux plugins..."
if [[ -x "$TPM_DIR/bin/install_plugins" ]]; then
    "$TPM_DIR/bin/install_plugins" || true
    ok "tmux plugins installed"
else
    warn "Start tmux and press prefix + I to install plugins"
fi

# ─── Node.js with NVM ────────────────────────────────────
if [ ! -d "$HOME/.nvm" ]; then
    info "Installing NVM..."
    NVM_LATEST=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -Po '"tag_name": "\K[^"]*')
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST}/install.sh" | bash

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

info "Installing Node.js LTS..."
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts
nvm use --lts

# Install Angular CLI
if command -v ng &>/dev/null; then
    ok "Angular CLI already installed"
else
    npm install -g @angular/cli
    ok "Angular CLI installed"
fi

# ─── .NET ─────────────────────────────────────────────────
if [ -d "$HOME/.dotnet" ]; then
    ok ".NET SDK already installed"
else
    info "Installing .NET SDK..."
    curl -sSL https://dot.net/v1/dotnet-install.sh | bash
    ok ".NET SDK installed"
fi

# ─── JetBrains Mono Nerd Font ─────────────────────────────
FONT_DIR="$HOME/.local/share/fonts"
if ls "$FONT_DIR"/JetBrains* &>/dev/null; then
    ok "JetBrains Mono Nerd Font already installed"
else
    info "Installing JetBrains Mono Nerd Font..."
    mkdir -p "$FONT_DIR"
    curl -Lo /tmp/JetBrainsMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    unzip -o /tmp/JetBrainsMono.zip -d "$FONT_DIR"
    rm /tmp/JetBrainsMono.zip
    fc-cache -fv
    ok "JetBrains Mono Nerd Font installed"
fi

echo ""
echo "Setup complete! Please log out and back in for zsh to take effect."
