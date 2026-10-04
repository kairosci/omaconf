#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/qutebrowser"
I18N_LIB="$PROJECT_DIR/scripts/lib"
# shellcheck source=/dev/null
source "$I18N_LIB/i18n.sh"
# shellcheck source=/dev/null
source "$I18N_LIB/userconf.sh"

i18n_init

mkdir -p "$CONFIG_DIR"
install_user_file "$SCRIPT_DIR/data/config.py" "$CONFIG_DIR/config.py"
log "install.qute_done"
