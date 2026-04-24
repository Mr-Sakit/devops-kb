# 🛠️ Sakit-DB: Personal DevOps Knowledge Base

A lightweight, terminal-based knowledge management system designed for DevOps engineers to quickly store and retrieve terminal commands. It features an automated local-to-cloud synchronization workflow.

## 🚀 Key Features

- **Instant Search:** Find any command or cheat sheet directly from your terminal.
- **Minimalist Data Entry:** Rapidly add single or multiple commands using the `bulk` mode.
- **Auto-Sync (CI/CD style):** Every update is automatically committed and pushed to GitHub.
- **Markdown Powered:** All data is stored in a structured `commands.md` file, perfectly rendered in GitHub and Obsidian.

---

## 📂 Project Structure

- `devdb.sh`: The core Bash script containing the logic for searching, adding, and syncing.
- `commands.md`: The central database where all commands are categorized and stored.

---

## 🛠️ Usage

### 1. Search for a Command
Simply type `sakit` followed by your keyword:
```bash
sakit docker
```

### 2. Deep Category Filtering (New!)
To see all commands within a specific category (supports multi-word names):

```bash
sakit @docker
sakit @docker compose
```
*This mode provides a "Full List" view for the targeted category only.*

### 3. Add a Single Entry
```bash
sakit add
```
*Interactive prompts will guide you through Category, Command, and Description.*

### 4. Bulk Add (Fast Entry)
Add multiple commands at once using the minimalist format:
```bash
sakit bulk
```
**Format in editor:**
```text
.LINUX
htop
 Process monitor
ls -la
 List all files including hidden
```

---

## ⚙️ How it Works (Automation Workflow)

1. **Input:** The script captures data via terminal or a temporary file.
2. **Parsing:** The Bash logic cleans and formats the input into Markdown list items (`* **cmd** : desc`).
3. **Storage:** Appends the formatted data to the appropriate category in `commands.md`.
4. **Git Sync:**
   - `git add commands.md`
   - `git commit -m "feat: updated knowledge base"`
   - `git push origin main`

---

## 🔧 Installation

1. Clone the repository:
   ```bash
   git clone [https://github.com/Mr-Sakit/devops-kb.git](https://github.com/Mr-Sakit/devops-kb.git)
   ```
2. Add an alias to your `.bashrc` or `.zshrc`:
   ```bash
   alias sakit='~/path/to/devdb.sh'
   ```
3. Ensure the script is executable:
   ```bash
   chmod +x devdb.sh
   ```

---

*Created with a focus on speed and terminal productivity.*

