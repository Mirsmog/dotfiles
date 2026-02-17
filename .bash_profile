#
# ~/.bash_profile
#

# Locale
export LANG=C.UTF-8

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Load .bashrc for interactive shells
[[ -f ~/.bashrc ]] && . ~/.bashrc
