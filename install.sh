#!/bin/bash

# ==============================================
# Dotfiles Installation Script
# ==============================================
# Creates symlinks from home directory to dotfiles repo

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Dotfiles Installation ===${NC}"
echo "Dotfiles directory: $DOTFILES_DIR"
echo ""

# Files to symlink
FILES=(
    ".bashrc"
    ".bash_profile"
    ".bash_aliases"
    ".tmux.conf"
    ".gitconfig"
)

# Function to create symlink with backup
create_symlink() {
    local src="$DOTFILES_DIR/$1"
    local dst="$HOME/$1"
    
    if [ ! -f "$src" ]; then
        echo -e "${RED}[SKIP]${NC} Source not found: $src"
        return
    fi
    
    # If destination exists and is not a symlink
    if [ -e "$dst" ] && [ ! -L "$dst" ]; then
        mkdir -p "$BACKUP_DIR"
        echo -e "${YELLOW}[BACKUP]${NC} $dst -> $BACKUP_DIR/$1"
        mv "$dst" "$BACKUP_DIR/$1"
    fi
    
    # Remove existing symlink
    [ -L "$dst" ] && rm "$dst"
    
    ln -s "$src" "$dst"
    echo -e "${GREEN}[OK]${NC} $dst -> $src"
}

# Create symlinks for dotfiles
echo "Creating symlinks..."
for file in "${FILES[@]}"; do
    create_symlink "$file"
done

# Starship config
echo ""
echo "Setting up starship config..."
mkdir -p "$HOME/.config"
src="$DOTFILES_DIR/.config/starship.toml"
dst="$HOME/.config/starship.toml"
if [ -f "$src" ]; then
    [ -e "$dst" ] && [ ! -L "$dst" ] && mkdir -p "$BACKUP_DIR" && mv "$dst" "$BACKUP_DIR/starship.toml"
    [ -L "$dst" ] && rm "$dst"
    ln -s "$src" "$dst"
    echo -e "${GREEN}[OK]${NC} $dst -> $src"
fi

# Create scripts directory and symlinks
echo ""
echo "Setting up scripts..."
mkdir -p "$HOME/scripts"

for script in "$DOTFILES_DIR/scripts/"*.sh; do
    if [ -f "$script" ]; then
        name=$(basename "$script")
        dst="$HOME/scripts/$name"
        [ -L "$dst" ] && rm "$dst"
        ln -s "$script" "$dst"
        echo -e "${GREEN}[OK]${NC} $dst -> $script"
    fi
done

# Handle secrets
echo ""
if [ ! -f "$HOME/.secrets" ]; then
    echo -e "${YELLOW}[NOTE]${NC} ~/.secrets not found"
    echo "       Copy the template and fill in your API keys:"
    echo "       cp $DOTFILES_DIR/.secrets.example ~/.secrets"
    echo "       Then edit ~/.secrets with your actual keys"
else
    echo -e "${GREEN}[OK]${NC} ~/.secrets already exists"
fi

# TPM (Tmux Plugin Manager)
echo ""
if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
    echo -e "${YELLOW}[NOTE]${NC} Tmux Plugin Manager not found"
    echo "       Install it with:"
    echo "       git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm"
    echo "       Then press prefix + I in tmux to install plugins"
else
    echo -e "${GREEN}[OK]${NC} TPM already installed"
fi

echo ""
echo -e "${GREEN}=== Installation Complete ===${NC}"
if [ -d "$BACKUP_DIR" ]; then
    echo -e "Backups saved to: ${YELLOW}$BACKUP_DIR${NC}"
fi
echo ""
echo "Next steps:"
echo "  1. Run: source ~/.bashrc"
echo "  2. Create ~/.secrets with your API keys"
echo "  3. In tmux, press prefix + I to install plugins"
