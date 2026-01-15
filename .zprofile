# macOS: initialize system PATH
if [[ "$OSTYPE" == "darwin"* ]]; then
    eval "$(/usr/libexec/path_helper -s)"
fi

export COLORTERM=truecolor

# SSH agent socket (Linux systemd)
if [[ -n "$XDG_RUNTIME_DIR" && -S "$XDG_RUNTIME_DIR/ssh-agent.socket" ]]; then
    export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
fi

# always nvim
export EDITOR=nvim
export VISUAL=nvim
