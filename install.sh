#!/bin/bash

# Configuration - must match backup.sh
REPO_DIR="$HOME/Desktop/portable_config"

# Same list as backup.sh - paths relative to $HOME
files_and_dirs=(
    "~/.zshrc"
    "~/.zprofile"
    "~/.config/git"
    "~/.config/nvim"
    "~/.config/tmux/tmux.conf"
    "~/.config/starship.toml"
    "~/.config/alacritty/alacritty.toml"
    "~/.config/secrets.env"
    "~/.config/Code/User/settings.json"
    "~/.config/Code/User/keybindings.json"
    "~/.config/Code/User/snippets"
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
                    read -p "  Replace it? [y/N] " -n 1 -r
                    echo ""
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

echo ""
echo "Installation complete."
