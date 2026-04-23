# 🚀 DevOps Knowledge Base (devops-kb)

Welcome to my personal DevOps journey! This repository is a centralized, searchable collection of commands, configurations, and best practices I encounter while mastering DevOps and Cyber Security.

> "Automation is not just about tools; it's a mindset."

## 🧠 The Concept

Instead of searching through endless documentation or browser history, I use a custom-built CLI tool named `sakit` to interact with this knowledge base directly from my Fedora terminal.



## 🛠️ The "sakit" CLI Tool

I've developed a Bash-based tool to manage these notes efficiently. It allows me to search for commands by keywords or add new entries on the fly.

### Features:
- **Search:** Instant keyword search across all categories.
- **Auto-Categorization:** Organizes notes under Markdown headers (`# DOCKER`, `# NETWORK`, etc.).
- **Interactive Add:** A simple command to append new findings without leaving the terminal.

### Installation:
1. Clone this repository:
   ```bash
   git clone [https://github.com/Sakit-Babazade/devops-kb.git](https://github.com/Sakit-Babazade/devops-kb.git) ~/Documents/knowledge-base
````

2.  Make the script executable:
    ```bash
    chmod +x ~/devdb.sh
    ```
3.  Add an alias to your `~/.bashrc`:
    ```bash
    alias sakit='~/devdb.sh'
    ```
4.  Refresh your terminal:
    ```bash
    source ~/.bashrc
    ```

## 📂 Current Structure

The `commands.md` file is organized into several key areas:

  - **Linux Core:** Fedora/DNF, Systemd, and File Permissions.
  - **Networking:** `nmcli`, `ip`, and troubleshooting tools.
  - **Containers:** Docker and Podman workflows.
  - **Infrastructure:** Initial steps into CI/CD and Cloud.

## 🚀 Usage Examples

**Search for a command:**

```bash
sakit docker
```

**Add a new entry (Interactive):**

```bash
sakit add
```

**Add a new entry (One-liner):**

```bash
sakit add NETWORK "ip a" "Show all interface addresses"
```


*Maintained by [Sakit Babazadə](https://github.com/Mr-Sakit) | 2026*
