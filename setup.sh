#!/bin/bash

REPO_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_PATH="$REPO_DIR/devdb.sh"
ALIAS_LINE="alias sakit='$SCRIPT_PATH'"

echo "⚙️  Setting up 'sakit' alias..."

chmod +x "$SCRIPT_PATH"

if grep -q "alias sakit=" ~/.bashrc; then
    echo "⚠️  Alias 'sakit' already exists in .bashrc. Updating path..."
    sed -i "s|alias sakit=.*|$ALIAS_LINE|" ~/.bashrc
else
    echo "➕ Adding 'sakit' alias to .bashrc..."
    echo "" >> ~/.bashrc
    echo "# Sakit Knowledge Base Alias" >> ~/.bashrc
    echo "$ALIAS_LINE" >> ~/.bashrc
fi

echo "✅ Setup complete!"
echo "🔄 Please run 'source ~/.bashrc' or restart your terminal to start using 'sakit'."
