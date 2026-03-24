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
[ -f ./configs/gitconfig ] && cp ./configs/gitconfig ~/.gitconfig

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
    iterm2
    neovim
    tmux
    ripgrep       # Required for Telescope live_grep
    fd            # Faster file finding for Telescope
    lazygit       # TUI git client (Phase 3)
    nmap
    golang
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
    docker
    visual-studio-code
    postman
    font-jetbrains-mono-nerd-font
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
ln -sf "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
ok "~/.tmux.conf → $DOTFILES_DIR/tmux/.tmux.conf"

# ─── TPM (tmux plugin manager) ───────────────────────────
TPM_DIR="$HOME/.tmux/plugins/tpm"
if [[ -d "$TPM_DIR" ]]; then
    ok "TPM already installed"
else
    info "Installing TPM..."
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    ok "TPM installed"

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
ln -sf "$DOTFILES_DIR/nvim" "$NVIM_CONFIG_DIR"
ok "~/.config/nvim → $DOTFILES_DIR/nvim"

# ─── Install nvim plugins (headless) ─────────────────────
info "Installing nvim plugins (this may take a moment)..."
nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
ok "nvim plugins installed"

# ─── Install treesitter parsers ───────────────────────────
info "Installing treesitter parsers..."
PARSERS=(
    lua c_sharp typescript javascript
    html css json yaml markdown
    bash sql dockerfile
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
mkdir -p $HOME/go/{bin,src}

# Node.js with NVM
if [ ! -d "$HOME/.nvm" ]; then
    echo "Installing NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
    
    # Load NVM immediately
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
fi

# Install Node.js LTS version
nvm install --lts
nvm use --lts

# Install Angular CLI
npm install -g @angular/cli

# Install dotnet
wget https://dot.net/v1/dotnet-install.sh
chmod +x dotnet-install.sh
./dotnet-install.sh

# Add VS Code and Cursor to PATH
cat << EOF >> ~/.zprofile
export PATH="\$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
EOF

### Configure Dock
echo "Configuring Dock..."
# Remove all apps from Dock
defaults write com.apple.dock persistent-apps -array

# Function to add app to Dock
add_to_dock() {
    defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$1</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
}

# Add apps to Dock in specified order
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

# Restart Dock to apply changes
killall Dock

### Final steps
echo "Restarting Finder..."
killall Finder

echo "Setup complete! Please restart your computer for all changes to take effect."
