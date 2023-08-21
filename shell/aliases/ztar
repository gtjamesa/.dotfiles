#!/bin/bash

ztar() {
  # Encrypt/decrypt single file using encryption level 15
  # zstd -7 yarn.lock
  # zstd -d yarn.lock.zst

  # Encrypt/decrypt directory
  # tar -I 'zstd -7' -cf rr-cache.tar.zst .git/rr-cache
  # tar -I zstd -xf rr-cache.tar.zst

  if [ -z "$1" ] || [ "$1" == "--help" ]; then
    cat << EOF
Usage: $0 [args] <FILE> [FILE(s)]
    -x                   Extract

Compress:
    $ ztar README.md                  Compress README.md to README.md.zst
    $ ztar tmp.tar.zst /tmp           Compress /tmp to tmp.tar.zst
    $ ztar tmp.tar.zst file1 file2    Compress file1 and file2 to tmp.tar.zst

Extract:
    $ ztar -x README.md.zst           Extract README.md.zst to README.md
    $ ztar -x tmp.tar.zst             Extract tmp.tar.zst to /tmp
EOF
    return 1
  fi

  extract=0
  is_dir=0
  filename="$1"
  files=("${@:2}")

  for opt in "$@"; do
    case $opt in
    -x)
      extract=1
      filename="$2"
      ;;
    esac
  done

  # Extract
  if [ "$extract" -eq 1 ]; then
    # Check if its a tar archive
    echo "$filename" | grep '.tar.zst' &> /dev/null
    [ $? -eq 0 ] && is_dir=1

    if [ "$is_dir" -eq 1 ]; then
#      echo tar -I zstd -xf "$filename"
      tar -I zstd -xf "$filename"
    else
#      echo zstd -d "$filename"
      zstd -d "$filename"
    fi

    return 0
  fi

  # Compress
  if [ "$extract" -eq 0 ]; then
    [ -d "$filename" ] && is_dir=1

    # One argument specified
    if [ "$#" -eq 1 ]; then
      # Fail if it is a directory
      if [ "$is_dir" -eq 1 ]; then
        echo "ERR: Please specify output filename";
        echo "Usage: $0 ${1##*/}.tar.zst $1";
        return 1;
      fi

      # Should be a file here so use default behaviour
#      echo zstd -7 "$filename"
      zstd -7 "$filename"
      return 0
    fi

    # Compress multiple files into a tar archive
#    echo tar -I 'zstd -7' -cf "$filename" "${files[@]}"
    tar -I 'zstd -7' -cf "$filename" "${files[@]}"
  fi
}
