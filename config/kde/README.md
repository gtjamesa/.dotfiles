# KDE / GTK appearance

> **⚠️ WIP — transitional.** Target architecture: capture the KDE appearance with
> Plasma 6.6's built-in **Save Current Theme** (a Global Theme package, applied via
> `plasma-apply-lookandfeel`), and keep `kde-sync` only for what that doesn't cover:
> **font install + font settings, GTK theming, behaviour (keyboard shortcuts, kwin
> scripts, hot corners), and Darkly asset install** — plus installing/applying the
> saved theme package on a second machine. Today the script
> still copies the full KDE config (`kdeglobals`/`kwinrc`/`kdedefaults`); that part
> retires once a Global Theme is saved and we confirm what 6.6 actually captures
> (notably whether it includes fonts — the `defaults` format suggests not). Theme
> still being tweaked; expect churn until it settles.

Synced by `shell/bin/kde-sync`. **Copy-based, not symlinked** — KConfig saves
atomically (temp file → `rename()`), which would clobber a symlink on first write.

```
kde-sync save            live config → here (run on the machine you theme on, then commit)
kde-sync load            here → live + install fonts + Darkly + reload Plasma (fresh machine)
kde-sync diff            show what live config differs from what's committed
kde-sync install-darkly  install the Darkly Qt/GTK style only
kde-sync install-fonts   install the Inter font family only
```

**Before installing on a second machine:** keep tweaking on the source machine,
then run `kde-sync diff` to review everything that's drifted and `kde-sync save`
to capture it (and commit) — so the laptop's `load` pulls the complete, current
config rather than a half-finished snapshot.

## What's tracked

Fonts, icon theme, widget style, colours, look-and-feel, window decorations,
cursor, and GTK 2/3/4 theming — the manifest lives at the top of `kde-sync`.

**Not tracked** (machine-specific): panel/widget layout
(`plasma-org.kde.plasma.desktop-appletsrc`), monitor config (`kwinoutputconfig.json`),
`kscreen*`, and top-level `kcminputrc` (per-device pointer/libinput state — the
cursor theme itself lives in `kdedefaults/kcminputrc`, which *is* tracked).

**Scrubbed on `save`** — machine-/time-specific noise is stripped from tracked
files so it doesn't follow you between machines (`diff` scrubs a throwaway copy of
live the same way, so a clean repo still reads in-sync). Stripped lines:
`gtk-xft-dpi` (display DPI), `ColorSchemeHash` (regenerated locally), `Speedbar Width`
(file-dialog px), the `# created by KDE Plasma` timestamp in `gtkrc`, and
`switch-to-activity-<uuid>` shortcuts (keyed to a per-machine activity id). Dropped
sections: `kwinrc`'s `[Desktops]` (virtual-desktop ids) and `[Tiling]` (tile
layouts) — its `[Plugins]` and decoration sections are kept. Edit `SCRUB` /
`SCRUB_SECTIONS` at the top of `kde-sync` to adjust.

## Assets vs settings

These files are *settings* that reference theme *assets*. Assets are installed,
not tracked:

- **Darkly** — `kde-sync install-darkly` installs both halves:
  - *Qt/KDE style* ([Bali10050/Darkly](https://github.com/Bali10050/Darkly)) — upstream
    version-matched `.fcNN.x86_64.rpm` from the latest release on Fedora (COPR
    `deltacopy/darkly` fallback); source build elsewhere.
  - *GTK 3/4 + libadwaita theme* ([wrymt/darkly-gtk](https://github.com/wrymt/darkly-gtk)) —
    built from SCSS (needs `sassc`) into `~/.local/share/themes/Darkly`.
- **Fonts** (Inter) — `kde-sync install-fonts` (also run by `load`): `rsms-inter-vf-fonts`
  on Fedora (variable build; ships an enabled fontconfig alias making it the default
  sans-serif), `fonts-inter` on Debian, `font-inter` cask on macOS.
- **Icon theme** — if packaged, `dnf install`; if a downloaded set, uncomment the
  `data|icons` line in the manifest to track `~/.local/share/icons`.
