#!/bin/bash

# Configuration
REPO_DIR="$HOME/Desktop/portable_config"
MAIN_BRANCH="main"
WIP_BRANCH="autosave"
THRESHOLD=10

files_and_dirs=(
    "~/.zshrc"
    "~/.zprofile"
    "~/.config/git"
    "~/.config/nvim"
    "~/.config/tmux/tmux.conf"
    "~/.config/starship.toml"
    "~/.config/alacritty/alacritty.toml"
    "~/.config/secrets.env"
)

# Ensure the directory exists
if [ ! -d "$REPO_DIR" ]; then
    echo "Error: Repository directory $REPO_DIR does not exist."
    exit 1
fi
cd "$REPO_DIR" || exit

# Ensure we are on the autosave branch (create it if it doesn't exist)
if ! git rev-parse --verify $WIP_BRANCH >/dev/null 2>&1; then
    echo "Creating $WIP_BRANCH branch..."
    git checkout -b $WIP_BRANCH
else
    # Switch to it if we aren't already there
    current_branch=$(git branch --show-current)
    if [ "$current_branch" != "$WIP_BRANCH" ]; then
        git checkout $WIP_BRANCH
    fi
fi

echo "Copying config files to $REPO_DIR..."

for item in "${files_and_dirs[@]}"; do
    expanded_item=$(eval echo "$item")
    if [ -e "$expanded_item" ]; then
        basename_item=$(basename "$expanded_item")
        # Remove existing copy first to avoid nested directory issues
        rm -rf "$REPO_DIR/$basename_item"

        if [ -d "$expanded_item" ]; then
            cp -r "$expanded_item" "$REPO_DIR/$basename_item"
            echo "Copied directory: $expanded_item"
        else
            cp "$expanded_item" "$REPO_DIR/$basename_item"
            echo "Copied file: $expanded_item"
        fi
    else
        echo "Skipping missing: $expanded_item"
    fi
done

# Remove empty directories (git doesn't track them anyway)
find "$REPO_DIR" -type d -empty -not -path "$REPO_DIR/.git/*" -delete 2>/dev/null

git add .
# Only commit if something actually changed
if ! git diff-index --quiet HEAD --; then
    git commit -m "Auto-backup: $(date +'%Y-%m-%d %H:%M:%S')"
else
    echo "No file changes detected."
fi

# Count how many commits autosave is ahead of main
count=$(git rev-list --count ${MAIN_BRANCH}..${WIP_BRANCH})

if [ "$count" -ge "$THRESHOLD" ]; then
    echo ">>> Threshold reached! Rolling up history..."

    # Switch to main and pull latest to be safe
    git checkout $MAIN_BRANCH
    git pull origin $MAIN_BRANCH -q

    # Squash merge all changes from autosave
    git merge --squash $WIP_BRANCH

    # Create the clean commit
    git commit -m "Config Rollup: $(date +%Y-%m-%d)"
    
    # Push the clean main branch
    git push origin $MAIN_BRANCH -q
    echo ">>> Main branch updated and pushed."

    # Reset autosave to look exactly like main (clears the counter)
    git checkout $WIP_BRANCH
    git reset --hard $MAIN_BRANCH
    git push origin $WIP_BRANCH --force -q
    echo ">>> Autosave branch reset and synced."
else
    # Just push the autosave branch so your work is saved remotely
    git push origin $WIP_BRANCH -q
fi
