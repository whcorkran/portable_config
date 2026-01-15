#!/bin/bash

# Configuration - auto-detect repo location
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect OS and set VS Code path
if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_USER="$HOME/Library/Application Support/Code/User"
else
    VSCODE_USER="$HOME/.config/Code/User"
fi

# Same list as backup.sh - paths relative to $HOME
files_and_dirs=(
    "~/.zshrc"
    "~/.zprofile"
    "~/.ssh/config"
    "~/.config/git"
    "~/.config/nvim"
    "~/.config/tmux/tmux.conf"
    "~/.config/starship.toml"
    "~/.config/alacritty/alacritty.toml"
    "~/.config/secrets.env"
)

# VS Code files (stored in repo at .config/Code/User/, installed to OS-specific path)
vscode_files=(
    "settings.json"
    "keybindings.json"
    "snippets"
)

# Ensure repo directory exists
if [ ! -d "$REPO_DIR" ]; then
    echo "Error: Repository directory $REPO_DIR does not exist."
    exit 1
fi

echo "Installing config files from $REPO_DIR..."

for item in "${files_and_dirs[@]}"; do
    expanded_item=$(eval echo "$item")
    # Get path relative to $HOME
    rel_path="${expanded_item#$HOME/}"
    source_path="$REPO_DIR/$rel_path"
    dest_path="$expanded_item"

    # Skip if backup doesn't exist
    if [ ! -e "$source_path" ]; then
        echo "Skipping (not in backup): $rel_path"
        continue
    fi

    # Create parent directories as needed (merge into existing hierarchy)
    dest_dir=$(dirname "$dest_path")
    mkdir -p "$dest_dir"

    # Fix SSH directory permissions (must be 700)
    if [[ "$dest_dir" == *".ssh"* ]]; then
        chmod 700 "$HOME/.ssh" 2>/dev/null
    fi

    # Handle files: just overwrite the specific file
    if [ -f "$source_path" ]; then
        if [ -e "$dest_path" ]; then
            echo ""
            echo "Warning: $dest_path already exists."
            read -p "Replace it? [y/N] " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Skipped: $rel_path"
                continue
            fi
        fi
        cp "$source_path" "$dest_path"
        # Fix SSH config permissions (must be 600)
        if [[ "$dest_path" == *".ssh/config" ]]; then
            chmod 600 "$dest_path"
        fi
        echo "Installed file: $rel_path"

    # Handle directories: merge contents, only prompt for conflicting files
    elif [ -d "$source_path" ]; then
        if [ ! -d "$dest_path" ]; then
            # Destination doesn't exist, just copy the whole directory
            cp -r "$source_path" "$dest_path"
            echo "Installed directory: $rel_path"
        else
            # Destination exists, merge by copying files individually
            echo "Merging into existing: $rel_path"
            while IFS= read -r -d '' src_file; do
                # Get the relative path within the source directory
                inner_rel="${src_file#$source_path/}"
                dest_file="$dest_path/$inner_rel"
                dest_file_dir=$(dirname "$dest_file")
                mkdir -p "$dest_file_dir"

                if [ -e "$dest_file" ]; then
                    echo ""
                    echo "  Warning: $dest_file already exists."
                    read -p "  Replace it? [y/N] " -n 1 -r < /dev/tty
                    echo "" > /dev/tty
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        echo "  Skipped: $inner_rel"
                        continue
                    fi
                fi
                cp "$src_file" "$dest_file"
                echo "  Installed: $inner_rel"
            done < <(find "$source_path" -type f -print0)
        fi
    fi
done

# Install VS Code config files (from standardized repo path to OS-specific location)
echo ""
echo "Installing VS Code settings..."
for item in "${vscode_files[@]}"; do
    source_path="$REPO_DIR/.config/Code/User/$item"
    dest_path="$VSCODE_USER/$item"

    if [ ! -e "$source_path" ]; then
        echo "Skipping (not in backup): $item"
        continue
    fi

    mkdir -p "$VSCODE_USER"

    if [ -f "$source_path" ]; then
        if [ -e "$dest_path" ]; then
            echo ""
            echo "Warning: $dest_path already exists."
            read -p "Replace it? [y/N] " -n 1 -r
            echo ""
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Skipped: $item"
                continue
            fi
        fi
        cp "$source_path" "$dest_path"
        echo "Installed: $item"
    elif [ -d "$source_path" ]; then
        if [ ! -d "$dest_path" ]; then
            cp -r "$source_path" "$dest_path"
            echo "Installed directory: $item"
        else
            echo "Merging into existing: $item"
            while IFS= read -r -d '' src_file; do
                inner_rel="${src_file#$source_path/}"
                dest_file="$dest_path/$inner_rel"
                mkdir -p "$(dirname "$dest_file")"
                if [ -e "$dest_file" ]; then
                    echo ""
                    echo "  Warning: $dest_file already exists."
                    read -p "  Replace it? [y/N] " -n 1 -r < /dev/tty
                    echo "" > /dev/tty
                    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                        echo "  Skipped: $inner_rel"
                        continue
                    fi
                fi
                cp "$src_file" "$dest_file"
                echo "  Installed: $inner_rel"
            done < <(find "$source_path" -type f -print0)
        fi
    fi
done

# Install VS Code extensions
extensions_file="$REPO_DIR/.config/Code/extensions.txt"
if [ -f "$extensions_file" ] && command -v code &>/dev/null; then
    echo ""
    echo "Found VS Code extensions list ($(wc -l < "$extensions_file" | tr -d ' ') extensions)."
    read -p "Install VS Code extensions? [y/N] " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        while read -r extension; do
            echo "Installing: $extension"
            code --install-extension "$extension" --force 2>/dev/null
        done < "$extensions_file"
        echo "Extensions installed."
    else
        echo "Skipped VS Code extensions."
    fi
fi

echo ""
echo "Installation complete."
