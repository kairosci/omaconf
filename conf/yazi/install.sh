#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/yazi"
APP_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/applications"
FM_DESKTOP="yazi-terminal.desktop"
MARK_BEGIN="# >>> omaconf yazi >>>"
MARK_END="# <<< omaconf yazi <<<"

I18N_LIB="$PROJECT_DIR/scripts/lib"
# shellcheck source=/dev/null
source "$I18N_LIB/i18n.sh"
# shellcheck source=/dev/null
source "$I18N_LIB/userconf.sh"

i18n_init

for cfg in yazi.toml keymap.toml theme.toml; do
    install_user_file "$SCRIPT_DIR/data/$cfg" "$CONFIG_DIR/$cfg"
done

mkdir -p "$CONFIG_DIR/plugins/smart-enter.yazi"
install_user_file "$SCRIPT_DIR/data/plugins/smart-enter.yazi/main.lua" "$CONFIG_DIR/plugins/smart-enter.yazi/main.lua"

if [[ -x "$PROJECT_DIR/hooks/theme-set.d/yazi-theme" ]]; then
    bash "$PROJECT_DIR/hooks/theme-set.d/yazi-theme" 2>/dev/null || warn "install.theme_sync_skipped"
fi

install_user_file "$SCRIPT_DIR/data/$FM_DESKTOP" "$APP_DIR/$FM_DESKTOP"
update-desktop-database "$APP_DIR" 2>/dev/null || warn "install.desktopdb_skipped"

install_shell_block "$HOME/.bashrc" "$MARK_BEGIN" "$MARK_END" << 'SHELLBLOCK'
function ya() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}
function yh() {
	cat << 'HELP'
yazi - navigation (vim-style)           quick openers
  k/j up/down .... up/down               text/md ..... micro
  h/l left/right . back/forward          pdf ....... mupdf
  gg/G ........... start/end             images ...... imv
  z/Z ............ jump with fzf/zoxide  audio/video . mpv
  o/O ............ open / open-with      archives .... extract here
  y/x/p .......... copy/cut/paste
  Tab ............ select, v visual      ~ ........... full help
   : .............. command, Q quit       ya .......... quit staying here
   picker ....... file Enter confirms+quits, dir Enter enters, q cancels
HELP
}
SHELLBLOCK

log "install.yazi_done"
