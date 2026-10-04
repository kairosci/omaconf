#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/micro"
MARK_BEGIN="# >>> omaconf micro >>>"
MARK_END="# <<< omaconf micro <<<"

I18N_LIB="$PROJECT_DIR/scripts/lib"
# shellcheck source=/dev/null
source "$I18N_LIB/i18n.sh"
# shellcheck source=/dev/null
source "$I18N_LIB/userconf.sh"

i18n_init

mkdir -p "$CONFIG_DIR/colorschemes"

if command -v jq &>/dev/null && [[ -s "$CONFIG_DIR/settings.json" ]]; then
    if ! jq -s '.[0] * .[1]' "$CONFIG_DIR/settings.json" "$SCRIPT_DIR/data/settings.json" 2>/dev/null | install_user_content "$CONFIG_DIR/settings.json"; then
        install_user_file "$SCRIPT_DIR/data/settings.json" "$CONFIG_DIR/settings.json"
    fi
else
    install_user_file "$SCRIPT_DIR/data/settings.json" "$CONFIG_DIR/settings.json"
fi

install_user_file "$SCRIPT_DIR/data/bindings.json" "$CONFIG_DIR/bindings.json"

if command -v micro &>/dev/null; then
    for plugin in detectindent jump snippets run editorconfig; do
        if ! micro -plugin list 2>/dev/null | grep -q "^$plugin "; then
            if ! plugin_output="$(micro -plugin install "$plugin" 2>&1)" || grep -Eq 'Unknown plugin|Failed to query plugin channel' <<< "$plugin_output"; then
                warn "install.micro_plugin_skipped" "$plugin"
            fi
        fi
    done
fi

if [[ -x "$PROJECT_DIR/hooks/theme-set.d/micro-theme" ]]; then
    bash "$PROJECT_DIR/hooks/theme-set.d/micro-theme" 2>/dev/null || warn "install.theme_sync_skipped"
fi

install_shell_block "$HOME/.bashrc" "$MARK_BEGIN" "$MARK_END" << 'SHELLBLOCK'
function mh() {
	cat << 'HELP'
micro - essentials                        project tools
  Ctrl-s ......... save                    F4 ........... jump to symbol
  Ctrl-q ......... quit                    Ctrl-e ....... command line
  Ctrl-z / Ctrl-y  undo / redo             Ctrl-g ....... editor help
  Ctrl-f/h ....... find / replace
  Ctrl-a/c/x/v ... select copy cut paste   Alt-g/h ...... split views
  Ctrl-k / Ctrl-d  cut line / duplicate
HELP
}
SHELLBLOCK

log "install.micro_done"
