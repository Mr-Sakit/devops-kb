# GIT
dnf: sudo dnf install -y git
apt: sudo apt-get update && sudo apt-get install -y git

# DOCKER
dnf: sudo dnf -y install dnf-plugins-core
dnf: sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
dnf: sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
dnf: sudo systemctl enable --now docker
dnf: sudo usermod -aG docker $USER && echo "NOTE: Close and reopen the terminal or type 'newgrp docker' to enable Docker permissions."
apt: sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg
apt: sudo install -m 0755 -d /etc/apt/keyrings
apt: sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
apt: sudo chmod a+r /etc/apt/keyrings/docker.asc
apt: echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt: sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
apt: sudo systemctl enable --now docker
apt: sudo usermod -aG docker $USER && echo "NOTE: Close and reopen the terminal or type 'newgrp docker' to enable Docker permissions."

# TERRAFORM
dnf: sudo dnf install -y dnf-plugins-core
dnf: sudo dnf config-manager addrepo --from-repofile=https://rpm.releases.hashicorp.com/fedora/hashicorp.repo
dnf: sudo dnf -y install terraform
apt: wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
apt: echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
apt: sudo apt-get update && sudo apt-get install -y terraform

# AZURE CLI
dnf: sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
dnf: echo -e "[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/azure-cli.repo
dnf: sudo dnf install -y azure-cli
apt: sudo apt-get update && sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
apt: sudo mkdir -p /etc/apt/keyrings
apt: curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
apt: echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/azure-cli.list
apt: sudo apt-get update && sudo apt-get install -y azure-cli

# KUBECTL
dnf: sudo dnf install -y curl
dnf: curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
dnf: sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
dnf: kubectl version --client
apt: sudo apt-get update && sudo apt-get install -y curl ca-certificates
apt: curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
apt: sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
apt: kubectl version --client

# HELM
dnf: sudo dnf install -y helm
apt: sudo apt-get update && sudo apt-get install -y curl gpg apt-transport-https
apt: curl -fsSL https://packages.buildkite.com/helm-linux/helm-debian/gpgkey | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
apt: echo "deb [signed-by=/usr/share/keyrings/helm.gpg] https://packages.buildkite.com/helm-linux/helm-debian/any/ any main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
apt: sudo apt-get update && sudo apt-get install -y helm

# ANSIBLE
dnf: sudo dnf install -y ansible
apt: sudo apt update && sudo apt install -y software-properties-common
apt: sudo add-apt-repository --yes --update ppa:ansible/ansible
apt: sudo apt install -y ansible

# NODEJS
dnf: sudo dnf install -y nodejs npm
apt: sudo apt-get update && sudo apt-get install -y nodejs npm

# NPM
dnf: sudo dnf install -y npm
apt: sudo apt-get update && sudo apt-get install -y npm

# JAVA
dnf: sudo dnf install -y java-21-openjdk-devel
apt: sudo apt-get update && sudo apt-get install -y openjdk-21-jdk

# MAVEN
dnf: sudo dnf install -y maven
apt: sudo apt-get update && sudo apt-get install -y maven

# SONARQUBE
dnf: docker run --name sonarqube -p 9000:9000 -d sonarqube:community
apt: docker run --name sonarqube -p 9000:9000 -d sonarqube:community

# MICRO
dnf: sudo dnf install -y micro 
apt: sudo apt update && sudo apt install -y micro 

# VIM
dnf: sudo dnf install -y vim
apt: sudo apt update && sudo apt install -y vim
