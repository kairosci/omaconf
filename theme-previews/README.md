# Theme previews

Run `make setup REBUILD_PREVIEWS=1` to regenerate every registered preview through the privileged pipeline.

The capture runner applies each actual Omarchy theme, waits for its wallpaper and shell transition, opens sample Geany and Thunar windows on an unused workspace, and captures the complete focused monitor. Application state is isolated from personal sessions. The original theme, background and workspace are restored on completion or failure.

Previews are normalized by `scripts/lib/theme-preview.sh` to uniform geometry, RGBA depth 8 and density 72. Setup installs user overlays and the update hook preserves normalization. Stock previews remain available for restoration.

The capture settings use an isolated keyfile backend so GTK actually resolves the configured icon theme. Generated GTK themes and icon assets remain available to isolated apps without exposing personal configuration. Window size and position are proportional to the focused monitor; no window crops or synthetic compositions are used.
