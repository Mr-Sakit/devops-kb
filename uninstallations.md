# GIT
dnf: sudo dnf remove -y git
apt: sudo apt-get remove -y git

# DOCKER
dnf: sudo systemctl disable --now docker || true
dnf: sudo dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
apt: sudo systemctl disable --now docker || true
apt: sudo apt-get remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# TERRAFORM
dnf: sudo dnf remove -y terraform
apt: sudo apt-get remove -y terraform

# AZURE CLI
dnf: sudo dnf remove -y azure-cli
apt: sudo apt-get remove -y azure-cli

# KUBECTL
dnf: sudo rm -f /usr/local/bin/kubectl
apt: sudo rm -f /usr/local/bin/kubectl

# HELM
dnf: sudo dnf remove -y helm
apt: sudo apt-get remove -y helm

# ANSIBLE
dnf: sudo dnf remove -y ansible
apt: sudo apt-get remove -y ansible

# NODEJS
dnf: sudo dnf remove -y nodejs npm
apt: sudo apt-get remove -y nodejs npm

# NPM
dnf: sudo dnf remove -y npm
apt: sudo apt-get remove -y npm

# JAVA
dnf: sudo dnf remove -y java-21-openjdk-devel
apt: sudo apt-get remove -y openjdk-21-jdk

# MAVEN
dnf: sudo dnf remove -y maven
apt: sudo apt-get remove -y maven

# SONARQUBE
dnf: docker rm -f sonarqube
apt: docker rm -f sonarqube

# MICRO
dnf: sudo dnf remove -y micro
apt: sudo apt-get remove -y micro

# VIM
dnf: sudo dnf remove -y vim
apt: sudo apt-get remove -y vim
