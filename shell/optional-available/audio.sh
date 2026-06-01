#!/bin/bash

link-easyeffects() {
  CONF_DIR="$HOME/.var/app/com.github.wwmm.easyeffects/config/easyeffects"

  # Skip if the flatpak config has already been symlinked
  if [ -L "$CONF_DIR" ]; then
    return 0
  fi

  # Backup the existing config and symlink the new one
  if [ -d "$CONF_DIR" ]; then
    mv "$CONF_DIR" "$CONF_DIR.bak"
    ln -s "$HOME/.dotfiles/config/easyeffects" "$CONF_DIR"

    echo "[!] Linked EasyEffects config"
    echo " - Add Flatseal permissions to the ~/.dotfiles/config/easyeffects directory"
  fi
}

install-easyeffects() {
  # ------------------------------
  # PIPEWIRE AND EASYEFFECTS SETUP
  # https://old.reddit.com/r/linuxmint/comments/16ndrj0/contribution_pipewire_and_easyeffects_setup_kit/
  # ------------------------------

  sudo -v

  # Install pipewire from repository
  sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y
  sudo add-apt-repository ppa:pipewire-debian/wireplumber-upstream -y
  sudo apt update
  sudo apt install pipewire -y
  sudo apt upgrade -y

  # Install wireplumber
  sudo apt purge pipewire-media-session -y
  sudo apt install wireplumber -y
  sudo apt install pipewire-pulse -y
  sudo apt purge pulseaudio -y
  sudo apt autoremove -y

  # Mask pulseaudio
  systemctl --user --now disable pulseaudio.service pulseaudio.socket
  systemctl --user mask pulseaudio
  systemctl --user --now enable pipewire pipewire-pulse wireplumber

  # Additional packages
  sudo apt install libldacbt-abr2 libldacbt-enc2 libspa-0.2-bluetooth pipewire-audio-client-libraries libspa-0.2-jack -y

  # ----------- YOU CAN REMOVE THIS PART IF YOU DON'T WANT EASYEFFECTS ----------

  sudo apt install --no-install-recommends xdg-desktop-portal-gnome -y
  flatpak install app/com.github.wwmm.easyeffects/x86_64/stable -y
  flatpak permission-reset com.github.wwmm.easyeffects

  # -----------------------------------------------------------------------------

  echo "Installation finished. Please restart your computer."
}

link-easyeffects

