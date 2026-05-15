
# GIT
* **git init** : Initializes a new local Git repository
* **git status** : Shows changed, staged, and untracked files in the working tree
* **git add <file>** : Adds a file to the staging area
* **git add .** : Adds all current directory changes to the staging area
* **git commit -m "<message>"** : Records staged changes with a commit message
* **git log** : Shows commit history
* **git log --oneline --graph --all** : Shows a compact visual commit graph for all branches
* **git branch** : Lists local branches and highlights the current branch
* **git branch <branch>** : Creates a new branch
* **git switch <branch>** : Switches to another branch
* **git switch -c <branch>** : Creates and switches to a new branch
* **git merge <branch>** : Merges another branch into the current branch
* **git branch -d <branch>** : Deletes a merged local branch
* **git remote add origin <url>** : Links a local repo to a remote repository
* **git remote set-url origin <url>** : Changes the remote repository URL
* **git fetch origin** : Downloads remote refs without merging them
* **git pull origin <branch>** : Fetches and merges changes from a remote branch
* **git push --set-upstream origin <branch>** : Pushes a branch and sets upstream tracking
* **git push origin <branch>** : Pushes local commits to a remote branch
* **git restore <file>** : Discards unstaged changes in a file
* **git restore --staged <file>** : Removes a file from staging without deleting changes
* **git reset --soft HEAD~1** : Undoes the last commit but keeps changes staged
* **git reset --mixed HEAD~1** : Undoes the last commit and keeps changes unstaged
* **git revert <commit>** : Creates a new commit that reverses an earlier commit
* **git clone <url>** : Downloads a remote repository locally

# LINUX
* **pwd** : Prints the current working directory
* **ls** : Lists files and directories
* **ls -la** : Lists all files, including hidden files, in long format
* **ls -lt** : Lists files sorted by modification time
* **cd <path>** : Changes the current directory
* **cd ..** : Moves one directory up
* **cd ~** : Moves to the current user's home directory
* **cd -** : Switches to the previous directory
* **mkdir -p <dir>** : Creates a directory and missing parent directories
* **touch <file>** : Creates an empty file or updates its timestamp
* **cp <source> <dest>** : Copies files or directories
* **mv <source> <dest>** : Moves or renames files and directories
* **rm <file>** : Removes a file
* **rm -rI <dir>** : Recursively removes a directory with an interactive safety prompt
* **cat <file>** : Prints file contents to the terminal
* **less <file>** : Opens a file in a scrollable pager
* **head -n <count> <file>** : Shows the first lines of a file
* **tail -n <count> <file>** : Shows the last lines of a file
* **tail -f <file>** : Follows appended log output in real time
* **grep "<pattern>" <file>** : Searches for matching text in a file
* **find <path> -name "<pattern>"** : Searches files by name under a path
* **echo "text" > <file>** : Writes text to a file and overwrites existing content
* **echo "text" >> <file>** : Appends text to a file
* **whoami** : Prints the current username
* **id** : Shows user ID and group memberships
* **uname -a** : Shows kernel, architecture, and OS information
* **cat /etc/os-release** : Shows Linux distribution details
* **free -h** : Shows memory and swap usage in human-readable format
* **df -h** : Shows disk usage for mounted filesystems
* **du -sh <path>** : Shows the total size of a file or directory
* **ps aux** : Lists running processes
* **top** : Displays live process and resource usage
* **jobs** : Lists background jobs in the current shell
* **fg <job>** : Brings a background job to the foreground
* **bg <job>** : Resumes a stopped job in the background
* **kill <pid>** : Sends a signal to terminate a process
* **crontab -e** : Edits the current user's scheduled cron jobs
* **sudo apt update** : Updates package metadata on Debian/Ubuntu systems
* **sudo apt install -y <package>** : Installs a package on Debian/Ubuntu without prompting
* **sudo dnf install -y <package>** : Installs a package on Fedora/RHEL-style systems without prompting

# FILE PERMISSIONS
* **chmod 400 <key.pem>** : Restricts a private key so only the owner can read it
* **chmod +x <file>** : Makes a script or binary executable
* **chmod 644 <file>** : Sets owner read/write and everyone else read-only permissions
* **chmod 755 <dir-or-file>** : Allows owner write access and everyone execute/read access
* **chown <user>:<group> <path>** : Changes file or directory ownership
* **sudo chown -R <user>:<group> <dir>** : Recursively changes ownership for a directory tree

# SYSTEMD
* **systemctl status <service>** : Shows the current status and recent logs for a service
* **sudo systemctl start <service>** : Starts a systemd service
* **sudo systemctl stop <service>** : Stops a systemd service
* **sudo systemctl restart <service>** : Restarts a systemd service
* **sudo systemctl enable <service>** : Enables a service to start on boot
* **sudo systemctl enable --now <service>** : Enables and starts a service immediately
* **sudo systemctl disable <service>** : Prevents a service from starting on boot
* **journalctl -u <service>** : Shows logs for a systemd service
* **journalctl -u <service> -f** : Follows live logs for a systemd service

# NETWORKING
* **ping <host>** : Checks basic network reachability
* **curl <url>** : Fetches a URL or tests HTTP connectivity
* **curl -I <url>** : Fetches only HTTP response headers
* **wget <url>** : Downloads content from a URL
* **ssh <user>@<host>** : Opens an SSH session to a remote host
* **ssh -i <key> <user>@<host>** : Connects with a specific SSH private key
* **scp -i <key> <source> <user>@<host>:<dest>** : Copies a file to a remote server over SSH
* **ip addr show** : Shows network interfaces and IP addresses
* **ip route show** : Shows the routing table
* **ss -tlnp** : Shows listening TCP ports and owning processes
* **netstat -tlnp** : Shows listening ports on systems with net-tools installed
* **telnet <host> <port>** : Tests whether a TCP port is reachable
* **nc -vz <host> <port>** : Tests TCP connectivity to a host and port
* **nslookup <domain>** : Queries DNS records for a domain
* **host <domain>** : Resolves DNS information for a domain

# APACHE
* **sudo apt install -y apache2** : Installs Apache on Debian/Ubuntu systems
* **sudo dnf install -y httpd** : Installs Apache on Fedora/RHEL-style systems
* **sudo systemctl enable --now apache2** : Enables and starts Apache on Debian/Ubuntu systems
* **sudo systemctl enable --now httpd** : Enables and starts Apache on Fedora/RHEL-style systems
* **sudo systemctl status apache2** : Checks Apache status on Debian/Ubuntu systems
* **sudo systemctl status httpd** : Checks Apache status on Fedora/RHEL-style systems
* **sudo apache2ctl configtest** : Validates Apache configuration on Debian/Ubuntu systems
* **sudo httpd -t** : Validates Apache configuration on Fedora/RHEL-style systems
* **sudo tail -n 50 /var/log/apache2/error.log** : Shows recent Apache error logs on Debian/Ubuntu

# NGINX
* **sudo apt install -y nginx** : Installs Nginx on Debian/Ubuntu systems
* **sudo dnf install -y nginx** : Installs Nginx on Fedora/RHEL-style systems
* **sudo systemctl enable --now nginx** : Enables and starts Nginx
* **sudo systemctl status nginx** : Checks Nginx service status
* **sudo nginx -t** : Tests Nginx configuration syntax
* **sudo systemctl reload nginx** : Reloads Nginx without dropping active connections
* **sudo ln -s /etc/nginx/sites-available/<site> /etc/nginx/sites-enabled/<site>** : Enables an Nginx site config on Debian/Ubuntu
* **curl -I http://localhost** : Verifies a local web server response
* **sudo tail -n 50 /var/log/nginx/error.log** : Shows recent Nginx error logs

# AZURE CLI
* **az login** : Authenticates Azure CLI with an Azure account
* **az version** : Shows the installed Azure CLI version
* **az account show** : Shows the active subscription and tenant
* **az account list --output table** : Lists available Azure subscriptions
* **az account set --subscription <subscription-id>** : Selects the active Azure subscription
* **az account list-locations --output table** : Lists Azure regions
* **az group create --name <resource-group> --location <region>** : Creates a resource group
* **az group list --output table** : Lists resource groups
* **az group delete --name <resource-group> --no-wait** : Deletes a resource group asynchronously
* **az vm create --resource-group <resource-group> --name <vm-name> --image Ubuntu2204 --admin-username <user> --generate-ssh-keys** : Creates a Linux VM with generated SSH keys
* **az vm list-ip-addresses --resource-group <resource-group> --name <vm-name> --output table** : Shows public and private IP addresses for a VM
* **az vm open-port --resource-group <resource-group> --name <vm-name> --port <port>** : Opens an inbound VM port through its network security group
* **az storage account create --name <storage-account> --resource-group <resource-group> --location <region> --sku Standard_LRS** : Creates a storage account
* **az storage container create --name <container> --account-name <storage-account>** : Creates a Blob Storage container
* **az storage blob upload --account-name <storage-account> --container-name <container> --name <blob> --file <file>** : Uploads a file as a blob
* **az storage blob download --account-name <storage-account> --container-name <container> --name <blob> --file <file>** : Downloads a blob to a local file
* **az storage account keys list --resource-group <resource-group> --account-name <storage-account> --query "[0].value" --output tsv** : Retrieves a storage account key
* **az webapp show --resource-group <resource-group> --name <webapp> --query defaultHostName -o tsv** : Prints an Azure Web App hostname
* **az webapp log tail --resource-group <resource-group> --name <webapp>** : Streams Azure Web App logs

# DOCKER
* **docker --version** : Shows the installed Docker client version
* **docker run** : Starts a new container from a specified image
* **docker run --name <name> -d -p <host-port>:<container-port> <image>** : Runs a detached container with a name and port mapping
* **docker run --rm <image>** : Runs a temporary container and removes it after exit
* **docker build** : Builds an image from a Dockerfile
* **docker build -t <image>:<tag> .** : Builds and tags an image from the current directory
* **docker images** : Lists the images available on the system
* **docker pull** : Pulls an image from Docker Hub or another registry
* **docker ps** : Shows running containers and their ports
* **docker ps -a** : Shows running and stopped containers
* **docker logs** : Used to view the logs of a container
* **docker logs -f <container>** : Streams container logs in real time
* **docker exec** : Allows executing commands inside a running container
* **docker exec -it <container> /bin/sh** : Opens an interactive shell inside a container
* **docker stop <container>** : Stops a running container
* **docker start <container>** : Starts a stopped container
* **docker restart <container>** : Restarts a container
* **docker rm <container>** : Removes a stopped container
* **docker rmi <image>** : Removes an image
* **docker inspect <object>** : Shows low-level JSON details for a Docker object
* **docker stats** : Shows live container resource usage
* **docker login** : Authenticates to a container registry
* **docker tag <source> <target>** : Adds another tag to an image
* **docker push <image>:<tag>** : Pushes an image to a registry
* **docker system prune** : Removes unused Docker data after confirmation

# DOCKERFILE
* **FROM <image>** : Sets the base image for a Docker build stage
* **WORKDIR <path>** : Sets the working directory inside the image
* **COPY <source> <dest>** : Copies files from the build context into the image
* **RUN <command>** : Executes a command while building the image
* **EXPOSE <port>** : Documents the port the containerized app listens on
* **ENV <key>=<value>** : Defines an environment variable in the image
* **CMD ["executable", "arg"]** : Sets the default command for a container
* **ENTRYPOINT ["executable"]** : Sets the main executable for a container

# DOCKER COMPOSE
* **docker compose up** : Creates and starts all services defined in a Compose file
* **docker compose up -d** : Starts Compose services in detached mode
* **docker compose up --build -d** : Rebuilds images and starts services in detached mode
* **docker compose down** : Stops services and removes created containers and networks
* **docker compose build** : Builds images for the services in the Compose file
* **docker compose ps** : Shows the status of containers managed by Compose
* **docker compose logs** : Used to view the logs of the services
* **docker compose logs -f <service>** : Streams logs for a specific service
* **docker compose exec <service> <command>** : Runs a command inside a running service container
* **docker compose config** : Validates and renders the final Compose configuration
* **docker compose pull** : Pulls service images
* **docker compose restart <service>** : Restarts a service
* **docker compose down -v** : Stops services and removes named volumes created by Compose
* **docker-compose up** : Legacy Compose v1 command to create and start services
* **docker-compose down** : Legacy Compose v1 command to stop services and remove containers/networks
* **docker-compose build** : Legacy Compose v1 command to build service images
* **docker-compose ps** : Legacy Compose v1 command to show Compose-managed containers
* **docker-compose logs** : Legacy Compose v1 command to view service logs

# DOCKER NETWORK
* **docker network ls** : Lists all existing networks
* **docker network create <network>** : Creates a new user-defined network
* **docker network inspect <network>** : Shows detailed information about a network
* **docker network connect <network> <container>** : Connects an existing container to a network
* **docker network disconnect <network> <container>** : Disconnects a container from a network
* **docker network rm <network>** : Deletes an unused network
* **docker network prune** : Removes all unused networks permanently

# DOCKER VOLUME
* **docker volume create <volume>** : Creates a new named volume
* **docker volume ls** : Lists all existing volumes
* **docker volume inspect <volume>** : Provides detailed information about one or more volumes
* **docker volume rm <volume>** : Deletes selected volumes
* **docker volume prune** : Removes all unused local volumes
* **docker run -v <volume>:<path> <image>** : Mounts a named volume into a container
* **docker run -v <host-path>:<container-path> <image>** : Mounts a host directory as a bind mount

# GITHUB ACTIONS
* **mkdir -p .github/workflows** : Creates the GitHub Actions workflow directory
* **actions/checkout@v4** : Checks out repository code in a workflow job
* **actions/setup-node@v4** : Installs and configures Node.js in a workflow job
* **actions/setup-java@v4** : Installs and configures a JDK in a workflow job
* **actions/upload-artifact@v4** : Uploads build outputs or reports as workflow artifacts
* **dorny/test-reporter@v1** : Publishes test reports into GitHub Checks
* **azure/login@v1** : Authenticates a workflow to Azure using credentials or OIDC
* **docker/login-action@v3** : Authenticates a workflow to a container registry
* **docker/build-push-action@v6** : Builds and optionally pushes Docker images from a workflow
* **azure/container-apps-deploy-action@v2** : Builds, pushes, and deploys an app to Azure Container Apps
* **workflow_dispatch** : Allows manual workflow runs from the GitHub Actions UI
* **npm ci** : Installs Node.js dependencies reproducibly from package-lock.json
* **npm test --if-present** : Runs tests only if a test script exists
* **npm run build --if-present** : Runs the build script only if it exists
* **mvn clean package -DskipTests=false** : Builds and tests a Maven project

# SONARQUBE
* **docker run --name sonarqube -p 9000:9000 sonarqube:community** : Runs SonarQube Community Edition on port 9000
* **docker compose up -d sonarqube** : Starts SonarQube from a Compose file in detached mode
* **docker logs -f sonarqube** : Follows SonarQube container logs
* **curl <sonarqube-url>** : Checks whether the SonarQube web UI is reachable
* **SonarSource/sonarqube-scan-action** : Runs a SonarQube scan in GitHub Actions
* **SONAR_HOST_URL** : GitHub Actions secret or variable containing the SonarQube server URL
* **SONAR_TOKEN** : GitHub Actions secret containing the SonarQube authentication token

# TERRAFORM
* **sakit terraform new** : Generates a starter Terraform project from an interactive template menu
* **sakit tf new** : Short alias for the Terraform project generator
* **terraform -version** : Shows the installed Terraform version
* **terraform init** : Initializes providers, modules, and backend configuration
* **terraform fmt** : Formats Terraform files using standard HCL style
* **terraform validate** : Checks Terraform configuration syntax and internal consistency
* **terraform plan** : Shows the infrastructure changes Terraform would make
* **terraform apply** : Applies the planned infrastructure changes
* **terraform apply --auto-approve** : Applies changes without an interactive approval prompt
* **terraform destroy** : Destroys resources managed by the current Terraform state
* **terraform destroy --auto-approve** : Destroys managed resources without an interactive prompt
* **terraform output** : Displays output values from the state
* **terraform output <name>** : Displays a specific output value
* **terraform show** : Shows the current state or a saved plan in readable form
* **terraform graph** : Generates a dependency graph in DOT format
* **terraform import <address> <id>** : Imports an existing resource into Terraform state
* **terraform workspace list** : Lists Terraform workspaces
* **terraform workspace new <workspace>** : Creates a new Terraform workspace
* **terraform workspace select <workspace>** : Switches to an existing Terraform workspace
* **terraform workspace show** : Shows the active Terraform workspace

# TERRAFORM STATE
* **terraform state list** : Lists resources tracked in the Terraform state
* **terraform state show <address>** : Shows detailed state for one resource
* **terraform state mv <source> <dest>** : Renames or moves a resource address in state
* **terraform state rm <address>** : Removes a resource from state without destroying it
* **terraform init -migrate-state** : Reconfigures a backend and migrates existing state
* **az storage account keys list --resource-group <resource-group> --account-name <storage-account> --query "[0].value" --output tsv** : Retrieves an Azure Storage key for Terraform backend setup
* **az storage blob list --container-name <container> --account-name <storage-account> --output table** : Lists remote Terraform state blobs in Azure Storage

# ANSIBLE
* **ansible --version** : Shows the installed Ansible version
* **ansible-inventory -i <inventory> --list** : Parses and displays an inventory as JSON
* **ansible-inventory --list** : Displays the default configured inventory
* **ansible all -m ping -i <inventory>** : Tests connectivity to all hosts in an inventory
* **ansible <group> -m ping -i <inventory>** : Tests connectivity to a host group
* **ansible <group> -m ansible.builtin.copy -a "src=<src> dest=<dest>" -i <inventory>** : Copies a local file to managed hosts
* **ansible <group> -m ansible.builtin.file -a "path=<path> state=directory mode=755" -i <inventory>** : Creates a directory on managed hosts
* **ansible <group> -m ansible.builtin.apt -a "name=<package> state=present" --become -i <inventory>** : Installs a package on Debian/Ubuntu managed hosts
* **ansible <group> -m ansible.builtin.service -a "name=<service> state=started enabled=yes" --become -i <inventory>** : Starts and enables a service on managed hosts
* **ansible-playbook <playbook>.yml -i <inventory> --syntax-check** : Validates playbook syntax
* **ansible-playbook <playbook>.yml -i <inventory>** : Runs a playbook against an inventory
* **ansible-playbook <playbook>.yml** : Runs a playbook using the default inventory configuration
* **ansible-galaxy role init <role>** : Creates a standard Ansible role directory structure
* **ansible-galaxy collection install <collection>** : Installs an Ansible collection
* **ansible-doc <module>** : Shows documentation for an Ansible module

# ANSIBLE VAULT
* **ansible-vault create <file>** : Creates a new encrypted variables file
* **ansible-vault view <file>** : Views an encrypted file without editing it
* **ansible-vault edit <file>** : Opens an encrypted file for editing
* **ansible-vault encrypt <file>** : Encrypts an existing file
* **ansible-vault decrypt <file>** : Decrypts an encrypted file
* **ansible-vault rekey <file>** : Changes the password used to encrypt a vault file
* **ansible-playbook <playbook>.yml --ask-vault-pass** : Runs a playbook and prompts for the vault password
* **ansible-playbook <playbook>.yml --vault-password-file <file>** : Runs a playbook using a vault password file

# KUBERNETES
* **kubectl version --client** : Shows the installed kubectl client version
* **kubectl cluster-info** : Shows Kubernetes control plane and service endpoints
* **kubectl get nodes** : Lists cluster nodes
* **kubectl get nodes -o wide** : Lists nodes with extra details such as IPs and OS
* **kubectl get ns** : Lists namespaces
* **kubectl create ns <namespace>** : Creates a namespace
* **kubectl config set-context --current --namespace=<namespace>** : Sets the default namespace for the current context
* **kubectl config view --minify -o jsonpath='{..namespace}{"\n"}'** : Prints the current context namespace
* **kubectl apply -f <file>** : Creates or updates resources from YAML
* **kubectl delete -f <file>** : Deletes resources defined in YAML
* **kubectl get all** : Shows common workload and service resources in the current namespace
* **kubectl get events --sort-by=.lastTimestamp** : Shows recent cluster events sorted by time
* **kubectl explain <resource>** : Shows API documentation for a Kubernetes resource
* **kubectl explain <resource>.<field> --recursive** : Shows nested API documentation for a resource field

# KUBECTL
* **kubectl run <pod> --image=<image> --restart=Never** : Creates a standalone pod from an image
* **kubectl get pods** : Lists pods in the current namespace
* **kubectl get pods -o wide** : Lists pods with node, IP, and status details
* **kubectl describe pod <pod>** : Shows detailed pod information and events
* **kubectl logs <pod>** : Prints pod logs
* **kubectl logs -f <pod>** : Streams pod logs in real time
* **kubectl exec -it <pod> -- /bin/sh** : Opens an interactive shell inside a pod container
* **kubectl label pod <pod> key=value** : Adds or updates labels on a pod
* **kubectl annotate pod <pod> key=value** : Adds or updates annotations on a pod
* **kubectl get pods --show-labels** : Lists pods with their labels
* **kubectl get pods -l key=value** : Filters pods by label selector
* **kubectl get <resource> -o yaml** : Outputs a resource as YAML
* **kubectl get <resource> -o jsonpath='{...}'** : Extracts specific fields from a resource
* **kubectl create deployment <name> --image=<image>** : Creates a deployment
* **kubectl expose deployment <name> --port=<port> --type=<type>** : Exposes a deployment through a service
* **kubectl get deploy,rs,pods -o wide** : Shows deployments, replicasets, and pods together
* **kubectl scale deployment/<name> --replicas=<count>** : Changes the replica count for a deployment
* **kubectl rollout status deployment/<name>** : Watches deployment rollout progress
* **kubectl rollout history deployment/<name>** : Shows deployment revision history
* **kubectl rollout undo deployment/<name>** : Rolls a deployment back to the previous revision
* **kubectl rollout restart deployment/<name>** : Restarts a deployment by triggering a new rollout
* **kubectl port-forward pod/<pod> <local-port>:<pod-port>** : Forwards a local port to a pod
* **kubectl cp <namespace>/<pod>:<remote-path> <local-path>** : Copies files from a pod to the local machine
* **kubectl top pods** : Shows pod resource usage when metrics-server is available
* **kubectl top nodes** : Shows node resource usage when metrics-server is available

# TROUBLESHOOTING
* **ping** : Checks basic network connectivity and DNS resolution
* **telnet** : Used to check the accessibility of a specific host and port
* **nc** : Used to check network connections and transfer data
* **curl** : Verifies data transfer via URL (HTTP/HTTPS, etc.)
* **ss** : Shows active network connections and listening ports
* **netstat** : Shows active network connections and listening ports
* **apk add** : Used to install packages in Alpine-based images
* **apt-get update** : Updates the package list in Debian/Ubuntu-based images
* **apt-get install** : Installs packages in Debian/Ubuntu-based images

# MICRO
* **micro** : Ctrl+S (Save), Ctrl+Q (Quit), Ctrl+E (Command Bar), Ctrl+G (Help)
