#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dua-cli"
MARK_BEGIN="# >>> omaconf disk >>>"
MARK_END="# <<< omaconf disk <<<"

I18N_LIB="$(dirname "$SCRIPT_DIR")/scripts/lib"
# shellcheck source=/dev/null
source "$I18N_LIB/i18n.sh"
# shellcheck source=/dev/null
source "$I18N_LIB/userconf.sh"

i18n_init

install_user_file "$SCRIPT_DIR/data/config.toml" "$CONFIG_DIR/config.toml"

if [[ -x "$PROJECT_DIR/hooks/theme-set.d/disk-theme" ]]; then
    bash "$PROJECT_DIR/hooks/theme-set.d/disk-theme" 2>/dev/null || warn "install.theme_sync_skipped"
fi

install_shell_block "$HOME/.bashrc" "$MARK_BEGIN" "$MARK_END" << 'SHELLBLOCK'
function dh() {
	cat << 'HELP'
dua - disk usage (vim-style)              panes and actions
  j/k or arrows .. move (same as yazi)     Tab .......... cycle panes
  gg/G ........... top/bottom              ] ............ toggle right panes
  Enter .......... open directory          / ............ search
  ? .............. full help inside dua    q/Esc ........ quit/back
  dua i .......... interactive here        dua i ~/Downloads . scan path
  deletion is multi-stage, confirm each step inside dua
HELP
}
SHELLBLOCK

log "install.disk_done"
