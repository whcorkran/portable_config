#!/bin/bash

# Get the current working directory
current_dir=$(pwd)

# Define the list of files and directories to copy
files_and_dirs=(
    "~/.zshrc"
    "~/.zprofile"
    "~/.config/git"
    "~/.config/nvim"
    "~/.config/tmux/tmux.conf"
    "~/.config/starship.toml"
    "~/.config/alacritty/alacritty.toml"
)

# Loop through the list and copy each item to the current directory
for item in "${files_and_dirs[@]}"; do
    # Expand the ~ to the full home directory
    expanded_item=$(eval echo "$item")

    # Check if the file/directory exists
    if [ -e "$expanded_item" ]; then
        # If it's a directory, copy it recursively
        if [ -d "$expanded_item" ]; then
            cp -r "$expanded_item" "$current_dir/"
            echo "Copied directory: $expanded_item"
        else
            # If it's a file, just copy it
            cp "$expanded_item" "$current_dir/"
            echo "Copied file: $expanded_item"
        fi
    else
        echo "Skipping non-existent file or directory: $expanded_item"
    fi
done

echo "Config backup complete!"

date=$(date +%Y-%m-%d)
repo=$(echo "$HOME/Desktop/portable_config")
git -C $repo add .
git -C $repo commit -m "$date"
git -C $repo push origin main -q

