# color and cursor
export COLORTERM=truecolor
echo -ne '\e[5 q' 

# >>> conda initialize >>>
. "$HOME/anaconda3/etc/profile.d/conda.sh"
# <<< conda initialize <<<

# === EVAL ===
eval "$(starship init zsh)"  # prompt
eval "$(direnv hook zsh)" # direnv

# Lazy load NVM
export NVM_DIR="$HOME/.nvm"
nvm_lazy() { unset -f nvm; . "$NVM_DIR/nvm.sh"; nvm "$@"; }
alias nvm=nvm_lazy

# === ZSH COMPLETION ===
fpath+=("/opt/homebrew/share/zsh-completions")
autoload -Uz compinit
compinit -C  # fast init
# compaudit | xargs chmod go-w  # only if necessary once

# === OTHER TOOLS ===
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh #fzf
eval "$(zoxide init zsh)" #zoxide 
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh #autosuggestions
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh #syntax

# -- ghostty zsh compatibility
bindkey "^[b" backward-word
bindkey "^[f" forward-word
bindkey "^A" beginning-of-line
bindkey "^E" end-of-line
bindkey "^[[3;3~" kill-word

# === ALIASES ===
alias vi="nvim"
alias c="clear"
alias ls="eza"
alias grep="rg"
alias cat="bat"

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
l() { eza -T --icons --level=${1:-2} --group-directories-first --header --long --no-user --no-permissions --modified }


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
