#!/usr/bin/env bash
set -e
set -u
set -o pipefail

SPEAKERS="alsa_output.pci-0000_0c_00.4.analog-stereo"
HEADPHONES="alsa_output.usb-Logitech_PRO_X_000000000000-00.analog-stereo"

current=$(pactl get-default-sink)

case "$current" in
    "$SPEAKERS")   echo "speakers" ;;
    "$HEADPHONES") echo "headphones" ;;
    *)             echo "other" ;;
esac
