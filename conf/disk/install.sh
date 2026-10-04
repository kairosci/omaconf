#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/gdu"
LEGACY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/dua-cli"
MARK_BEGIN="# >>> omaconf disk >>>"
MARK_END="# <<< omaconf disk <<<"

I18N_LIB="$PROJECT_DIR/scripts/lib"
# shellcheck source=/dev/null
source "$I18N_LIB/i18n.sh"
# shellcheck source=/dev/null
source "$I18N_LIB/userconf.sh"

i18n_init

install_user_file "$SCRIPT_DIR/data/gdu.yaml" "$CONFIG_DIR/gdu.yaml"

if [[ -x "$PROJECT_DIR/hooks/theme-set.d/disk-theme" ]]; then
    bash "$PROJECT_DIR/hooks/theme-set.d/disk-theme" 2>/dev/null || warn "install.theme_sync_skipped"
fi

if [[ -d "$LEGACY_DIR" ]]; then
    rm -rf "$LEGACY_DIR" 2>/dev/null || warn "install.disk_legacy_skipped"
fi

install_shell_block "$HOME/.bashrc" "$MARK_BEGIN" "$MARK_END" << 'SHELLBLOCK'
function dh() {
	cat << 'HELP'
gdu - disk usage (vim-style, same as yazi)   views and more
  j/k ............ move                       ? ............ full help
  g/G ............ top/bottom                  s ............ sort size
  h/l, enter ..... parent/enter                 d ............ delete
  space .......... mark for deletion            q ............ quit
  gdu ............ interactive here             gdu ~/Downloads . scan path
HELP
}
SHELLBLOCK

log "install.disk_done"
