#!/bin/bash

# Desktop-only helpers (NAS mount, GPU, games, GIMP) — Linux desktop only.
# Enable with: dotmod enable desktop-aliases

mount-synology() {
  if [ "$1" == "--help" ]; then
    echo "Usage: $0 [mount] [path]"
    echo
    echo "mount\t - Mount path (default: home)"
    echo "path\t - Destination path (default: /mnt/synology)"
    echo -e "\nExample: $0 home /mnt/synology"
    return 0
  fi

  CREDS_PATH="$HOME/.synologycredentials"

  # Set MOUNT_PATH to $1 if it's not empty, otherwise use "/home"
  MOUNT_PATH="/${1:-home}"
  DST_PATH="${2:-/mnt/synology}"

  if [ ! -f "$CREDS_PATH" ]; then
    echo "username=USERNAME" > "$CREDS_PATH" && echo "password=PASSWORD" >> "$CREDS_PATH"
    echo "Please enter credentials at $CREDS_PATH"
    chmod 0600 "$CREDS_PATH"
    return 0
  fi

  [ ! -d "${DST_PATH}" ] && sudo mkdir -p "${DST_PATH}"
  sudo mount -t cifs "//192.168.0.100${MOUNT_PATH}" "${DST_PATH}" -o "uid=1000,credentials=$HOME/.synologycredentials,rw,nodfs,vers=3.0"
}

umount-synology() {
  MOUNT_PATH="${1:-/mnt/synology}"
  sudo umount "$MOUNT_PATH"
}

nvidia-flatpak-update() {
  VERSION_FILE=/proc/driver/nvidia/version

  if [ ! -f "${VERSION_FILE}" ]; then
    echo "Nvidia driver not found (${VERSION_FILE})"
    return 1
  fi

  DRIVER_VERSION=$(awk '{print $8}' "${VERSION_FILE}" | head -1)
  FLATPAK_VERSION="${DRIVER_VERSION//./-}"

  echo -e "Installing flatpak drivers for version ${COLOR_GREEN}${DRIVER_VERSION}${COLOR_RESET}\n"

  flatpak install --user flathub "org.freedesktop.Platform.GL.nvidia-${FLATPAK_VERSION}/x86_64" "org.freedesktop.Platform.GL32.nvidia-${FLATPAK_VERSION}/x86_64"
}

runelite-flatpak-link() {
  BASE_DIR="$HOME/.var/app/com.adamcake.Bolt/data/bolt-launcher"
  SCREENSHOT_DIR=""

  if [ ! -d "$BASE_DIR" ]; then
    echo -e "Bolt launcher directory not found: $BASE_DIR\n"
    echo "Install: ${COLOR_BLUE}flatpak install --user -y flathub com.adamcake.Bolt${COLOR_RESET}"
    return 1
  fi

  CURRENT_LINK=$(readlink -f "$HOME/.runelite")
  if [ "$CURRENT_LINK" == "$BASE_DIR/.runelite" ]; then
    echo "Runelite link already set to Bolt launcher directory"
    return 0
  fi

  # Check if screenshots directory is a symlink
  if [ -L "$HOME/.runelite/screenshots" ]; then
    SCREENSHOT_DIR=$(readlink -f "$HOME/.runelite/screenshots")
  fi

  if [ -d "$HOME/.runelite" ] && [ ! -L "$HOME/.runelite" ]; then
    BACKUP_DIR=".runelite-$(date +%Y%m%d).bak"
    echo "Backing up existing .runelite directory to $HOME/$BACKUP_DIR"
    mv "$HOME/.runelite" "$HOME/$BACKUP_DIR"
  fi

  # Link directories
  ln -s "$BASE_DIR/.runelite" "$HOME/.runelite"

  # Re-link screenshots directory if it was a symlink
  if [ -n "$SCREENSHOT_DIR" ]; then
    mv "$HOME/.runelite/screenshots" "$HOME/.runelite/screenshots.bak"
    rm -rf "$HOME/.runelite/screenshots"
    ln -s "$SCREENSHOT_DIR" "$HOME/.runelite/screenshots"
  fi

  echo ""
  echo "Add 'xdg-pictures/RuneLite:create' filesystem permission in Flatseal for Bolt launcher to access screenshots"
}

runelite-flatpak-update() {
  BASE_DIR="$HOME/.local/share/flatpak/runtime/com.jagex.Launcher.ThirdParty.RuneLite/x86_64/stable/active/files"
  BINARY_PATH="$BASE_DIR/RuneLite.exe"
  BACKUP_PATH="$BASE_DIR/RuneLite-$(date +%Y%m%d).exe.bak"
  update_nvidia=0

  for opt in "$@"; do
    case $opt in
      --help)
        echo "Usage: $0 [update]"
        echo
        echo "--nvidia\t - Update runelite"
        echo -e "\nExample: $0 update"
        return 0
        ;;
      --nvidia)
        update_nvidia=1
        ;;
    esac
  done

  if [ ! -f "$BINARY_PATH" ]; then
    echo "Runelite not installed"
    return 1
  fi

  if [ "$update_nvidia" -eq 1 ]; then
    nvidia-flatpak-update
  fi

  # Backup the existing file
  cp "$BINARY_PATH" "$BACKUP_PATH"

  # Download the latest version
  flatpak update -y com.jagex.Launcher com.jagex.Launcher.ThirdParty.RuneLite

  # Merge the changes
  PATCH_FILE=$(mktemp)
  diff "$BINARY_PATH" "$BACKUP_PATH" > "$PATCH_FILE"
  patch -b "$BINARY_PATH" < "$PATCH_FILE"
  rm -f "$PATCH_FILE"
}

install-gimp-ps-shortcuts() {
  GIMP_DIR="$HOME/.config/GIMP/3.0"
  BASE_URL="https://github.com/loloolooo/photoshop-keymap-for-gimp/raw/refs/heads/3.x"

  if [ ! -d "$GIMP_DIR" ]; then
    echo "GIMP config directory not found: $GIMP_DIR"
    return 1
  fi

  backup_file "$GIMP_DIR/controllerrc"
  backup_file "$GIMP_DIR/shortcutsrc"

  wget -O "$GIMP_DIR/controllerrc" "${BASE_URL}/controllerrc"
  wget -O "$GIMP_DIR/shortcutsrc" "${BASE_URL}/shortcutsrc"
}
