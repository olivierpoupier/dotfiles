### Host
sudo pmset -a sms 0 # no motion sensor
sudo pmset -a hibernatemode 0 # no hibernate
sudo systemsetup -setcomputersleep Off >/dev/null # no sleep
sudo rm /private/var/vm/sleepimage # remove sleep image
sudo touch /private/var/vm/sleepimage
sudo chflags uchg /private/var/vm/sleepimage
sudo scutil --set ComputerName "opoupier-mac" # set hostname
sudo scutil --set HostName "opoupier-mac"
sudo scutil --set LocalHostName "opoupier-mac"
defaults write com.apple.screensaver askForPassword -int 1 # ask for password after ss
defaults write -g AppleShowAllExtensions -bool true # show file extensions
defaults write com.apple.finder AppleShowAllFiles true # show hidden files
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3 # allow tab in popups

### Environment
# brew
if ! [ -x "$(command -v brew)" ]; then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew update
brew doctor
brew install mas
brew tap caskroom/cask

#divvy
mas install 413857545
#slack
mas install 618783545
#discord
mas install 985746746
#excel
mas install 462058435
#word
mas install 462054704
#powerpoint
mas install 462062816
#outlook
mas install 985367838
# npm & packages
brew install node
npm install -g @angular/cli
#python
brew install python
#.net core
brew install --cask dotnet
# zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"

function install_dot() {
  local source="$1"
  local target="$2"
  rm -rf "$HOME/$target"
  ln -s "$HOME/$source" "$HOME/$target"
}

install_dot dotfiles/dotfiles/zshrc .zshrc
install_dot dotfiles/dotfiles/vimrc .config/nvim/init.vim


[ ! -f ~/.gitconfig ] && cp $HOME/dotfiles/dotfiles/gitconfig ~/.gitconfig
[ ! -f ~/.config/nvim/autoload/plug.vim ] && cp ~/dotfiles/vim/plug.vim ~/.config/nvim/autoload/plug.vim

if test "$SHELL" != "/bin/zsh"; then
  chsh -s /bn/zsh
fi

### Dev tools
# iTerm2
brew install --cask iterm2
# neovim
brew install --cask neovim
# postman
brew install --cask postman
# vs code
brew install --cask visual-studio-code

cat << EOF >> ~/.zprofile
export PATH="\$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
EOF

code --install-extension ormulahendry.dotnet-test-explorer
code --install-extension ms-dotnettools.csharp
code --install-extension mikestead.dotenv
code --install-extension editorconfig.editorconfig
code --install-extension dsznajder.es7-react-js-snippets
code --install-extension davidanson.vscode-markdownlint
code --install-extension ms-python.python
code --install-extension syler.sass-indented
code --install-extension robbowen.synthwave-vscode

### Dock
# Set smaller icon size
defaults write com.apple.dock tilesize -int 40
# Speed up mission control animations
defaults write com.apple.dock expose-animation-duration -float 0.1
# Set persistent apps in dock
## TODO: do that

### Finder
# Show extensions
defaults write -g AppleShowAllExtensions -bool true
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles true
# Search in current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

### I/O
# Disable autocorrect
defaults write -g NSAutomaticSpellingCorrectionEnabled -bool false
# Enable "natural" scrolling
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

killall Dock &> /dev/null
killall Finder &> /dev/nulli
