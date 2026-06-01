#!/usr/bin/env bash
set -e
set -u
set -o pipefail

# Toggle default PipeWire sink between speakers and headphones.

SPEAKERS="alsa_output.pci-0000_0c_00.4.analog-stereo"
HEADPHONES="alsa_output.usb-Logitech_PRO_X_000000000000-00.analog-stereo"

current=$(pactl get-default-sink)

if [ "$current" = "$SPEAKERS" ]; then
    target="$HEADPHONES"
else
    target="$SPEAKERS"
fi

# Switch default sink
pactl set-default-sink "$target"

# Move all currently playing streams to the new sink
pactl list short sink-inputs | awk '{print $1}' | while read -r id; do
    pactl move-sink-input "$id" "$target"
done
