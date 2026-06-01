#!/bin/bash

# WSL-specific helpers. Enable with: dotmod enable wsl

# Perforce p4merge — Windows binary, accessed from WSL
export P4MERGE_BINARY="/mnt/c/Program Files/Perforce/p4merge.exe"
export P4MERGE_PREPEND=""
export P4MERGE_APPEND=""

xdebug-forward() {
  wsl2=0

  # Detect WSL 2
  [ -f /proc/sys/fs/binfmt_misc/WSLInterop ] && wsl2=1
  grep -qi Microsoft /proc/version && wsl2=1
  grep -qi Microsoft /proc/sys/kernel/osrelease && wsl2=1

  if [ "$wsl2" -eq 0 ]; then
    echo 'Error: Not running inside WSL 2.' >&2
    return 1
  fi

  if [ ! -x "$(command -v socat)" ]; then
    echo 'Error: socat is not installed.' >&2
    return 1
  fi

  HOST_IP=$(cat /etc/resolv.conf | tail -n1 | cut -d " " -f 2)
  PORT=${1:-9003}

  echo "Forwarding port ${PORT} to ${HOST_IP}:${PORT}..."
  socat "tcp-listen:${PORT},reuseaddr,fork" "tcp:${HOST_IP}:${PORT}"
}

wsl-backup() {
  if [[ -z "$1" ]]; then
    echo "Usage: wsl-backup <destination>"
    return 1
  fi

  DEST="$1"
  FILE_PATH="$DEST/wsl-backup-$(date +%Y%m%d).tar.gz"

  tar -cvzf "$FILE_PATH" "$HOME"
}

git-setup-p4merge() {
  git config --global diff.tool p4merge
  git config --global merge.tool p4merge
  git config --global difftool.p4merge.cmd '/mnt/c/Program\ Files/Perforce/p4merge.exe "$(wslpath -aw $LOCAL)" "$(wslpath -aw $REMOTE)"'
  git config --global mergetool.p4merge.cmd '/mnt/c/Program\ Files/Perforce/p4merge.exe "$(wslpath -aw $BASE)" "$(wslpath -aw $LOCAL)" "$(wslpath -aw $REMOTE)" "$(wslpath -aw $MERGED)"'
  git config --global mergetool.p4merge.trustexitcode false
}
