---
name: desktop-applications
description: >-
  Select and integrate graphical applications, GTK file dialogs and desktop defaults without unnecessary desktop stacks.
---

# Desktop Applications

Thunar is the graphical file manager. Provision GVFS for trash and mounts, gvfs-mtp for phones, Tumbler for thumbnails, and thunar-archive-plugin with File Roller for archives. Nautilus remains excluded. Remove Yazi and its provisioned integrations while preserving personal data.

Geany edits text, Papers opens PDFs, Loupe opens images, Celluloid plays media, Baobab analyzes storage and Resources monitors the system. Register their MIME defaults and Omarchy launch shortcuts through the shared desktop workflow. Retain existing terminal tools as optional alternatives.

Brave is the sole provisioned browser. Remove qutebrowser, its adblock dependency and the terminal file chooser backend through the debloat stage and persistent pins. Preserve user data when removing applications.

Route FileChooser and AppChooser to GTK, and ScreenCast and Screenshot to Hyprland. Unmask GTK when migrating an existing installation. Keep the routing in one canonical config and share its application between setup and post-update. Never route an interface to a backend that does not implement it.

GTK applications and runtime libraries are allowed. Prefer maintained Arch packages and avoid installing a complete GNOME, KDE or Xfce desktop to obtain one application. Audit reverse dependencies before removing shared libraries. Preserve Omarchy, NetworkManager, the active Secret Service provider and session IPC.

GTK styling follows the active Omarchy palette through a theme hook; retain the user's unrelated CSS and settings. Apply all live changes through the setup pipeline and verify actual MIME defaults, portal services and thumbnail support after migration.
