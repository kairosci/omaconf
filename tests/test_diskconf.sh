#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DISK_INSTALLER="$PROJECT_DIR/conf/disk/install.sh"
DISK_DATA="$PROJECT_DIR/conf/disk/data/gdu.yaml"
DISK_HOOK="$PROJECT_DIR/hooks/theme-set.d/disk-theme"
DEFAULTS_MODULE="$PROJECT_DIR/scripts/lib/modules/20-defaults.sh"
DEBLOAT_MODULE="$PROJECT_DIR/scripts/lib/modules/10-debloat.sh"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Disk Usage Analyzer Configuration"

assert_file_exists "diskconf installer exists" "$DISK_INSTALLER"
assert_file_executable "diskconf installer is executable" "$DISK_INSTALLER"
assert_file_exists "gdu base config exists" "$DISK_DATA"
assert_true "diskconf data and hook dropped dua" "! grep -rq 'dua-cli' '$PROJECT_DIR/conf/disk/data' '$DISK_HOOK'"
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

assert_file_contains "diskconf targets the gdu config dir" "$DISK_INSTALLER" '}/gdu"'
assert_file_contains "diskconf installer deploys the gdu config" "$DISK_INSTALLER" 'CONFIG_DIR/gdu.yaml'
assert_file_contains "diskconf installer syncs the theme hook" "$DISK_INSTALLER" "theme-set.d/disk-theme"
assert_file_contains "diskconf installer degrades gracefully on theme skip" "$DISK_INSTALLER" 'install.theme_sync_skipped'
assert_file_contains "diskconf installer cleans the legacy dua config" "$DISK_INSTALLER" 'LEGACY_DIR'
assert_file_contains "diskconf installer warns without aborting on legacy skip" "$DISK_INSTALLER" 'install.disk_legacy_skipped'
assert_file_contains "diskconf installer manages the shell block" "$DISK_INSTALLER" "install_shell_block"
assert_file_contains "diskconf installer ships the terminal quick card" "$DISK_INSTALLER" "function dh\(\)"
assert_file_contains "diskconf quick card documents vim-style parity" "$DISK_INSTALLER" "vim-style"
assert_file_contains "diskconf quick card points at the built-in help" "$DISK_INSTALLER" "full help"
assert_file_contains "diskconf installer logs completion through i18n" "$DISK_INSTALLER" 'log "install.disk_done"'

if command -v python3 &>/dev/null; then
    assert_true "gdu base config parses as YAML" "python3 -c \"import yaml; yaml.safe_load(open('$DISK_DATA'))\""
    assert_true "gdu base config leaves style to the theme hook" "python3 -c \"
import yaml
cfg = yaml.safe_load(open('$DISK_DATA'))
assert 'style' not in cfg, 'style section belongs to the theme hook'
assert cfg.get('use-si-prefix') is False, 'binary prefixes keep house byte format'
\""
else
    assert_true "python3 available for YAML checks" "false"
fi

assert_file_contains "disk-theme hook resolves the current theme without hardcoding" "$DISK_HOOK" 'CURRENT_THEME'
assert_file_contains "disk-theme hook reads the omarchy palette" "$DISK_HOOK" 'colors.toml'
assert_file_not_contains "disk-theme hook hardcodes no theme name" "$DISK_HOOK" 'themes/catppuccin|themes/tokyo-night|themes/gruvbox'
assert_file_contains "disk-theme hook rejects theme path traversal" "$DISK_HOOK" '\*..\*'
assert_file_contains "disk-theme hook validates palette hex colors" "$DISK_HOOK" '#\[0-9a-fA-F\]'
assert_file_not_contains "disk-theme hook reads the palette without early-exit pipelines" "$DISK_HOOK" '\| head'
assert_file_contains "disk-theme hook generates a real gdu style" "$DISK_HOOK" 'selected-row:'
assert_file_contains "disk-theme hook themes result rows" "$DISK_HOOK" 'directory-color:'
assert_file_contains "disk-theme hook quotes hex colors for YAML" "$DISK_HOOK" 'text-color: \\"'
assert_file_contains "disk-theme hook manages its own header range" "$DISK_HOOK" 'omaconf disk theme'
assert_file_contains "disk-theme hook writes atomically" "$DISK_HOOK" 'mktemp'
assert_file_contains "disk-theme hook keeps the config permissions tight" "$DISK_HOOK" 'chmod 644'

assert_file_contains "defaults module installs gdu from the repos" "$DEFAULTS_MODULE" 'pacman -Q gdu'
assert_file_contains "setup discovers the disk installer" "$PROJECT_DIR/scripts/lib/modules/24-user-configurations.sh" 'conf/\*/install.sh'
assert_file_contains "setup propagates app config failures" "$PROJECT_DIR/scripts/lib/modules/24-user-configurations.sh" 'err "defaults.app_failed"'
assert_file_not_contains "defaults disk block never exits the sourcing setup" "$DEFAULTS_MODULE" 'defaults.diskconf_skipped.*exit'
assert_file_contains "debloat module removes the replaced analyzer" "$DEBLOAT_MODULE" 'dua-cli'

assert_file_contains "Makefile exposes disk target" "$PROJECT_DIR/Makefile" '^disk:'
assert_file_contains "Makefile lints diskconf" "$PROJECT_DIR/Makefile" 'conf/disk/'
assert_file_contains "help lists disk target" "$PROJECT_DIR/scripts/lib/help.sh" 'row disk "make.disk"'
assert_file_contains "Arch CI installs YAML test dependencies" "$PROJECT_DIR/.github/workflows/ci.yml" 'base-devel git sudo jq python python-yaml'
assert_file_contains "verify checks gdu package" "$PROJECT_DIR/scripts/verify.sh" 'pacman -Q gdu'
assert_file_contains "verify checks gdu config" "$PROJECT_DIR/scripts/verify.sh" 'gdu/gdu.yaml'
assert_file_contains "verify drops the dua package" "$PROJECT_DIR/scripts/verify.sh" 'pacman -Q dua-cli'
assert_file_contains "verify checks disk-theme hook" "$PROJECT_DIR/scripts/verify.sh" 'theme-set.d/disk-theme'
assert_file_contains "cliconf covers gdu" "$PROJECT_DIR/conf/cli/data/helpers.sh" 'gdu)'
assert_file_contains "cliconf redirects legacy dua to gdu" "$PROJECT_DIR/conf/cli/data/helpers.sh" 'dua | disk'

for key in install.disk_done install.disk_legacy_skipped defaults.disk_install defaults.disk_failed defaults.diskconf defaults.diskconf_skipped make.disk check.disk_config check.disk_theme_hook; do
    assert_true "catalog en defines $key" "grep -qE '^$key=' '$PROJECT_DIR/scripts/lib/messages/en.msg'"
done

if ((UID != 0)); then
    DISK_SANDBOX="$(mktemp -d)"
    mkdir -p "$DISK_SANDBOX/home/.config/dua-cli"
    printf '# legacy\n' > "$DISK_SANDBOX/home/.config/dua-cli/config.toml"
    touch "$DISK_SANDBOX/home/.bashrc"
    (
        set -euo pipefail
        export HOME="$DISK_SANDBOX/home"
        export XDG_CONFIG_HOME="$DISK_SANDBOX/home/.config"
        export OMACONF_LANG="en"
        bash "$DISK_INSTALLER" 2>/dev/null
        bash "$DISK_INSTALLER" 2>/dev/null
    ) 2>/dev/null
    assert_true "diskconf seeds the gdu config" "[[ -f '$DISK_SANDBOX/home/.config/gdu/gdu.yaml' ]]"
    assert_true "diskconf records the theme header" "grep -q 'omaconf disk theme' '$DISK_SANDBOX/home/.config/gdu/gdu.yaml'"
    assert_true "diskconf generates the gdu style section" "grep -q '^style:' '$DISK_SANDBOX/home/.config/gdu/gdu.yaml'"
    assert_true "diskconf themes the selected row" "grep -q 'selected-row:' '$DISK_SANDBOX/home/.config/gdu/gdu.yaml'"
    assert_true "diskconf removes the legacy dua config" "[[ ! -e '$DISK_SANDBOX/home/.config/dua-cli' ]]"
    assert_true "diskconf installs the dh quick card" "grep -q 'function dh()' '$DISK_SANDBOX/home/.bashrc'"
    assert_true "diskconf writes exactly one shell block" "[[ \$(grep -c '>>> omaconf disk >>>' '$DISK_SANDBOX/home/.bashrc') -eq 1 ]]"
    assert_true "diskconf writes exactly one theme header" "[[ \$(grep -c '>>> omaconf disk theme >>>' '$DISK_SANDBOX/home/.config/gdu/gdu.yaml') -eq 1 ]]"
    if command -v python3 &>/dev/null; then
        assert_true "seeded gdu config stays valid YAML" "python3 -c \"import yaml; yaml.safe_load(open('$DISK_SANDBOX/home/.config/gdu/gdu.yaml'))\""
        assert_true "seeded gdu style carries quoted hex colors" "python3 -c \"
import yaml
cfg = yaml.safe_load(open('$DISK_SANDBOX/home/.config/gdu/gdu.yaml'))
style = cfg.get('style', {})
assert style.get('selected-row', {}).get('background-color', '').startswith('#'), 'selected row has no theme color'
assert style.get('result-row', {}).get('directory-color', '').startswith('#'), 'directories have no theme color'
\""
    fi
    if command -v gdu &>/dev/null; then
        assert_true "gdu loads the seeded config" "gdu --config-file '$DISK_SANDBOX/home/.config/gdu/gdu.yaml' -n '$DISK_SANDBOX/home' 2>/dev/null"
    fi
    rm -rf "$DISK_SANDBOX"
fi

test_summary
