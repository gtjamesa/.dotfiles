#!/bin/bash

# Video clip/concat via ffmpeg. Enable with: dotmod enable media

# Clip a section of a video using ffmpeg
fclip() {
  if ! command -v ffmpeg &>/dev/null; then
    echo "ffmpeg not installed"
    return 1
  fi

  if [ -z "$4" ]; then
    echo "Usage: fclip <src-file> <dst-file> <start-timestamp> <end-timestamp>"
    return 1
  fi

  ffmpeg -ss "$3" -to "$4" -i "$1" -async 1 "$2"
}

fconcat() {
  if ! command -v ffmpeg &>/dev/null; then
    echo "ffmpeg not installed"
    return 1
  fi

  if [ -z "$3" ]; then
    echo "Usage: fconcat <dst-file> <src-file1 [src-file2 src-file3]...>"
    return 1
  fi

  TMPFILE=$(mktemp)
  DST_PATH="$1"

  for opt in "$@"; do
    # if arg is the same as first argument, skip
    if [ "$opt" != "$DST_PATH" ]; then
      BASE_DIR="$opt"

      # Prepend `pwd` if BASE_DIR is a relative path
      if [[ "$BASE_DIR" != /* ]]; then
        BASE_DIR="$(pwd)/${BASE_DIR}"
      fi

      echo "file '${BASE_DIR}'" >> "${TMPFILE}"
    fi
  done

  ffmpeg -safe 0 -f concat -i "${TMPFILE}" -c copy "${DST_PATH}"

  rm -f "${TMPFILE}"
}
