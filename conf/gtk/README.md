# GTK

Setup installs flat GTK styling through the palette hook and native settings through this installer. GTK animations and client window buttons are disabled. Square controls, compact headerbars, outlined keyboard focus and palette selection remain visible in light and dark themes. Headerbars, sidebars, cards and dialogs share the palette background without raised surfaces.

All application windows use opaque, square surfaces without compositor shadows or blur. Opening windows and popups fade in over 180 ms; closing windows fade out over 140 ms. Workspace changes, including special workspaces, are immediate to avoid overlapping outgoing and incoming tiles. Focus borders ease over 140 ms. Window geometry updates immediately, avoiding animated paths that cross neighboring tiles. Tearing is explicitly disabled. Omarchy's application animation exclusions and instant bar and panel layer rules remain authoritative.

The desktop uses the dwindle tiling layout with zero gaps and one pixel borders. Main windows tile; modal dialogs and windows tagged by Omarchy as floating retain their dialog behavior. Keybindings are preserved. GTK keeps application controls and file dialogs functional, with flat palette colors and no client window buttons, gradients or rounded widgets.

Run `make setup` after merging the desktop PRs. Reopen libadwaita applications to load updated CSS. The installer preserves unrelated Hyprland configuration.
