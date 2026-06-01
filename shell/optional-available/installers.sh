#!/bin/bash

install-ueli() { _install_appimage oliverschwendener/ueli ueli "$@"; }
install-ueli-prerelease() { _install_appimage oliverschwendener/ueli ueli --prerelease "$@"; }
install-bruno() { _install_appimage usebruno/bruno bruno "$@"; }

_install_appimage() {
  local repo="$1" name="$2"; shift 2
  local dest="/opt/apps/$name.AppImage" prerelease=""
  for arg in "$@"; do
    case "$arg" in
      --prerelease) prerelease="--prerelease" ;;
      --autostart) ;;
      *) echo "Unknown option: $arg" >&2; return 1 ;;
    esac
  done
  _dl_setex "$(_github_release_url "$repo" AppImage $prerelease)" "$dest" || return 1
  _extract_appimage_icon "$name" "$dest"
  _add_desktop_entry "$name" "$dest"
  [[ " $* " == *" --autostart "* ]] && _add_autostart "$name" "$dest"
}

_dl_setex() {
  local tmpfile
  tmpfile=$(mktemp)
  echo "Downloading $1 to $2..."
  wget -q --show-progress -O "$tmpfile" "$1" || { rm -f "$tmpfile"; echo "Download failed" >&2; return 1; }
  chmod +x "$tmpfile"
  mv -f "$tmpfile" "$2"
}

_github_release_url() {
  local repo="$1" match="$2" flags="$3"
  if [ -z "$repo" ] || [ -z "$match" ]; then
    echo "Usage: _github_release_url owner/repo match_string [--prerelease]" >&2
    return 1
  fi
  local api_url="https://api.github.com/repos/$repo/releases"
  local jq_prefix
  if [ "$flags" = "--prerelease" ]; then
    jq_prefix='map(select(.prerelease and (.draft | not))) | .[0].assets'
  else
    api_url="$api_url/latest"
    jq_prefix='.assets'
  fi
  local url
  url=$(curl -s "$api_url" | jq -r --arg m "$match" \
    "$jq_prefix | map(select(.browser_download_url | contains(\$m) and (contains(\"arm64\") or contains(\"aarch64\") | not))) | .[0].browser_download_url")
  if [ -z "$url" ] || [ "$url" = "null" ]; then
    echo "Error: could not resolve download URL for $repo ($match)" >&2
    return 1
  fi
  echo "$url"
}

_extract_appimage_icon() {
  local name="$1" appimage="$2"
  local icon_dir="$HOME/.local/share/icons" tmpdir
  tmpdir=$(mktemp -d)
  cd "$tmpdir" || return 1
  "$appimage" --appimage-extract "*.png" --appimage-extract "*.svg" >/dev/null 2>&1
  local icon
  icon=$(find squashfs-root -maxdepth 1 -name "*.png" -o -name "*.svg" 2>/dev/null | head -1)
  if [ -z "$icon" ]; then
    icon=$(find squashfs-root -name "*.png" -o -name "*.svg" 2>/dev/null | head -1)
  fi
  if [ -n "$icon" ]; then
    local ext="${icon##*.}"
    mkdir -p "$icon_dir"
    cp "$icon" "$icon_dir/$name.$ext"
    echo "Extracted icon: $icon_dir/$name.$ext"
  else
    echo "No icon found in AppImage" >&2
  fi
  rm -rf "$tmpdir"
  cd - >/dev/null
}

_add_desktop_entry() {
  local name="$1" exec_path="$2"
  local desktop_file="$HOME/.local/share/applications/$name.desktop"
  if grep -qF "Exec=$exec_path" "$desktop_file" 2>/dev/null; then
    return 0
  fi
  mkdir -p "$HOME/.local/share/applications"
  cat <<EOF > "$desktop_file"
[Desktop Entry]
Type=Application
Name=$name
Exec=$exec_path
Icon=$name
Terminal=false
Categories=Utility;
EOF
  echo "Added menu entry: $desktop_file"
}

_add_autostart() {
  local name="$1" exec_path="$2"
  local desktop_file="$HOME/.config/autostart/$name.desktop"
  if grep -qF "Exec=$exec_path" "$desktop_file" 2>/dev/null; then
    echo "Autostart already exists: $desktop_file"
    return 0
  fi
  mkdir -p "$HOME/.config/autostart"
  cat <<EOF > "$desktop_file"
[Desktop Entry]
Type=Application
Exec=$exec_path
X-GNOME-Autostart-enabled=true
NoDisplay=false
Hidden=false
Name=$name
X-GNOME-Autostart-Delay=10
EOF
  echo "Added autostart: $desktop_file"
}
