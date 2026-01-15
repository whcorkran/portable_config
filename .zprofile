# Only run brew shellenv if NOT in tmux
if [ -z "$TMUX" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi
