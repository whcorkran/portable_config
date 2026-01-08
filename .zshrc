# .zshrc
[[ -f ~/.zprofile ]] && source ~/.zprofile
# >>> conda initialize >>>
. "$HOME/anaconda3/etc/profile.d/conda.sh"
# <<< conda initialize <<<

# === EVAL ===
eval "$(starship init zsh)"  # prompt

# === ZSH TOOLS ===
# Utilities
eval "$(zoxide init zsh)" #zoxide 
source ~/.fzf.zsh >/dev/null 2>&1 #fzf

# Tab Completion
fpath=(
  /usr/share/zsh/site-functions
  /usr/share/zsh/vendor-completions
  $fpath
)
autoload -Uz compinit; compinit -u
zstyle ':completion:*:git-checkout:*' sort false
zstyle ':completion:*:descriptions' format '[%d]'
# set list-colors to enable filename colorizing
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' menu no
# preview directory's content with eza when completing cd
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'
# fzf-tab does not follow FZF_DEFAULT_OPTS by default
zstyle ':fzf-tab:*' fzf-flags --no-clear --height=40%  --bind=enter:accept --info=inline
if [[ -n "$TMUX" ]]; then
  zstyle ':fzf-tab:*' fzf-command ftb-tmux-popup
  zstyle ':fzf-tab:*' popup-min-size 50 8
fi
zstyle ':fzf-tab:*' use-fzf-default-opts no

source ~/opt/fzf-tab/fzf-tab.plugin.zsh # tab completion fzf, needs to be git cloned!
# alacritty ubuntu compatibility fix: sed -i '83s/^/#/' ~/opt/fzf-tab/lib/-ftb-fzf

source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh # suggestions
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh #syntax

# -- ghostty zsh compatibility
# bindkey "^[b" backward-word
# bindkey "^[f" forward-word
# bindkey "^A" beginning-of-line
# bindkey "^E" end-of-line
# bindkey "^[[3;3~" kill-word

# -- xterm navigation sequences
bindkey '\e[D' backward-char
bindkey '\e[C' forward-char
bindkey '\e[1;3D' backward-word
bindkey '\e[1;3C' forward-word
bindkey '\e[1;5D' beginning-of-line
bindkey '\e[1;5C' end-of-line
# alt/ctrl delete are handled by terminal emulator


# === ALIASES ===
alias vi="nvim"
alias c="clear"
alias ls="eza --icons"
alias cat="batcat" # ubuntu

# -- tmux --
alias tls='tmux list-sessions'
alias td='tmux detach'

# -- git --
alias gs='git status'
alias gd='git diff'
alias gc='git commit'
alias gu='git pull'
alias gp='git push'

# go to git root
alias cdg='cd $(groot)'
# sexy working tree graph
alias gtree="git log --graph --decorate --all --pretty=format:'%C(auto)%h %C(blue)%ad %Creset)%s %C(green)(%an)%C(reset)' --date=short"
# pipe to clipboard
alias copy='xsel -b'

# === SHELL SCRIPTS ===
# --- tmux pane title updater ---

if [[ -n "$TMUX" ]]; then
  preexec() {
    print -Pn "\033]2;$1 : ${PWD##*/}\007"
  }
  precmd() {
    print -Pn "\033]2;${PWD##*/}\007"
  }
fi

# -- flexible, general purpose, attaching command --
t() {
  local name="$1"
  if [ -n "$TMUX" ]; then
    # Inside tmux
    if [ -n "$name" ]; then
      # Switch or create session by name
      tmux switch-client -t "$name" 2>/dev/null || { tmux new-session -d -s "$name" && tmux switch-client -t "$name"; }
    else
      # No name: switch to most recent
      tmux switch-client -t '!' 2>/dev/null || echo "No previous session to switch to."
    fi
  else
    # Outside tmux
    if [ -n "$name" ]; then
      # Attach or create session by name, preserving PATH
      PATH="$PATH" tmux new -As "$name"
    else
      # No name: fuzzy search
      PATH="$PATH" tmux attach || PATH="$PATH" tmux new -As main
    fi
  fi
}

# -- fzf through sessions
ta() {
  local session
  session=$(tmux ls -F '#S' 2>/dev/null | fzf \
    --height=40% \
    --border \
    --prompt="tmux > " \
    --preview="tmux list-windows -F '#{window_index}: #{window_name}  |  #{pane_current_command}' -t {}" \
    --preview-window=right:55%:wrap
  )
  [[ -n "$session" ]] && tmux attach -t "$session"
}

# --- Get path to git root --- 
groot() { git -C "${1:-.}" rev-parse --show-toplevel 2>/dev/null || return 1 }

# -- eza with arguments tree
l() { eza -T --icons --level=${2:-2}  --group-directories-first --header --long --no-user --no-permissions --modified ${1:-.}}


# -- nnn configuration

export EDITOR=nvim
export NNN_TRASH=1
export NNN_ARCHIVE="\\.(7z|bz2|gz|tar|tgz|zip)$"
export NNN_PLUG='o:fzopen;p:preview-tui;d:diffs;c:fzcd'
export NNN_FIFO=/tmp/nnn.fifo
n ()
{
    # cd to last directory on quit

    # Block nesting of nnn in subshells
    [ "${NNNLVL:-0}" -eq 0 ] || {
        echo "nnn is already running"
        return
    }

    # The behaviour is set to cd on quit (nnn checks if NNN_TMPFILE is set)
    # If NNN_TMPFILE is set to a custom path, it must be exported for nnn to
    # see. To cd on quit only on ^G, remove the "export" and make sure not to
    # use a custom path, i.e. set NNN_TMPFILE *exactly* as follows:
    #      NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"
    export NNN_TMPFILE="${XDG_CONFIG_HOME:-$HOME/.config}/nnn/.lastd"

    # Unmask ^Q (, ^V etc.) (if required, see `stty -a`) to Quit nnn
    # stty start undef
    # stty stop undef
    # stty lwrap undef
    # stty lnext undef

    # The command builtin allows one to alias nnn to n, if desired, without
    # making an infinitely recursive alias
    command nnn -C "$@"

    [ ! -f "$NNN_TMPFILE" ] || {
        . "$NNN_TMPFILE"
        rm -f -- "$NNN_TMPFILE" > /dev/null
    }
}

# PATH setup
export PATH="$HOME/opt/nvim-linux-x86_64/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# bun completions
[ -s "/home/henry/.bun/_bun" ] && source "/home/henry/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# opencode
export PATH=/home/henry/.opencode/bin:$PATH
