# Theme previews

The setup pipeline regenerates previews with `make setup REBUILD_PREVIEWS=1`. It captures real Geany and Thunar windows in isolated application instances on a temporary workspace for each explicitly selected theme, with sample files rather than personal documents. The original workspace is restored on exit; the active theme stays unchanged.

Previews are normalized to 1800 × 1012, RGBA, depth 8 and density 72. Setup installs user overlays, and existing stock backups remain available for restoration. Preview capture requires an active, unlocked Omarchy session.
