#!/bin/bash

# ─── Dotfiles bootstrap ──────────────────────────────────
# Installs dependencies and symlinks configs for tmux + nvim.
# Safe to re-run — skips anything already installed.
#
# Usage:
#   git clone <your-dotfiles-repo> ~/dotfiles
#   cd ~/dotfiles
#   chmod +x install.sh
#   ./install.sh

echo "Starting MacBook setup..."
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

### System Preferences
echo "Configuring system preferences..."
# Set computer name
sudo scutil --set ComputerName "opoupier"
sudo scutil --set HostName "opoupier"
sudo scutil --set LocalHostName "opoupier"

# Show file extensions and hidden files
defaults write -g AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles true

### Brew setup
info()  { printf "\033[1;34m[info]\033[0m  %s\n" "$1"; }
ok()    { printf "\033[1;32m[ok]\033[0m    %s\n" "$1"; }
warn()  { printf "\033[1;33m[warn]\033[0m  %s\n" "$1"; }
error() { printf "\033[1;31m[error]\033[0m %s\n" "$1"; exit 1; }

# Git
[ -f "$DOTFILES_DIR/dotfiles/.gitconfig" ] && cp "$DOTFILES_DIR/dotfiles/.gitconfig" "$HOME/.gitconfig"

# ─── Homebrew ─────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add brew to PATH for the rest of this script (Apple Silicon vs Intel)
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -f /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    ok "Homebrew installed"
else
    ok "Homebrew already installed"
fi

# ─── Brew packages ────────────────────────────────────────
BREW_FORMULAES=(
    wget
    neovim
    tmux
    ripgrep       # Required for Telescope live_grep
    fd            # Faster file finding for Telescope
    lazygit       # TUI git client (Phase 3)
    nmap
    golang
    keychain      # SSH agent management
)

info "Installing brew packages..."
for pkg in "${BREW_FORMULAES[@]}"; do
    if brew list "$pkg" &>/dev/null; then
        ok "$pkg already installed"
    else
        info "Installing $pkg..."
        brew install "$pkg"
        ok "$pkg installed"
    fi
done

# ─── Brew Casks ────────────────────────────────────────
BREW_CASKS=(
    iterm2
    font-jetbrains-mono-nerd-font
    docker
    visual-studio-code
    postman
)

info "Installing brew packages..."
for pkg in "${BREW_CASKS[@]}"; do
    if brew list "$pkg" &>/dev/null; then
        ok "$pkg already installed"
    else
        info "Installing $pkg..."
        brew install --cask "$pkg"
        ok "$pkg installed"
    fi
done

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
ln -sf "$DOTFILES_DIR/dotfiles/zshrc" "$HOME/.zshrc"
ok "~/.zshrc → $DOTFILES_DIR/dotfiles/zshrc"

# ─── SSH key ─────────────────────────────────────────────
if [ -f "$HOME/.ssh/id_rsa" ]; then
    ok "SSH key already exists"
else
    info "Generating SSH key..."
    mkdir -p "$HOME/.ssh"
    ssh-keygen -t rsa -b 4096 -f "$HOME/.ssh/id_rsa" -N ""
    ok "SSH key generated at ~/.ssh/id_rsa"
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

# Go setup
mkdir -p "$HOME/go/bin" "$HOME/go/src"

# Node.js with NVM
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

# Add .NET and VS Code to PATH
if ! grep -q '.dotnet' "$HOME/.zprofile" 2>/dev/null; then
    cat << 'EOF' >> ~/.zprofile

# .NET
export DOTNET_ROOT="$HOME/.dotnet"
export PATH="$PATH:$DOTNET_ROOT:$DOTNET_ROOT/tools"
EOF
    ok ".NET PATH added to .zprofile"
fi

if ! grep -q 'Visual Studio Code' "$HOME/.zprofile" 2>/dev/null; then
    cat << 'EOF' >> ~/.zprofile

# VS Code
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
EOF
fi

### Configure Dock (only on first run)
DOCK_MARKER="$HOME/.dotfiles_dock_configured"
if [ -f "$DOCK_MARKER" ]; then
    ok "Dock already configured (remove ~/.dotfiles_dock_configured to reconfigure)"
else
    echo "Configuring Dock..."
    defaults write com.apple.dock persistent-apps -array

    add_to_dock() {
        defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$1</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
    }

    add_to_dock "/System/Applications/Finder.app"
    add_to_dock "/System/Applications/Calendar.app"
    add_to_dock "/Applications/Safari.app"
    add_to_dock "/System/Applications/Mail.app"
    add_to_dock "/System/Applications/Messages.app"
    add_to_dock "/System/Applications/Music.app"
    add_to_dock "/System/Applications/Notes.app"
    add_to_dock "/Applications/Postman.app"
    add_to_dock "/Applications/iTerm.app"
    add_to_dock "/System/Applications/System Settings.app"
    add_to_dock "/System/Applications/Utilities/Keychain Access.app"
    add_to_dock "/Applications/Docker.app"

    killall Dock
    touch "$DOCK_MARKER"
    ok "Dock configured"
fi

### Final steps
echo "Restarting Finder..."
killall Finder

echo "Setup complete! Please restart your computer for all changes to take effect."
