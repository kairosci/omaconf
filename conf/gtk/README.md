# GTK

Setup installs flat GTK styling through the palette hook and native settings through this installer. GTK animations are disabled; client titlebars retain the close button. Square controls, compact headerbars, outlined keyboard focus and palette selection remain visible in light and dark themes.

Nautilus, Papers, Loupe, Baobab, Resources and File Roller use opaque, square windows without compositor shadows, blur or window animations. Celluloid receives the same treatment. Main windows tile; modal dialogs and windows tagged by Omarchy as floating retain their dialog behavior. The user layout, gaps and keybindings are preserved.

Run `make setup` after merging the desktop PRs. Reopen libadwaita applications to load updated CSS. The installer preserves unrelated Hyprland configuration.
