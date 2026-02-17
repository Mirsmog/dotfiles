#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# ==============================================
# Locale
# ==============================================
export LANG=C.UTF-8

# ==============================================
# Bash Completion
# ==============================================
if [ -r /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
elif [ -r /etc/bash_completion ]; then
  . /etc/bash_completion
fi

# ==============================================
# FZF (fuzzy finder)
# ==============================================
# Ctrl+R -> interactive history search
# Alt+C  -> cd into a directory
# Ctrl+T -> paste selected file(s)
if [ -r /usr/share/fzf/key-bindings.bash ]; then
  . /usr/share/fzf/key-bindings.bash
fi
if [ -r /usr/share/fzf/completion.bash ]; then
  . /usr/share/fzf/completion.bash
fi

# ==============================================
# History
# ==============================================
# Type prefix, then Up/Down to cycle matching history entries
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'

# ==============================================
# Basic Aliases
# ==============================================
alias cls='clear'
alias vi='nvim'
alias ld='lazydocker'
alias reload='source ~/.bashrc'
alias grep='grep --color=auto'
alias cop='copilot'

# Rovodev
alias rovo='acli rovodev run'
alias rovos='~/scripts/switch-rovodev-account.sh'

# Proxy toggle (WSL specific)
alias px='source ~/.toggle_proxy.sh'

# ==============================================
# Prompt
# ==============================================
# Default PS1 (overridden by Starship if available)
PS1='[\u@\h \W]\$ '

# Starship prompt (modern, fast, customizable)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init bash)"
fi

# ==============================================
# Zoxide (smart cd)
# ==============================================
# `z <query>` to jump, `zi` for interactive selection
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash --cmd z)"
fi

# ==============================================
# Version Managers & Tools
# ==============================================

# NVM (Node Version Manager)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Local bin (uv, pipx, etc.)
export PATH="$HOME/.local/bin:$PATH"

# OpenCode
[ -d "$HOME/.opencode/bin" ] && export PATH="$HOME/.opencode/bin:$PATH"

# ==============================================
# Load Additional Configs
# ==============================================

# Custom aliases (docker, git, pnpm, etc.)
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# Secrets (API keys - NOT in git!)
[ -f ~/.secrets ] && . ~/.secrets

# Local overrides (machine-specific settings)
[ -f ~/.bashrc.local ] && . ~/.bashrc.local

# ==============================================
# Functions
# ==============================================

# Clone repository with fzf (Ctrl+G)
clone-repo() {
    local script="$HOME/scripts/clone-repo.sh"
    [ -f "$script" ] || script="$HOME/clone-repo.sh"  # fallback
    
    if [[ ! -f "$script" ]]; then
        echo "Error: clone-repo.sh not found" >&2
        return 1
    fi
    
    command rm -f /tmp/clone-repo-cd-target
    "$script"
    
    if [[ -f /tmp/clone-repo-cd-target ]]; then
        local target_dir
        target_dir=$(cat /tmp/clone-repo-cd-target)
        command rm -f /tmp/clone-repo-cd-target
        [[ -d "$target_dir" ]] && cd "$target_dir" && echo "Changed to: $(pwd)"
    fi
}
bind -x '"\C-g": clone-repo'

# ==============================================
# Auto-start tmux
# ==============================================
if command -v tmux >/dev/null 2>&1; then
  if [ -z "$TMUX" ]; then
    if tmux has-session -t main 2>/dev/null; then
      exec tmux attach -t main
    else
      exec tmux new -s main
    fi
  fi
fi
. "$HOME/.cargo/env"
