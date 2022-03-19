#!/bin/bash
nombre_maquina=ubuntu-wsl

sudo sed -i -e "s/$HOSTNAME.localdomain/$nombre_maquina.localdomain/g" -e "s/$HOSTNAME/$nombre_maquina/g" /etc/hosts

sudo cat <<EOF | sudo tee /etc/wsl.conf
[network]
hostname = $nombre_maquina
generateHosts = false
[user]
default = $USER
EOF

#hostnamectl set-hostname $nombre_maquina
#sudo timedatectl set-timezone Europe/Paris
sudo rm -rf /etc/localtime
sudo ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime

sudo ufw disable
sudo apt update -y && sudo apt upgrade -y
sudo apt install tmux vim git tree htop -y

sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
# sudo service sshd restart

sudo sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g'

#ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -q -N ""
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -q -N ""

echo "root:123" | sudo chpasswd

usuario1=ansibleadmin
sudo useradd -U $usuario1 -m -s /bin/bash -G sudo
echo "$usuario1:123" | sudo chpasswd
echo "$usuario1 ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers

sudo apt install ansible -y

usuario2=dockeradmin
sudo useradd -U $usuario2 -m -s /bin/bash -G sudo
echo "$usuario2:123" | sudo chpasswd
echo "$usuario2 ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers

sudo apt update -y && sudo apt upgrade -y
sudo apt remove docker docker.io containerd runc -y
sudo apt install ca-certificates curl gnupg lsb-release apt-transport-https -y
sudo apt autoremove -y
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update -y && sudo apt upgrade -y
sudo apt install docker-ce docker-ce-cli containerd.io -y
sudo service docker start
sudo usermod -aG docker $USER
sudo usermod -aG docker $usuario1
sudo usermod -aG docker $usuario2

sudo apt install zsh -y
sudo chsh -s $(which zsh)

mkdir -p ~/ps/tst
mkdir -p ~/ps/git

cd ~/ps/git
git clone https://github.com/jvinc86/wsl-bash-script.git
git clone https://github.com/jvinc86/alias-ubuntu.git
source ~/ps/git/alias-ubuntu/alias.sh

sudo apt install ruby-full gcc make -y
sudo gem install colorls
source $(dirname $(gem which colorls))/tab_complete.sh

sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
sudo sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc
sudo sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc

sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
sudo git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
source ~/ps/git/alias-ubuntu/alias.sh

# Para finalizar:
#      cat ~/.ssh/id_ed25519.pub
# La copiamos, en Github creamos una llave nueva con esos datos
#      https://github.com/settings/keys
# Ejecutamos los comandos:

#cd ~/ps/git/wsl-bash-script
#git remote set-url origin git@github.com:jvinc86/wsl-bash-script.git
#git config --global credential.helper store
#git config --global credential.helper cache

#cd ~/ps/git/alias-ubuntu
#git remote set-url origin git@github.com:jvinc86/alias-ubuntu.git
#git config --global credential.helper store
#git config --global credential.helper cache

#Es posible que debamos correr otra vez:
# sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
# sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
