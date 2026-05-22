#!/bin/bash

alias prettyjson='python -m json.tool'

function mdc() {
  mkdir -p "$1" && cd "$1"
}

fileinfo() {
  local FILESIZE
  local HASH
  FILESIZE=$(stat --printf="%s" "$1")
  HASH=$(sha256sum "$1" | awk -F' ' '{print $1}')
  echo "$1"
  echo "Filesize: ${FILESIZE}"
  echo -e "SHA256: ${HASH}\n"
}

rand-str() {
  LENGTH=16
  [ -n "$1" ] && LENGTH="$1"
  tr -dc A-Za-z0-9 </dev/urandom | head -c "$LENGTH"; echo
}
