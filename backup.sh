#!/bin/bash

# Configuration
REPO_DIR="$HOME/Desktop/portable_config"
BRANCH="main"

# Detect OS and set VS Code path
if [[ "$OSTYPE" == "darwin"* ]]; then
    VSCODE_USER="$HOME/Library/Application Support/Code/User"
else
    VSCODE_USER="$HOME/.config/Code/User"
fi

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

# VS Code files (use detected path)
vscode_files=(
    "settings.json"
    "keybindings.json"
    "snippets"
)

# Ensure the directory exists
if [ ! -d "$REPO_DIR" ]; then
    echo "Error: Repository directory $REPO_DIR does not exist."
    exit 1
fi
cd "$REPO_DIR" || exit

# Ensure we're on the right branch
current_branch=$(git branch --show-current)
if [ "$current_branch" != "$BRANCH" ]; then
    git checkout "$BRANCH" || exit 1
fi

# Build list of expected relative paths
expected_paths=()
for item in "${files_and_dirs[@]}"; do
    expanded_item=$(eval echo "$item")
    rel_path="${expanded_item#$HOME/}"
    expected_paths+=("$rel_path")
done
# Add VS Code paths (stored in standardized location)
for item in "${vscode_files[@]}"; do
    expected_paths+=(".config/Code/User/$item")
done
expected_paths+=(".config/Code/extensions.txt")

# Clean up: remove tracked files that are no longer in our list
echo "Cleaning up stale backups..."
git ls-files | while read -r tracked_file; do
    # Skip repo-specific files
    case "$tracked_file" in
        .gitignore|backup.sh|install.sh|README.md|LICENSE)
            continue
            ;;
    esac

    # Check if this tracked file is under any expected path
    is_expected=false
    for expected in "${expected_paths[@]}"; do
        if [ "$tracked_file" = "$expected" ] || [[ "$tracked_file" == "$expected"/* ]]; then
            is_expected=true
            break
        fi
    done

    if [ "$is_expected" = false ]; then
        echo "Removing stale: $tracked_file"
        git rm -f "$tracked_file" 2>/dev/null
        rm -f "$REPO_DIR/$tracked_file" 2>/dev/null
    fi
done

# Remove untracked files/dirs not in our list (except repo files)
shopt -s dotglob
for entry in "$REPO_DIR"/*; do
    [ -e "$entry" ] || continue
    entry_basename=$(basename "$entry")

    case "$entry_basename" in
        .git|.gitignore|backup.sh|install.sh|README.md|LICENSE)
            continue
            ;;
    esac

    entry_rel="${entry#$REPO_DIR/}"
    is_expected=false
    for expected in "${expected_paths[@]}"; do
        if [ "$entry_rel" = "$expected" ] || [[ "$expected" == "$entry_rel"/* ]]; then
            is_expected=true
            break
        fi
    done

    if [ "$is_expected" = false ]; then
        echo "Removing untracked: $entry_rel"
        rm -rf "$entry"
    fi
done
shopt -u dotglob

echo "Copying config files to $REPO_DIR..."

for item in "${files_and_dirs[@]}"; do
    expanded_item=$(eval echo "$item")
    if [ -e "$expanded_item" ]; then
        rel_path="${expanded_item#$HOME/}"
        dest_path="$REPO_DIR/$rel_path"

        # Create parent directory if needed
        mkdir -p "$(dirname "$dest_path")"

        # Remove existing and copy fresh
        rm -rf "$dest_path"
        cp -r "$expanded_item" "$dest_path"
        echo "Copied: $rel_path"
    else
        echo "Skipping missing: $expanded_item"
    fi
done

# Copy VS Code files (from OS-specific location to standardized repo path)
for item in "${vscode_files[@]}"; do
    source_path="$VSCODE_USER/$item"
    dest_path="$REPO_DIR/.config/Code/User/$item"

    if [ -e "$source_path" ]; then
        mkdir -p "$(dirname "$dest_path")"
        rm -rf "$dest_path"
        cp -r "$source_path" "$dest_path"
        echo "Copied: .config/Code/User/$item"
    else
        echo "Skipping missing: $source_path"
    fi
done

# Remove empty directories
find "$REPO_DIR" -type d -empty -not -path "$REPO_DIR/.git/*" -delete 2>/dev/null

# Export VS Code extensions list
if command -v code &>/dev/null; then
    echo "Exporting VS Code extensions list..."
    mkdir -p "$REPO_DIR/.config/Code"
    code --list-extensions > "$REPO_DIR/.config/Code/extensions.txt"
    echo "Exported $(wc -l < "$REPO_DIR/.config/Code/extensions.txt" | tr -d ' ') extensions"
fi

# Stage all changes
git add -A

# Commit if there are changes
if ! git diff --cached --quiet; then
    git commit -m "Backup: $(date +'%Y-%m-%d %H:%M:%S')"
    echo "Changes committed."

    # Push to remote
    if git remote get-url origin &>/dev/null; then
        git push origin "$BRANCH" && echo "Pushed to remote."
    fi
else
    echo "No changes to commit."
fi
