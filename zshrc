# Auto-attach to tmux 'main' on interactive SSH login.
if [[ -z "$TMUX" && -n "$SSH_CONNECTION" && $- == *i* ]] && command -v tmux >/dev/null; then
  exec tmux new-session -A -s main
fi

export PATH="$HOME/.local/bin:$PATH"

[[ -f $HOME/.zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh ]] && \
  source $HOME/.zsh/zsh-vi-mode/zsh-vi-mode.plugin.zsh

eval "$(mise activate zsh)"
eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ls='eza -lh --group-directories-first --icons=auto'
alias lsa='ls -a'
alias lt='eza --tree --level=2 --long --icons --git'
alias lta='lt -a'
alias ff="fzf --preview 'bat --style=numbers --color=always {}'"
alias cd="zd"

zd() {
  if [ $# -eq 0 ]; then
    builtin cd ~ && return
  elif [ -d "$1" ]; then
    builtin cd "$1"
  else
    z "$@" && printf "\U000F17A9 " && pwd || echo "Error: Directory not found"
  fi
}

# Expose a local port over Tailscale at https://<vm>.<ts-net>.ts.net/
# Usage: serve-me 3000
serve-me() {
  if [ -z "${1:-}" ]; then
    echo "usage: serve-me <port>" >&2
    return 1
  fi
  tailscale serve --bg "http://localhost:$1"
}
