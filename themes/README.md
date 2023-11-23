# Themes

This directory stores ohmyzsh and Gnome terminal themes

```bash
# Dump a profile
$ dconf dump /org/gnome/terminal/legacy/profiles:/:1430663d-083b-4737-a7f5-8378cc8226d1/ > material-theme-profile.dconf

# Dump all profiles
$ dconf dump /org/gnome/terminal/legacy/profiles:/ > gnome-terminal-profiles.dconf

# Load a profile
$ dconf load /org/gnome/terminal/legacy/profiles:/:afb4f136-0d48-418d-a852-9978e8d3efa3/ < gnome-terminal-profiles.dconf
```
