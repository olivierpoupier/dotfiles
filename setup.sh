#!/bin/bash

echo "Starting MacBook setup..."

### System Preferences
echo "Configuring system preferences..."
# Set computer name
sudo scutil --set ComputerName "opoupier"
sudo scutil --set HostName "opoupier"
sudo scutil --set LocalHostName "opoupier"

# Show file extensions and hidden files
defaults write -g AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles true

### Install Homebrew
echo "Installing Homebrew..."
if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

### Install Development Tools
echo "Installing development tools..."
# Git
brew install git
[ -f ./configs/gitconfig ] && cp ./configs/gitconfig ~/.gitconfig

# iTerm2
brew install --cask iterm2

# Oh My Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Copy zsh configs
[ -f ./dotfiles/zshrc ] && cp ./dotfiles/zshrc ~/.zshrc
[ -f ./dotfiles/theme.zsh-theme ] && cp ./dotfiles/theme.zsh-theme ~/.oh-my-zsh/themes/

# Node.js
brew install node

# .NET versions
brew install --cask dotnet-sdk
dotnet tool install -g dotnet-ef
brew install --cask dotnet-sdk6-0-400
brew install --cask dotnet-sdk8-0

# Docker
brew install --cask docker

# Node.js and Angular CLI
brew install node
npm install -g @angular/cli

# Network tools
brew install nmap

# Python, pip, and venv
brew install python
# Verify pip and venv are available
python3 -m pip install --upgrade pip
python3 -m ensurepip --upgrade

### Install Applications
echo "Installing applications..."
# VS Code and Cursor
brew install --cask visual-studio-code
brew install --cask cursor

# Add VS Code and Cursor to PATH
cat << EOF >> ~/.zprofile
export PATH="\$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export PATH="\$PATH:/Applications/Cursor.app/Contents/Resources/app/bin"
EOF

# Development tools
brew install --cask postman
brew install --cask azure-data-studio
brew install --cask slack
brew install --cask microsoft-excel
brew install --cask chatgpt
brew install --cask figma

# VS Code Extensions
echo "Installing VS Code extensions..."
code --install-extension GitHub.copilot
code --install-extension ms-dotnettools.csharp
code --install-extension ms-dotnettools.vscode-dotnet-runtime
code --install-extension mikestead.dotenv
code --install-extension golang.go
code --install-extension ms-toolsai.jupyter
code --install-extension ms-azuretools.vscode-docker
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode
code --install-extension ms-python.python
code --install-extension eamodio.gitlens
code --install-extension RobbOwen.synthwave-vscode
code --install-extension DotJoshJohnson.xml
code --install-extension wmaurer.change-case

# Cursor Extensions (Cursor is based on VS Code, so many extensions are compatible)
echo "Installing Cursor extensions..."
cursor --install-extension ms-dotnettools.csharp
cursor --install-extension ms-dotnettools.vscode-dotnet-runtime
cursor --install-extension mikestead.dotenv
cursor --install-extension golang.go
cursor --install-extension ms-toolsai.jupyter
cursor --install-extension ms-azuretools.vscode-docker
cursor --install-extension dbaeumer.vscode-eslint
cursor --install-extension esbenp.prettier-vscode
cursor --install-extension ms-python.python
cursor --install-extension eamodio.gitlens
cursor --install-extension RobbOwen.synthwave-vscode
cursor --install-extension DotJoshJohnson.xml
cursor --install-extension wmaurer.change-case

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
add_to_dock "/Applications/Slack.app"
add_to_dock "/Applications/ChatGPT.app"
add_to_dock "/System/Applications/Music.app"
add_to_dock "/System/Applications/Notes.app"
add_to_dock "/Applications/Postman.app"
add_to_dock "/Applications/Visual Studio Code.app"
add_to_dock "/Applications/Cursor.app"
add_to_dock "/Applications/iTerm.app"
add_to_dock "/Applications/Azure Data Studio.app"
add_to_dock "/System/Applications/System Settings.app"
add_to_dock "/System/Applications/Utilities/Keychain Access.app"
add_to_dock "/Applications/Docker.app"
add_to_dock "/Applications/Microsoft Excel.app"

# Restart Dock to apply changes
killall Dock

### Final steps
echo "Restarting Finder..."
killall Finder

echo "Setup complete! Please restart your computer for all changes to take effect."
