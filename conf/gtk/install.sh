#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
source "$PROJECT_DIR/scripts/lib/i18n.sh"
source "$PROJECT_DIR/scripts/lib/userconf.sh"
i18n_init
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
install_user_file "$SCRIPT_DIR/data/tiling.lua" "$CONFIG_HOME/hypr/omaconf-gtk.lua"
if [[ -f "$CONFIG_HOME/hypr/hyprland.lua" ]]; then
    install_shell_block "$CONFIG_HOME/hypr/hyprland.lua" '-- omaconf gtk tiling (managed)' '-- end omaconf gtk tiling (managed)' <<'LUA'
require("omaconf-gtk")
LUA
fi
apply_user_gsettings "$SCRIPT_DIR/data/settings.tsv"
log "gui.install_done" "GTK"
