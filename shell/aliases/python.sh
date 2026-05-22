#!/bin/bash

# Start and source a Python VirtualEnv
# venv - loads Python 3 by default
# venv 3 - loads Python 3
# venv 2/2.7 - loads Python 2.7
venv() {
  # Source the venv if it already exists
  if [[ -f "./venv/bin/activate" ]]; then
      source venv/bin/activate
      return
  fi

  PYVER=3

  # Set version
  if [[ -n "$1" ]]; then
    PYVER="$1"
  fi

  if [[ "$PYVER" == "2" ]]; then
    PYVER="2.7"
  fi

  virtualenv -p "/usr/bin/python$PYVER" venv
  source venv/bin/activate
}
