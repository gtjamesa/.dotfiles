#!/bin/bash

# Flush zsh completion cache and reload shell (run after brew install/upgrade
# to pick up newly-installed _foo completion files).
alias zcompflush='rm -f ~/.cache/zcompdump && exec zsh'
