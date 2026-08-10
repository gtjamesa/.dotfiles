#!/bin/bash

# Video clip/concat + GIF frame split/rebuild. Enable with: dotmod enable media
#
#   fclip   <src> <dst> <start> <end>   trim a section
#   fconcat <dst> <src>...              join clips
#   ffps    <file.gif>                  report the true frame rate
#   fsplit  <file> [workdir]            -> frames/ (source PNGs) + out/ (render target)
#   fgif    [--mp4] [output] [workdir]  rebuild from out/, or frames/ if out/ is empty

# Clip a section of a video using ffmpeg
fclip() {
  if [ -z "$4" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: fclip <src-file> <dst-file> <start-timestamp> <end-timestamp>"
    return 1
  fi

  ffmpeg -ss "$3" -to "$4" -i "$1" -async 1 "$2"
}

fconcat() {
  if [ -z "$3" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
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

# Print "<fpsarg> <fps> <kind>" for a GIF; fpsarg is what ffmpeg -framerate wants.
#
# A GIF stores each delay as a WHOLE centisecond, so any rate that doesn't divide
# 100 lands as a repeating pattern (15fps -> 7 6 7 7 6 7 ...). That's rounding,
# not variable timing — and it's why ffprobe's avg_frame_rate lies (50/3 on a
# 15fps file). Recover the real rate by testing candidates: re-derive the delays
# each would produce, keep the one that reproduces the file exactly.
_media_fps() {
  # GIFs only — magick happily reports %T for a video too, rounding 1/30s to a
  # 3cs delay and claiming 33.333fps. Callers fall back to the container rate.
  [ "$(ffprobe -v error -select_streams v:0 -show_entries stream=codec_name \
    -of default=nw=1:nk=1 "$1" 2>/dev/null)" = gif ] || return 1

  magick identify -format '%T\n' "$1" 2>/dev/null | awk '
    function fmt(x,   s) { s = sprintf("%.3f", x); sub(/0+$/, "", s); sub(/\.$/, "", s); return s }
    function gcd(a, b,   t) { while (b) { t = b; b = a % b; a = t } return a }
    /^[0-9]+$/ { d[++n] = $1; total += $1 }
    END {
      if (!n || !total) exit 1

      same = 1
      for (i = 2; i <= n; i++) if (d[i] != d[1]) { same = 0; break }
      if (same) {                                   # one delay -> exact rational
        g = gcd(100, d[1]); num = 100 / g; den = d[1] / g
        print (den == 1 ? num "" : num "/" den), fmt(100.0 / d[1]), "constant"
        exit
      }

      raw = n * 100.0 / total
      for (c = int(raw) - 1; c <= int(raw) + 2; c++) {
        if (c < 1) continue
        ok = 1; prev = 0
        for (i = 1; i <= n; i++) {
          cum = int(i * 100.0 / c + 0.5)            # ideal cumulative cs, rounded
          if (cum - prev != d[i]) { ok = 0; break }
          prev = cum
        }
        if (ok) { print c, c, "quantised"; exit }
      }

      print fmt(raw), fmt(raw), "variable"
    }'
}

# Keep rationals internally — they're what -framerate wants, and the only exact
# spelling of 30000/1001 — but every displayed rate gets decimalised, because
# that number is typed by hand into Natron's frame rate field.
_media_dec() {
  awk -F/ '{ s = sprintf("%.3f", NF > 1 ? $1 / $2 : $1)
             sub(/0+$/, "", s); sub(/\.$/, "", s); print s }' <<< "$1"
}

# Count *.png — not `ls | wc -l`, which lists the cwd when the glob matches nothing
_media_count() {
  local f n=0
  [ -n "${ZSH_VERSION:-}" ] && setopt local_options null_glob
  for f in "$1"/*.png; do [ -f "$f" ] && n=$((n + 1)); done
  printf '%s\n' "$n"
}

# Colourise unless piped/NO_COLOR: _media_out <colour> <headline> <detail>
_media_out() {
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    printf '%b%s%b %b%s%b\n' "$1" "$2" "$COLOR_RESET" "$COLOR_LIGHT_GREY" "$3" "$COLOR_RESET"
  else
    printf '%s %s\n' "$2" "$3"
  fi
}

ffps() {
  local fpsarg fps kind

  if [ -z "$1" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    cat <<'EOF'
Usage: ffps <file.gif>

  Report the true frame rate, resolving the whole-centisecond delay rounding
  that makes ffprobe's avg_frame_rate wrong (50/3 on a 15fps file).
EOF
    return 1
  fi

  [ -f "$1" ] || { echo "ffps: no such file: $1" >&2; return 1; }

  read -r fpsarg fps kind <<< "$(_media_fps "$1")"
  [ -n "$fpsarg" ] || { echo "ffps: no GIF frame delays in $1" >&2; return 1; }

  [ "$kind" = variable ] \
    && _media_out "$COLOR_YELLOW" "~$fps fps" "variable — rebuild uses the original delays" \
    || _media_out "$COLOR_GREEN" "$fps fps" "$kind · -framerate $fpsarg · $(magick identify -format '%T ' "$1" | cut -c1-32)…"
}

# Split into PNG frames + record the timing so fgif can rebuild it exactly
fsplit() {
  local file="$1" wd="${2:-.}" fpsarg fps kind n

  if [ -z "$1" ] || [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    cat <<'EOF'
Usage: fsplit <src-file> [workdir]

  Extract PNG frames to <workdir>/frames and create <workdir>/out for the comp
  to render into. Records the detected fps so fgif needs no arguments.

  workdir   defaults to the current directory
EOF
    return 1
  fi

  [ -f "$file" ] || { echo "fsplit: no such file: $file" >&2; return 1; }
  [ -n "${ZSH_VERSION:-}" ] && setopt local_options null_glob

  mkdir -p "$wd/frames" "$wd/out" || return 1
  rm -f "$wd"/frames/*.png

  # passthrough keeps one PNG per source frame — no dupes, no drops
  ffmpeg -loglevel error -y -i "$file" -fps_mode passthrough "$wd/frames/f_%04d.png" || return 1

  read -r fpsarg fps kind <<< "$(_media_fps "$file")"
  [ -n "$fpsarg" ] || { fpsarg=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=r_frame_rate -of default=nw=1:nk=1 "$file")
    fps=$(_media_dec "$fpsarg") kind=container; }
  n=$(_media_count "$wd/frames")

  printf 'fpsarg=%s\nkind=%s\n' "$fpsarg" "$kind" > "$wd/.media-timing"
  if [ "$kind" = variable ]; then
    magick identify -format '%T\n' "$file" > "$wd/.media-delays"
  else
    rm -f "$wd/.media-delays"   # don't leave a previous source's delays behind
  fi

  _media_out "$COLOR_GREEN" "$n frames" "-> $wd/frames · $fps fps ($kind) · render to $wd/out · then: fgif"
}

# Rebuild a GIF (or MP4) from rendered frames at the recorded rate
fgif() {
  local mp4=0 vfr=0 out wd src fpsarg kind n i d f list abs

  [ "$1" = "--mp4" ] && { mp4=1; shift; }

  if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    cat <<'EOF'
Usage: fgif [--mp4] [output] [workdir]

  Rebuild at the rate fsplit recorded, reading <workdir>/out — or
  <workdir>/frames if out/ is empty. Falls back to the source's own per-frame
  delays automatically when the source was genuinely variable.

  --mp4     write H.264 instead of a GIF; implied by an .mp4 output name
  output    defaults to final.gif, or final.mp4 with --mp4; written relative
            to the CWD, not workdir
  workdir   defaults to the current directory
EOF
    return 1
  fi

  [ "$mp4" = 1 ] && out="${1:-final.mp4}" || out="${1:-final.gif}"
  wd="${2:-.}"
  case "$out" in *.mp4) mp4=1 ;; esac

  [ -n "${ZSH_VERSION:-}" ] && setopt local_options null_glob

  [ "$(_media_count "$wd/out")" -gt 0 ] && src="$wd/out" || src="$wd/frames"
  n=$(_media_count "$src")
  [ "$n" -gt 0 ] || { echo "fgif: no PNGs in $src — run fsplit first" >&2; return 1; }

  fpsarg=$(sed -n 's/^fpsarg=//p' "$wd/.media-timing" 2>/dev/null)
  kind=$(sed -n 's/^kind=//p' "$wd/.media-timing" 2>/dev/null)
  [ -n "$fpsarg" ] || { fpsarg=15 kind="assumed"; }

  # String compare, not -eq: a missing delays file yields "" and would error out
  [ "$kind" = variable ] \
    && [ "$(grep -c . "$wd/.media-delays" 2>/dev/null)" = "$n" ] && vfr=1

  if [ "$mp4" = 1 ]; then
    # trunc: libx264 refuses odd dimensions under yuv420p
    set -- -c:v libx264 -crf 18 -pix_fmt yuv420p \
      -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -movflags +faststart "$out"

    if [ "$vfr" = 1 ]; then
      # Video has no -delay, so feed a concat list of per-frame durations. The
      # trailing repeat is what gives the final frame its duration rather than
      # 1ms. `option framerate 1000` is load-bearing on every entry: without it
      # concat rounds durations to the image demuxer's 1/25 default (7 6 12 ->
      # 8 4 12) and drops that repeat. -safe 0 resolves relative paths against
      # the list file's own directory, hence the absolute ones.
      list=$(mktemp) || return 1
      i=1
      for f in "$src"/*.png; do
        case "$f" in /*) abs="$f" ;; *) abs="$PWD/$f" ;; esac
        d=$(sed -n "${i}p" "$wd/.media-delays")
        printf "file '%s'\noption framerate 1000\nduration %d.%02d\n" \
          "$abs" "$((d / 100))" "$((d % 100))"
        i=$((i + 1))
      done > "$list"
      printf "file '%s'\noption framerate 1000\n" "$abs" >> "$list"

      ffmpeg -loglevel error -y -f concat -safe 0 -i "$list" -fps_mode vfr "$@" \
        || { rm -f "$list"; return 1; }
      rm -f "$list"
    else
      ffmpeg -loglevel error -y -framerate "$fpsarg" -pattern_type glob -i "$src/*.png" "$@" \
        || return 1
    fi
  elif [ "$vfr" = 1 ]; then
    # Positional params instead of an array — bash and zsh index arrays differently
    set --
    i=1
    for f in "$src"/*.png; do
      set -- "$@" -delay "$(sed -n "${i}p" "$wd/.media-delays")" "$f"
      i=$((i + 1))
    done
    magick "$@" -loop 0 -layers OptimizePlus "$out" || return 1
  else
    # stats_mode=diff weights the palette toward what actually moves — stops
    # gradients banding once you're down to 256 colours
    ffmpeg -loglevel error -y -framerate "$fpsarg" -pattern_type glob -i "$src/*.png" \
      -filter_complex "split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer" \
      -loop 0 "$out" || return 1
  fi

  _media_out "$COLOR_GREEN" "$out" \
    "<- $src · $n frames · $(_media_dec "$fpsarg") fps ($kind) · $(du -h "$out" | cut -f1)"
}
