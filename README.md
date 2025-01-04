
## desktop install

```
ssh-keygen -t rsa -b 4096
cat ~/.ssh/id_rsa.pub | xclip -i
# add to github
sudo apt install git
mkdir ~/repos
git clone git@github.com:olivierpoupier/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles
./setup.sh
```