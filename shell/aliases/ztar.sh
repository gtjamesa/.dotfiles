#!/bin/bash

ztar() {
  # Encrypt/decrypt single file using encryption level 15
  # zstd -7 yarn.lock
  # zstd -d yarn.lock.zst

  # Encrypt/decrypt directory
  # tar -I 'zstd -7' -cf rr-cache.tar.zst .git/rr-cache
  # tar -I zstd -xf rr-cache.tar.zst

  if [ -z "$1" ] || [ "$1" = "--help" ]; then
    cat << EOF
Usage: $0 [args] <FILE> [FILE(s)]
    -x                   Extract
    --rm                 Remove source file(s) after successful compression

Compress:
    $ ztar README.md                  Compress README.md to README.md.zst
    $ ztar tmp.tar.zst /tmp           Compress /tmp to tmp.tar.zst
    $ ztar tmp.tar.zst file1 file2    Compress file1 and file2 to tmp.tar.zst
    $ ztar --rm README.md             Compress, then delete README.md

Extract:
    $ ztar -x README.md.zst           Extract README.md.zst to README.md
    $ ztar -x tmp.tar.zst             Extract tmp.tar.zst to /tmp
EOF
    return 1
  fi

  extract=0
  is_dir=0
  remove=0

  # Strip leading flags so $1/$# refer to the filename and its sources
  while [ "$#" -gt 0 ]; do
    case "$1" in
    -x)
      extract=1
      shift
      ;;
    --rm)
      remove=1
      shift
      ;;
    *)
      break
      ;;
    esac
  done

  filename="$1"
  files=("${@:2}")

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
      # zstd's own --rm only unlinks on success
      if [ "$remove" -eq 1 ]; then
#        echo zstd -7 --rm "$filename"
        zstd -7 --rm "$filename"
      else
#        echo zstd -7 "$filename"
        zstd -7 "$filename"
      fi
      return $?
    fi

    # Compress multiple files into a tar archive
#    echo tar -I 'zstd -7' -cf "$filename" "${files[@]}"
    tar -I 'zstd -7' -cf "$filename" "${files[@]}" || return $?

    if [ "$remove" -eq 1 ]; then
      rm -rf "${files[@]}"
    fi
  fi
}
