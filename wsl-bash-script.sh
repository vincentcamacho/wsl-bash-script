#!/bin/bash

# Cambiar nombre de maquina wsl
nombre_maquina=ubuntu-wsl
sudo sed -i -e "s/$HOSTNAME.localdomain/$nombre_maquina.localdomain/g" -e "s/$HOSTNAME/$nombre_maquina/g" /etc/hosts

# Otra forma de cambiar nombre de la maquina pero NO funciona en WSL
#hostnamectl set-hostname $nombre_maquina

# Configurar archivo principal de WSL
sudo cat <<EOF | sudo tee /etc/wsl.conf
[network]
hostname = $nombre_maquina
generateHosts = false
#generateResolvConf = false
[user]
default = $USER
EOF

# Configurar DNS de Google
echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null

# Cambiar time zone
sudo rm -rf /etc/localtime
sudo ln -s /usr/share/zoneinfo/Europe/Paris /etc/localtime

# Otra forma de cambiar time zone pero NO funciona en WSL
#sudo timedatectl set-timezone Europe/Paris

# Desactivar Firewall
sudo ufw disable

# Instalar herramientas basicas
sudo apt update -y && sudo apt upgrade -y
sudo apt install tldr tmux vim git tree htop unzip wget curl -y

# Permitir Accesos por usuario-password y con llave
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sudo service sshd restart

# Eliminar la necesidad de password para usuario del grupo sudo
sudo sed -i /etc/sudoers -re 's/^%sudo.*/%sudo ALL=(ALL:ALL) NOPASSWD: ALL/g'

# Generar un par de llaves SSL
#ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -q -N ""
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -q -N ""

# Cambiar password a root
echo "root:123" | sudo chpasswd

# Instalar nuevo Shell ZSH y cambiarlo
sudo apt install zsh -y
sudo chsh -s $(which zsh)

# Instalar Vagrant
wget https://releases.hashicorp.com/vagrant/2.2.19/vagrant_2.2.19_x86_64.deb
sudo apt install ./vagrant_2.2.19_x86_64.deb -y
rm -rf vagrant_2.2.19_x86_64.deb

# Instalar Terraform
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt update -y && sudo apt install terraform -y

# Instalar Ansible
sudo apt update -y && sudo apt upgrade -y
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# Crear usuario para ansible
usuario1=ansibleadmin
sudo useradd -U $usuario1 -m -s /bin/bash -G sudo
echo "$usuario1:123" | sudo chpasswd
echo "$usuario1 ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers

# Instalar modulo Ansible necesario para VMware
ansible-galaxy collection install community.vmware
sudo apt install -y python3-pip
pip install pyvmomi

# Crear Inventario de Ansible
mkdir -p ~/gt/ansible-wsl
sudo cat <<EOF | sudo tee ~/gt/ansible-wsl/inventory.yaml
---
jenkins:
  hosts:
    agent1:
      ansible_host: 192.168.42.71
    agent2:
      ansible_host: 192.168.42.66
  vars:
    ansible_user: debian
    ansible_password: debian
EOF

# Crear Archivo de Configuracion de Ansible
sudo cat <<EOF | sudo tee ~/.ansible.cfg
[defaults]
inventory=~/gt/ansible-wsl/inventory.yaml
host_key_checking = False
EOF

# Crear usuario para Docker
usuario2=dockeradmin
sudo useradd -U $usuario2 -m -s /bin/bash -G sudo
echo "$usuario2:123" | sudo chpasswd
echo "$usuario2 ALL=(ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers

# Instalar Docker
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

# Instalar Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install command completion for Docker Compose
sudo curl \
    -L https://raw.githubusercontent.com/docker/compose/1.29.2/contrib/completion/bash/docker-compose \
    -o /etc/bash_completion.d/docker-compose

mkdir -p ~/ps/
mkdir -p ~/gt/
mkdir -p ~/ts/

# Copiar mis repos de alias y wsl
cd ~/ps/
git clone https://github.com/jvinc86/wsl-bash-script.git
git clone https://github.com/jvinc86/alias-ubuntu.git
git clone https://github.com/jvinc86/docker-compose
git clone https://github.com/jvinc86/vagrant/

# Copiar repos idn
# cd ~/gt/
# sudo git clone https://gitlab.int.idnomic.com/package-factory/devops-rocket

# Instalar lc
sudo apt install ruby-full gcc make -y
sudo gem install colorls
source $(dirname $(gem which colorls))/tab_complete.sh

# Instalar lx
EXA_VERSION=$(curl -s "https://api.github.com/repos/ogham/exa/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
curl -Lo exa.zip "https://github.com/ogham/exa/releases/latest/download/exa-linux-x86_64-v${EXA_VERSION}.zip"
sudo unzip -q exa.zip bin/exa -d /usr/local
rm -rf exa.zip

# Instalar OhMyZSH
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
sudo git clone --depth=1 https://gitee.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
sudo sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/g' ~/.zshrc

# Instalar Auto-sugerencias y Highlighting para ZSH
sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions

# Configurar Plugins en ZSH, es decir, Auto-sugerencias, Highlighting y Docker Compose
sudo sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc
sudo sed -i 's/^plugins.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting docker docker-compose)/g' ~/.zshrc | grep ^plugins

# Instalar Powershell en Linux
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | sudo tee /etc/apt/sources.list.d/microsoft.list
sudo apt update
sudo apt install -y powershell

cp ~/.zshrc ~/.zshrc-backup
source ~/ps/alias-ubuntu/alias.sh

# Para finalizar:
#      cat ~/.ssh/id_ed25519.pub
# La copiamos, en Github creamos una llave nueva con esos datos
#      https://github.com/settings/keys
# Ejecutamos los comandos:

#cd ~/ps/wsl-bash-script
#git remote set-url origin git@github.com:jvinc86/wsl-bash-script.git
#git config --global credential.helper store
#git config --global credential.helper cache

#cd ~/ps/alias-ubuntu
#git remote set-url origin git@github.com:jvinc86/alias-ubuntu.git
#git config --global credential.helper store
#git config --global credential.helper cache

#Es posible que debamos correr otra vez:
# sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git $ZSH_CUSTOM/plugins/zsh-autosuggestions
# sudo git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
