#!/usr/bin/env bash

set -e

REPO_URL="https://github.com/lla1dlaw/.env_setup.git"
TARGET_DIR="$HOME/.env_setup"
BW_ITEM_NAME="Ansible Vault"

echo "Starting system bootstrap..."

# 1. Determine Package Manager & Install Prerequisites
PACKAGE_MANAGER="other"
if command -v apt-get >/dev/null 2>&1; then PACKAGE_MANAGER="apt-get";
elif command -v dnf >/dev/null 2>&1; then PACKAGE_MANAGER="dnf";
elif command -v pacman >/dev/null 2>&1; then PACKAGE_MANAGER="pacman";
elif command -v zypper >/dev/null 2>&1; then PACKAGE_MANAGER="zypper";
else
    echo "Error: No known package manager found."
    exit 1
fi

echo "Installing prerequisites (curl, git, unzip, jq)..."
if [ "$PACKAGE_MANAGER" = "apt-get" ]; then
    sudo apt-get update -y && sudo apt-get install -y curl git unzip jq
elif [ "$PACKAGE_MANAGER" = "dnf" ]; then
    sudo dnf install -y curl git unzip jq
fi

# 2. Install Bitwarden CLI if missing
if ! command -v bw >/dev/null 2>&1; then
    echo "Installing Bitwarden CLI..."
    curl -Lso bw.zip "https://vault.bitwarden.com/download/?app=cli&platform=linux"
    unzip -q bw.zip
    mkdir -p "$HOME/.local/bin"
    mv bw "$HOME/.local/bin/bw"
    chmod +x "$HOME/.local/bin/bw"
    export PATH="$HOME/.local/bin:$PATH"
    rm bw.zip
fi

# 3. Authenticate with Bitwarden
echo ""
echo "=== Bitwarden Authentication ==="
echo "Please log in to retrieve your Ansible Vault password."
read -p "Bitwarden Email: " BW_EMAIL

# Login and capture the session token. (This will prompt for Master Password and 2FA)
export BW_SESSION=$(bw login "$BW_EMAIL" --raw)

if [ -z "$BW_SESSION" ]; then
    echo "Login failed or session exists. Attempting to unlock..."
    export BW_SESSION=$(bw unlock --raw)
fi

if [ -z "$BW_SESSION" ]; then
    echo "Failed to authenticate with Bitwarden. Exiting."
    exit 1
fi

# 4. Fetch Ansible Vault Password
echo "Fetching Ansible Vault password..."
VAULT_PASS_FILE=$(mktemp)
# Ensure the temp file is only readable by the current user
chmod 600 "$VAULT_PASS_FILE" 

if ! bw get password "$BW_ITEM_NAME" > "$VAULT_PASS_FILE"; then
    echo "Error: Could not find password for item '$BW_ITEM_NAME' in Bitwarden."
    rm -f "$VAULT_PASS_FILE"
    bw lock
    exit 1
fi

# Lock Bitwarden immediately after retrieval
bw lock
echo "Bitwarden locked. Password retrieved securely."

# 5. Clone the Repository
if [ ! -d "$TARGET_DIR" ]; then
    echo "Cloning dotfiles repository..."
    git clone "$REPO_URL" "$TARGET_DIR"
else
    echo "Repository already exists at $TARGET_DIR. Pulling latest..."
    cd "$TARGET_DIR" && git pull origin main
fi

# 6. Execute the Initial Setup
echo "Initiating environment setup..."
cd "$TARGET_DIR"

# Export the file path. Ansible natively reads this variable to decrypt the vault.
export ANSIBLE_VAULT_PASSWORD_FILE="$VAULT_PASS_FILE"

# Make the wrapper script executable and run it
chmod +x ./dotfiles
./dotfiles init

# 7. Secure Cleanup
echo "Cleaning up sensitive data..."
rm -f "$VAULT_PASS_FILE"
unset ANSIBLE_VAULT_PASSWORD_FILE
unset BW_SESSION

echo "Bootstrap complete."
