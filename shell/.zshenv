# ~/.zshenv — sourced for EVERY shell: interactive, non-interactive, login,
# non-login, and GUI / Xcode build phases. Keep it minimal and fast (it runs
# for every script subshell): env vars + PATH only, no slow tool init.

typeset -U path PATH
[ -f ~/.dotfiles/shell/exports ] && source ~/.dotfiles/shell/exports
