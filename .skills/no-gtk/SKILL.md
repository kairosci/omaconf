---
name: no-gtk
description: >-
  Keep GTK applications out of Omaconf defaults and audit unavoidable system GTK dependencies.
---

# No GTK

## Default application policy

Provisioned GUI applications must be toolkit-free where practical and Qt otherwise. Do not install Electron applications as defaults. Electron embeds Chromium and its Linux desktop integration still depends on GTK; selecting Qt themes cannot replace that runtime dependency. Prefer official Arch packages and avoid KDE or GNOME desktop stacks.

The current defaults use qutebrowser with QtWebEngine and python-adblock for browsing and MuPDF for PDFs. Yazi, Micro, Kitty, imv, mpv, btop and Herdr remain toolkit-free. Route file selection through termfilechooser and mask the GTK portal backend. Do not write GTK theme settings; configure Qt with the xdgdesktop platform theme.

## Dependency audit

Before removing GTK packages, inspect reverse dependencies on the target machine:

```bash
pactree -r gtk3
pactree -r gtk4
```

Omarchy currently requires `gnome-keyring`, which requires `gcr` and GTK3. GTK4 also remains required by Omarchy-adjacent system components such as the preview-share picker, `tensaku`, `zenity`, and NetworkManager OpenVPN integration. Removing these dependencies without replacing their owners breaks desktop or VPN functions. Keep GTK libraries only for those required dependencies and separately installed third-party applications; never select GTK applications as Omaconf defaults.

Sushi, `gtksourceview4`, and `gst-plugin-gtk` form a removable GNOME previewer group and belong in `DEBLOAT`. Do not add `xdg-desktop-portal-gtk` to the removal set while GTK4 depends on it; mask its service and route supported portal requests to Hyprland or termfilechooser.

## Keyring backend

The keyring backend is selected by `make keyring BACKEND=keepassxc` or `make keyring BACKEND=gnome-keyring`. Both implement the Secret Service API. KeePassXC is the preferred Qt backend; its database must be created and unlocked by the user before applications can read stored secrets. The package `gnome-keyring` remains installed while Omarchy depends on it, even when its daemon is masked.

## Removal procedure

Remove unwanted packages through `DEBLOAT` in `scripts/modules/10-debloat.sh`, pin them in `IgnorePkg`, and update the package inventory and tests. Audit reverse dependencies first and document any system package that cannot be removed without losing a required function.
