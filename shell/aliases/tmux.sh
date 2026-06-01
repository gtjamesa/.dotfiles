#!/bin/bash

# Attach tmux to current working directory
tmux-cwd() {
  tmux command-prompt -I "$PWD" -p "New session dir:" "attach -c %1"
}
