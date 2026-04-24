# DOCKER
dnf: sudo dnf -y install dnf-plugins-core
dnf: sudo dnf config-manager addrepo --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
dnf: sudo dnf install -y docker-ce docker-ce-cli containerd.io
dnf: sudo systemctl enable --now docker
dnf: sudo dnf install -y docker-ce docker-ce-cli containerd.io && sudo systemctl enable --now docker
apt: sudo apt-get update && sudo apt-get install -y ca-certificates curl gnupg && sudo install -m 0755 -d /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg && sudo chmod a+r /etc/apt/keyrings/docker.gpg && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null && sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io && sudo usermod -aG docker $USER && echo "⚠️ NOTE: Close and reopen the terminal or type 'newgrp docker' to enable Docker permissions!"

# TERRAFORM
dnf: sudo dnf install -y dnf-plugins-core && sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo && sudo dnf -y install terraform
apt: wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list && sudo apt update && sudo apt install terraform
# MICRO
dnf: sudo dnf install -y micro && echo "🚀 Micro installed! Use Ctrl+Q to quit."
apt: sudo apt update && sudo apt install -y micro && echo "🚀 Micro installed! Use Ctrl+Q to quit."

# VIM
dnf: sudo dnf install -y vim
apt: sudo apt update && sudo apt install -y vim
