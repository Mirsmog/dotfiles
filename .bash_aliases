#!/bin/bash

# ==============================================
# Quality of life (navigation, ls)
# ==============================================

# Safer defaults
alias cp='cp -i'
alias mv='mv -i'

# Safe delete: move to Trash instead of permanent removal
rrm() { command rm "$@"; }
rm() {
  if command -v gio >/dev/null 2>&1; then
    local args=()
    for a in "$@"; do
      case "$a" in
        -*) ;; # ignore rm flags
        *) args+=("$a") ;;
      esac
    done

    if [ ${#args[@]} -eq 0 ]; then
      echo "rm: missing operand" >&2
      return 1
    fi

    local failed=0
    for a in "${args[@]}"; do
      gio trash -- "$a" || failed=1
    done
    return $failed
  else
    command rm -i "$@"
  fi
}

# Quick navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ~='cd ~'
alias c='clear'

# Pretty ls (prefer eza/exa, fallback to GNU ls)
if command -v eza >/dev/null 2>&1; then
  alias ls='eza -F --group-directories-first --icons'
  alias la='eza -a -F --group-directories-first --icons'
  alias ll='eza -lah -F --group-directories-first --icons --git'
  alias lt='eza -T -L 2 -F --group-directories-first --icons'
  alias lta='eza -aT -L 2 -F --group-directories-first --icons'
  alias l1='eza -1 -F --group-directories-first --icons'
elif command -v exa >/dev/null 2>&1; then
  alias ls='exa -F --group-directories-first --icons'
  alias la='exa -a -F --group-directories-first --icons'
  alias ll='exa -lah -F --group-directories-first --icons --git'
  alias lt='exa -T -L 2 -F --group-directories-first --icons'
  alias lta='exa -aT -L 2 -F --group-directories-first --icons'
  alias l1='exa -1 -F --group-directories-first --icons'
else
  alias ls='ls --color=auto -F'
  alias la='ls --color=auto -AF'
  alias ll='ls --color=auto -alFh'
  alias lt='ls --color=auto -alFh'
fi

# Grep with color
alias grep='grep --color=auto'

# ==============================================
# Docker
# ==============================================

alias d='docker'
alias di='docker images'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias drm='docker rm'
alias drmi='docker rmi'
alias dexec='docker exec -it'
alias dlogs='docker logs'
alias dlogsf='docker logs -f'
alias dinspect='docker inspect'
alias dstats='docker stats'
alias dsa='docker stop $(docker ps -q)'
alias dca='docker rm -f $(docker ps -aq)'
alias dsr='docker stop $(docker ps -q) && docker rm $(docker ps -aq)'
alias drma='docker rm -f $(docker ps -aq)'
alias drmia='docker rmi -f $(docker images -q)'
alias drmid='docker rmi $(docker images -f "dangling=true" -q)'
alias ddu='docker system df'

# Docker functions
denter() { docker exec -it "$1" /bin/bash; }
dentersh() { docker exec -it "$1" /bin/sh; }

# ==============================================
# Docker Compose
# ==============================================

alias dc='docker-compose'
alias dcu='docker-compose up'
alias dcud='docker-compose up -d'
alias dcd='docker-compose down'
alias dcb='docker-compose build'
alias dcr='docker-compose restart'
alias dcs='docker-compose stop'
alias dcl='docker-compose logs'
alias dclf='docker-compose logs -f'
alias dcps='docker-compose ps'
alias dcexec='docker-compose exec'

# Docker Compose v2
alias dkc='docker compose'
alias dkcu='docker compose up'
alias dkcud='docker compose up -d'
alias dkcd='docker compose down'
alias dkcb='docker compose build'
alias dkcr='docker compose restart'
alias dkcs='docker compose stop'
alias dkcl='docker compose logs'
alias dkclf='docker compose logs -f'
alias dkcps='docker compose ps'
alias dkcexec='docker compose exec'

# ==============================================
# Git
# ==============================================

alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add .'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gp='git push'
alias gpl='git pull'
alias gf='git fetch'
alias gb='git branch'
alias gba='git branch -a'
alias gbd='git branch -d'
alias gco='git checkout'
alias gcob='git checkout -b'
alias gm='git merge'
alias gr='git rebase'
alias gri='git rebase -i'
alias gl='git log'
alias glo='git log --oneline'
alias glg='git log --graph --oneline --decorate --all'
alias gd='git diff'
alias gds='git diff --staged'
alias gst='git stash'
alias gstp='git stash pop'
alias gstl='git stash list'
alias greset='git reset'
alias gclean='git clean -fd'

# Git functions
gcp() {
    git add .
    git commit -m "$1"
    git push
}

gcnb() {
    git checkout -b "$1"
}

# ==============================================
# pnpm
# ==============================================

alias p='pnpm'
alias pi='pnpm install'
alias pa='pnpm add'
alias pad='pnpm add -D'
alias pr='pnpm remove'
alias pup='pnpm update'
alias prun='pnpm run'
alias pdev='pnpm run dev'
alias pbuild='pnpm run build'
alias ptest='pnpm run test'
alias pstart='pnpm run start'
alias plint='pnpm run lint'
alias plist='pnpm list'
alias ppub='pnpm publish'

# ==============================================
# Bun
# ==============================================

alias b='bun'
alias bi='bun install'
alias ba='bun add'
alias bad='bun add -d'
alias br='bun remove'
alias bup='bun update'
alias brun='bun run'
alias bdev='bun run dev'
alias bbuild='bun run build'
alias btest='bun test'
alias bstart='bun run start'
alias blint='bun run lint'
alias bx='bunx'

# ==============================================
# npm / Node.js
# ==============================================

alias n='node'
alias ni='npm install'
alias nis='npm install --save'
alias nid='npm install --save-dev'
alias nun='npm uninstall'
alias nup='npm update'
alias nrun='npm run'
alias ndev='npm run dev'
alias nbuild='npm run build'
alias ntest='npm test'
alias nstart='npm start'
alias nlint='npm run lint'
alias nlist='npm list'
alias npub='npm publish'
