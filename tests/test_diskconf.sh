#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DISK_INSTALLER="$PROJECT_DIR/diskconf/install.sh"
DISK_DATA="$PROJECT_DIR/diskconf/data/config.toml"
DISK_HOOK="$PROJECT_DIR/hooks/theme-set.d/disk-theme"
DEFAULTS_MODULE="$PROJECT_DIR/scripts/modules/20-defaults.sh"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Disk Usage Analyzer Configuration"

assert_file_exists "diskconf installer exists" "$DISK_INSTALLER"
assert_file_executable "diskconf installer is executable" "$DISK_INSTALLER"
assert_file_exists "dua-cli base config exists" "$DISK_DATA"
assert_file_exists "disk-theme hook exists" "$DISK_HOOK"
assert_file_executable "disk-theme hook is executable" "$DISK_HOOK"

assert_file_contains "diskconf installer uses strict mode" "$DISK_INSTALLER" "set -euo pipefail"
assert_file_contains "disk-theme hook uses strict mode" "$DISK_HOOK" "set -euo pipefail"
assert_file_contains "diskconf installer sources the i18n library" "$DISK_INSTALLER" "i18n.sh"
assert_file_contains "diskconf installer sources the user config library" "$DISK_INSTALLER" "userconf.sh"
assert_file_contains "diskconf installer initializes i18n" "$DISK_INSTALLER" "i18n_init"
assert_file_contains "disk-theme hook bootstraps i18n" "$DISK_HOOK" "i18n-boot.sh"
assert_file_not_contains "diskconf installer has no raw failure suppression" "$DISK_INSTALLER" '\|\|[[:space:]]*true'
assert_file_not_contains "disk-theme hook has no raw failure suppression" "$DISK_HOOK" '\|\|[[:space:]]*true'
assert_file_not_contains "diskconf installer never hardcodes a user home" "$DISK_INSTALLER" "/home/"
assert_file_not_contains "disk-theme hook never hardcodes a user home" "$DISK_HOOK" "/home/"

assert_file_contains "diskconf targets the dua-cli config dir" "$DISK_INSTALLER" '}/dua-cli"'
assert_file_contains "diskconf installer deploys the dua-cli config" "$DISK_INSTALLER" 'CONFIG_DIR/config.toml'
assert_file_contains "diskconf installer syncs the theme hook" "$DISK_INSTALLER" "theme-set.d/disk-theme"
assert_file_contains "diskconf installer degrades gracefully on theme skip" "$DISK_INSTALLER" 'install.theme_sync_skipped'
assert_file_contains "diskconf installer manages the shell block" "$DISK_INSTALLER" "install_shell_block"
assert_file_contains "diskconf installer ships the terminal quick card" "$DISK_INSTALLER" "function dh\(\)"
assert_file_contains "diskconf quick card documents panes" "$DISK_INSTALLER" "cycle panes"
assert_file_contains "diskconf quick card points at the built-in help" "$DISK_INSTALLER" "full help"
assert_file_contains "diskconf installer logs completion through i18n" "$DISK_INSTALLER" 'log "install.disk_done"'

if command -v python3 &>/dev/null; then
    assert_true "dua-cli config parses as TOML" "python3 -c \"import tomllib; tomllib.load(open('$DISK_DATA','rb'))\""
    assert_true "dua-cli config keeps unified vim-style keys" "python3 -c \"
import tomllib
cfg = tomllib.load(open('$DISK_DATA','rb'))
assert cfg.get('format') == 'binary', 'byte format not pinned'
keys = cfg.get('keys', {})
assert keys.get('esc_navigates_back') is True, 'esc_navigates_back missing'
assert keys.get('quit') == 'q', 'quit is not q like yazi'
assert keys.get('toggle_help') == '?', 'help is not ? like yazi'
assert keys.get('open_search') == '/', 'search is not / like yazi'
assert keys.get('toggle_mark') == 'space', 'mark is not space like yazi'
assert 'j' in keys.get('move_down', []), 'move_down is not j like yazi'
assert 'k' in keys.get('move_up', []), 'move_up is not k like yazi'
assert 'g' in keys.get('move_to_top', []), 'move_to_top misses yazi-style g'
assert 'G' in keys.get('move_to_bottom', []), 'move_to_bottom is not G like yazi'
assert 'h' in keys.get('ascend', []), 'ascend misses yazi-style h'
assert 'l' in keys.get('descend', []), 'descend misses yazi-style l'
assert 'O' in keys.get('open_entry', []), 'open_entry is not O like yazi'
assert 'toggle_right_panes' not in keys, 'undocumented key would be silently ignored'
\""
    assert_true "dua-cli config sets no unsupported color section" "python3 -c \"
import tomllib
cfg = tomllib.load(open('$DISK_DATA','rb'))
assert 'colors' not in cfg and 'theme' not in cfg, 'fake color section would be silently ignored by dua'
\""
else
    assert_true "python3 available for TOML checks" "false"
fi

assert_file_contains "disk-theme hook resolves the current theme without hardcoding" "$DISK_HOOK" 'CURRENT_THEME'
assert_file_contains "disk-theme hook reads the omarchy palette" "$DISK_HOOK" 'colors.toml'
assert_file_not_contains "disk-theme hook hardcodes no theme name" "$DISK_HOOK" 'themes/catppuccin|themes/tokyo-night|themes/gruvbox'
assert_file_contains "disk-theme hook rejects theme path traversal" "$DISK_HOOK" '\*..\*'
assert_file_contains "disk-theme hook validates palette hex colors" "$DISK_HOOK" '#\[0-9a-fA-F\]'
assert_file_not_contains "disk-theme hook reads the palette without early-exit pipelines" "$DISK_HOOK" '\| head'
assert_file_contains "disk-theme hook manages its own header range" "$DISK_HOOK" 'omaconf disk theme'
assert_file_contains "disk-theme hook writes atomically" "$DISK_HOOK" 'mktemp'
assert_file_contains "disk-theme hook keeps the config permissions tight" "$DISK_HOOK" 'chmod 644'

assert_file_contains "defaults module installs dua-cli from the repos" "$DEFAULTS_MODULE" 'pacman -Q dua-cli'
assert_file_contains "defaults module provisions diskconf per user" "$DEFAULTS_MODULE" 'diskconf/install.sh'
assert_file_contains "defaults module warns without aborting on skip" "$DEFAULTS_MODULE" 'defaults.diskconf_skipped'
assert_file_not_contains "defaults disk block never exits the sourcing setup" "$DEFAULTS_MODULE" 'defaults.diskconf_skipped.*exit'

assert_file_contains "Makefile exposes disk target" "$PROJECT_DIR/Makefile" '^disk:'
assert_file_contains "Makefile lints diskconf" "$PROJECT_DIR/Makefile" 'diskconf/'
assert_file_contains "help lists disk target" "$PROJECT_DIR/scripts/lib/help.sh" 'row disk "make.disk"'
assert_file_contains "verify checks dua-cli package" "$PROJECT_DIR/scripts/verify.sh" 'dua-cli'
assert_file_contains "verify checks dua-cli config" "$PROJECT_DIR/scripts/verify.sh" 'dua-cli/config.toml'
assert_file_contains "verify checks disk-theme hook" "$PROJECT_DIR/scripts/verify.sh" 'theme-set.d/disk-theme'
assert_file_contains "cliconf covers dua" "$PROJECT_DIR/cliconf/data/helpers.sh" 'dua)'

for key in install.disk_done defaults.disk_install defaults.disk_failed defaults.diskconf defaults.diskconf_skipped make.disk check.disk_config check.disk_theme_hook; do
    assert_true "catalog en defines $key" "grep -qE '^$key=' '$PROJECT_DIR/scripts/lib/messages/en.msg'"
done

if ((UID != 0)); then
    DISK_SANDBOX="$(mktemp -d)"
    mkdir -p "$DISK_SANDBOX/home"
    touch "$DISK_SANDBOX/home/.bashrc"
    (
        set -euo pipefail
        export HOME="$DISK_SANDBOX/home"
        export XDG_CONFIG_HOME="$DISK_SANDBOX/home/.config"
        export OMACONF_LANG="en"
        bash "$DISK_INSTALLER" 2>/dev/null
        bash "$DISK_INSTALLER" 2>/dev/null
    ) 2>/dev/null
    assert_true "diskconf seeds the dua-cli config" "[[ -f '$DISK_SANDBOX/home/.config/dua-cli/config.toml' ]]"
    assert_true "diskconf records the theme header" "grep -q 'omaconf disk theme' '$DISK_SANDBOX/home/.config/dua-cli/config.toml'"
    assert_true "diskconf installs the dh quick card" "grep -q 'function dh()' '$DISK_SANDBOX/home/.bashrc'"
    assert_true "diskconf writes exactly one shell block" "[[ \$(grep -c '>>> omaconf disk >>>' '$DISK_SANDBOX/home/.bashrc') -eq 1 ]]"
    assert_true "diskconf writes exactly one theme header" "[[ \$(grep -c '>>> omaconf disk theme >>>' '$DISK_SANDBOX/home/.config/dua-cli/config.toml') -eq 1 ]]"
    if command -v python3 &>/dev/null; then
        assert_true "seeded dua-cli config stays valid TOML" "python3 -c \"import tomllib; tomllib.load(open('$DISK_SANDBOX/home/.config/dua-cli/config.toml','rb'))\""
    fi
    rm -rf "$DISK_SANDBOX"
fi

test_summary
