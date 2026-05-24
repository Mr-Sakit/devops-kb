# Sakit-DB: Personal DevOps Knowledge Base

Sakit-DB is a lightweight, terminal-first knowledge base for DevOps commands. It stores everything in Markdown and provides fast search, quick entry, and optional auto-sync to GitHub.

## Key Features

- **Fast search:** Find commands directly from the terminal.
- **Category listing:** Browse all available command groups with `sakit list`.
- **Install/uninstall helpers:** Install or remove common DevOps tools from one repo.
- **Preview mode:** Show install/uninstall commands without running them.
- **Doctor checks:** Validate project files and local setup with one command.
- **Explain mode:** Read longer notes for selected commands.
- **Terraform generator:** Create starter Terraform projects or build custom Azure stacks from terminal prompts.
- **Quiet execution:** Install/uninstall output stays clean unless an error occurs.
- **Quick entry:** Add a single command or use bulk entry for speed.
- **Auto-sync:** Updates can be committed and pushed automatically.
- **Markdown storage:** Data lives in `commands.md`, readable in GitHub or Obsidian.

## Project Files

- `devdb.sh` - Main script: search, add, bulk add, category list, install/uninstall helpers.
- `generators/terraform.sh` - Interactive Terraform project generator.
- `templates/terraform/` - Terraform starter templates used by the generator.
- `commands.md` - Command database (categorized).
- `explanations.md` - Longer command explanations and usage notes.
- `installations.md` - Installation steps per tool and package manager.
- `uninstallations.md` - Uninstall steps per tool and package manager.
- `setup.sh` - Adds the `sakit` alias to your shell.

## Usage

### Search
```bash
sakit docker
```
Example output:
![sakit docker example](docker.png)

### List a Category
Supports multi-word categories:
```bash
sakit @docker
sakit @docker compose
```
Example output:
![sakit @docker example](@docker.png)

### List Available Entries
```bash
sakit list
sakit install list
sakit uninstall list
```

### Explain a Command
```bash
sakit explain "docker run"
sakit explain "kubectl apply"
```

### Generate Terraform Projects
```bash
sakit terraform new
sakit tf new
```

The interactive mode uses inline arrow-key menus for template and Azure location selection. Common regions are shown first, with additional regions under `More...` grouped by geography. Linux VM, custom builder, and private VMSS stack projects also prompt for VM size, Ubuntu image, and SSH public key when compute resources are selected. VM sizes show a small recommended list first, with extra sizes grouped and paged under `More...`; if Azure CLI is signed in, sizes are discovered from the selected region, otherwise a static fallback list is used.

`Azure Custom Builder` uses a checkbox menu so you can select resources such as Resource Group, VNet, Subnet, NSG, Linux VM, VMSS, Internal Load Balancer, Azure SQL, Private Endpoint, Key Vault, App Gateway/WAF, Monitoring, and Backup. Required dependencies are resolved automatically and shown in the architecture preview before files are created. Use `←/→` or `space` to toggle a resource.

Custom Builder supports two project styles: `flat` keeps resources in the root project, while `module` writes root files that call focused child modules under `modules/` such as `network`, `compute`, `load_balancer`, `data`, `security`, and `operations`.

Use `-l` or `--learn` to generate a more explanatory README for labs and study notes. Default mode keeps README files short for practical work.

Non-interactive example:
```bash
sakit terraform new --template azure-vnet-subnet --dir my-vnet-lab --prefix sakit --location swedencentral --yes
sakit terraform new --template azure-linux-vm --dir my-vm-lab --prefix sakit --location swedencentral --vm-size Standard_B1s --os-image ubuntu-24-04 --ssh-key-file ~/.ssh/id_ed25519.pub --yes
sakit terraform new --template azure-custom-builder --dir my-custom-lab --prefix sakit --location swedencentral --components resource-group,vnet,subnet,nsg,linux-vm --vm-size Standard_B1s --os-image ubuntu-22-04 --ssh-key-file ~/.ssh/id_ed25519.pub --yes
sakit terraform new --template azure-custom-builder --dir my-module-lab --prefix sakit --location swedencentral --components internal-lb --style module --vm-size Standard_B1s --os-image ubuntu-22-04 --ssh-key-file ~/.ssh/id_ed25519.pub --yes
sakit terraform new --template azure-custom-builder --dir my-learning-lab --prefix sakit --location swedencentral --components internal-lb --vm-size Standard_B1s --os-image ubuntu-22-04 --ssh-key-file ~/.ssh/id_ed25519.pub -l --yes
sakit terraform new --template azure-private-vmss-stack --dir my-private-stack --prefix secureflow --location swedencentral --vm-size Standard_B1s --os-image ubuntu-22-04 --ssh-key-file ~/.ssh/id_ed25519.pub --yes
```

### Install and Uninstall Tools
Default mode keeps output quiet and only prints command output if an error occurs:
```bash
sakit install micro
sakit uninstall micro
```

Preview commands without executing them:
```bash
sakit install docker -show
sakit uninstall docker -show
```

Use verbose mode to see every command's full output:
```bash
sakit install docker --verbose
sakit uninstall docker --verbose
```

### Health Check
```bash
sakit doctor
```

## How It Works

1. Capture input via terminal or temp file.
2. Parse into Markdown items (`* **cmd** : desc`).
3. Append to the right category in `commands.md`.
4. Optionally commit and push to GitHub.

## Installation

1. Clone the repo:
   ```bash
   git clone https://github.com/Mr-Sakit/devops-kb.git
   ```
2. Enter the repo:
   ```bash
   cd devops-kb
   ```
3. Make setup executable:
   ```bash
   chmod +x setup.sh
   ```
4. Run setup (adds alias and makes script executable):
   ```bash
   ./setup.sh
   ```
5. Reload your shell:
   ```bash
   source ~/.bashrc
   ```
