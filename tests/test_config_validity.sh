#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SHELL_PLUGINS_MODULE="$PROJECT_DIR/scripts/modules/35-shell-plugins.sh"
YAZI_DATA="$PROJECT_DIR/conf/yazi/data"
CLICONF_DATA="$PROJECT_DIR/conf/cli/data"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Config Validity & Placement Regression"

assert_file_contains "shell plugins module keeps omamp on the right" "$SHELL_PLUGINS_MODULE" "section right"

if command -v python3 &>/dev/null; then
    assert_true "yazi.toml parses as TOML" "python3 -c \"import tomllib; tomllib.load(open('$YAZI_DATA/yazi.toml','rb'))\""
    assert_true "yazi theme.toml parses as TOML" "python3 -c \"import tomllib; tomllib.load(open('$YAZI_DATA/theme.toml','rb'))\""
    assert_true "every yazi open rule has url or mime" "python3 -c \"
import tomllib
cfg = tomllib.load(open('$YAZI_DATA/yazi.toml','rb'))
rules = cfg.get('open', {}).get('rules', [])
assert rules, 'no open rules found'
bad = [r for r in rules if 'url' not in r and 'mime' not in r]
assert not bad, f'rules without url/mime: {bad}'
\""
    assert_true "every yazi opener has a run command" "python3 -c \"
import tomllib
cfg = tomllib.load(open('$YAZI_DATA/yazi.toml','rb'))
ops = cfg.get('opener', {})
assert ops, 'no openers found'
bad = [k for k, v in ops.items() if not all('run' in e for e in v)]
assert not bad, f'openers without run: {bad}'
\""
    assert_true "yazi open rules end with a catch-all reveal fallback" "python3 -c \"
import tomllib
cfg = tomllib.load(open('$YAZI_DATA/yazi.toml','rb'))
rules = cfg.get('open', {}).get('rules', [])
assert rules and rules[-1].get('url') == '*' and rules[-1].get('use') == 'reveal', f'no catch-all reveal fallback: {rules[-1] if rules else None}'
ops = cfg.get('opener', {})
assert 'reveal' in ops and all('run' in e for e in ops['reveal']), 'reveal opener missing or without run'
\""
    assert_true "yazi keymap.toml parses as TOML" "python3 -c \"import tomllib; tomllib.load(open('$YAZI_DATA/keymap.toml','rb'))\""
    assert_true "yazi Enter key enters directories or opens files" "python3 -c \"
import tomllib
cfg = tomllib.load(open('$YAZI_DATA/keymap.toml','rb'))
mgr = cfg.get('mgr', {})
keys = mgr.get('prepend_keymap', []) + mgr.get('append_keymap', [])
hits = [k for k in keys if 'Enter' in str(k.get('on', '')) and 'smart-enter' in str(k.get('run', ''))]
assert hits, 'no Enter smart-enter binding found'
\""
    assert_true "yazi common keybindings map copy cut paste search and quit" "python3 -c \"
import tomllib
cfg = tomllib.load(open('$YAZI_DATA/keymap.toml','rb'))
keys = cfg.get('mgr', {}).get('prepend_keymap', [])
found = {entry['on']: entry['run'] for entry in keys}
expected = {'<C-c>': 'yank', '<C-x>': 'yank --cut', '<C-v>': 'paste', '<C-q>': 'quit', '<C-f>': 'filter --smart'}
assert all(found.get(key) == action for key, action in expected.items()), found
\""
    assert_file_exists "yazi smart-enter plugin ships its entry point" "$YAZI_DATA/plugins/smart-enter.yazi/main.lua"
    assert_file_contains_literal "smart-enter enters directories" "$YAZI_DATA/plugins/smart-enter.yazi/main.lua" 'ya.emit("enter"'
    assert_file_contains_literal "smart-enter opens files" "$YAZI_DATA/plugins/smart-enter.yazi/main.lua" 'ya.emit("open"'
else
    assert_true "python3 available for TOML checks" "false"
fi

assert_true "Micro settings JSON valid" "jq empty '$PROJECT_DIR/conf/micro/data/settings.json'"
assert_true "Micro bindings JSON valid" "jq empty '$PROJECT_DIR/conf/micro/data/bindings.json'"
assert_true "qutebrowser config Python syntax valid" "python3 -c \"compile(open('$PROJECT_DIR/conf/qutebrowser/data/config.py').read(), 'config.py', 'exec')\""
assert_file_contains_literal "Micro shares common editor bindings" "$PROJECT_DIR/conf/micro/data/bindings.json" '"Ctrl-s": "Save"'
assert_file_contains_literal "Micro shares search and history bindings" "$PROJECT_DIR/conf/micro/data/bindings.json" '"Ctrl-z": "Undo"'
assert_file_contains_literal "qutebrowser saves, searches and quits on common chords" "$PROJECT_DIR/conf/qutebrowser/data/config.py" 'config.bind("<Ctrl+Q>", "quit")'

assert_true "cliconf helpers bash syntax valid" "bash -n '$CLICONF_DATA/helpers.sh'"
assert_true "cliconf installer bash syntax valid" "bash -n '$PROJECT_DIR/conf/cli/install.sh'"
assert_true "herdr menu bash syntax valid" "bash -n '$PROJECT_DIR/conf/herdr/data/herdr-keybindings-menu'"
assert_true "herdr installer bash syntax valid" "bash -n '$PROJECT_DIR/conf/herdr/install.sh'"

for tool in mpv mupdf imv fzf rg fd bat eza zoxide git lazygit gum ai gdu; do
    assert_file_contains "cliconf covers $tool" "$CLICONF_DATA/helpers.sh" "$tool)"
done

if command -v desktop-file-validate &>/dev/null; then
    assert_true "yazi-terminal desktop file valid" "desktop-file-validate '$YAZI_DATA/yazi-terminal.desktop'"
else
    assert_file_contains "yazi-terminal desktop has Exec" "$YAZI_DATA/yazi-terminal.desktop" "^Exec="
    assert_file_contains "yazi-terminal desktop handles directories" "$YAZI_DATA/yazi-terminal.desktop" "inode/directory"
fi

USERCONF_LIB="$PROJECT_DIR/scripts/lib/userconf.sh"
assert_file_exists "user config library exists" "$USERCONF_LIB"
assert_file_contains "user config library installs files from a source" "$USERCONF_LIB" "^install_user_file\(\)"
assert_file_contains "user config library installs content from stdin" "$USERCONF_LIB" "^install_user_content\(\)"
assert_file_contains "user config library manages shell blocks" "$USERCONF_LIB" "^install_shell_block\(\)"
assert_true "user config library leaves caller shell options untouched" \
    "bash -c 'set +e +u; source \"$USERCONF_LIB\"; [[ \$- != *e* && \$- != *u* ]]'"
assert_true "no installer keeps the ad hoc timestamped backup" \
    "! grep -qE 'bak-\\\$\\(date' '$PROJECT_DIR'/conf/*/install.sh"

assert_true "app configurations have one canonical root" \
    "[[ -d '$PROJECT_DIR/conf' ]] && ! find '$PROJECT_DIR' -mindepth 1 -maxdepth 1 -type d -name '*conf' ! -name conf -print -quit | grep -q ."

for installer in "$PROJECT_DIR"/conf/*/install.sh; do
    assert_file_contains "$installer sources the user config library" \
        "$installer" "userconf.sh"
done

HERDR_MENU="$PROJECT_DIR/conf/herdr/data/herdr-keybindings-menu"
assert_file_contains "herdr menu lists the upstream herdr bindings" "$HERDR_MENU" "herdr --default-config"
assert_file_contains "herdr menu supports print mode" "$HERDR_MENU" '[-]-print'
assert_file_contains "herdr menu keeps the upstream display format" "$HERDR_MENU" "→ %s"
assert_file_contains "herdr menu runs only when the herdr process exists" "$HERDR_MENU" "herdr_running"
assert_file_contains "herdr menu checks the herdr server state" "$HERDR_MENU" "herdr status server"
assert_file_contains "herdr menu focuses the herdr window" "$HERDR_MENU" "focuswindow"
assert_file_contains "herdr menu replays keys into herdr" "$HERDR_MENU" "wtype"
assert_file_contains "herdr menu exits cleanly on menu cancel" "$HERDR_MENU" '\|\| exit 0'
assert_file_not_contains "herdr menu has no raw failure suppression" "$HERDR_MENU" '\|\|[[:space:]]*true'
assert_file_contains "herdr installer deploys the menu per user" "$PROJECT_DIR/conf/herdr/install.sh" "herdr-keybindings-menu"
assert_file_contains "herdr installer manages the hyprland binding" "$PROJECT_DIR/conf/herdr/install.sh" "bindings.lua"
assert_file_contains "herdr installer keeps super-ctrl-k on herdr" "$PROJECT_DIR/conf/herdr/install.sh" 'SUPER [+] CTRL [+] K'

if ((UID != 0)); then
    USERCONF_SANDBOX="$(mktemp -d)"
    mkdir -p "$USERCONF_SANDBOX/src" "$USERCONF_SANDBOX/dst"
    printf 'first\n' > "$USERCONF_SANDBOX/src/payload"
    printf 'stale\n' > "$USERCONF_SANDBOX/dst/payload"
    (
        set -euo pipefail
        # shellcheck source=../scripts/lib/userconf.sh
        source "$USERCONF_LIB"
        install_user_file "$USERCONF_SANDBOX/src/payload" "$USERCONF_SANDBOX/dst/payload"
    ) 2>/dev/null
    assert_true "user config library installs the new content" \
        "grep -q '^first$' '$USERCONF_SANDBOX/dst/payload'"
    assert_true "user config library keeps the replaced content in a single slot backup" \
        "[[ -f '$USERCONF_SANDBOX/dst/payload.bak' ]] && ! ls '$USERCONF_SANDBOX/dst/' | grep -qE '\.bak-'"
    (
        set -euo pipefail
        # shellcheck source=../scripts/lib/userconf.sh
        source "$USERCONF_LIB"
        install_user_file "$USERCONF_SANDBOX/src/payload" "$USERCONF_SANDBOX/dst/payload"
        install_user_file "$USERCONF_SANDBOX/src/payload" "$USERCONF_SANDBOX/dst/payload"
    ) 2>/dev/null
    assert_true "user config library never accumulates backups across runs" \
        "[[ \$(ls -1 '$USERCONF_SANDBOX/dst/' | grep -c 'payload') -eq 2 ]]"

    printf '# rc\n\n# >>> omaconf sandbox >>>\nold() { :; }\n# <<< omaconf sandbox <<<\n' > "$USERCONF_SANDBOX/rc"
    (
        set -euo pipefail
        # shellcheck source=../scripts/lib/userconf.sh
        source "$USERCONF_LIB"
        install_shell_block "$USERCONF_SANDBOX/rc" "# >>> omaconf sandbox >>>" "# <<< omaconf sandbox <<<" << 'BLOCK'
new() { :; }
BLOCK
    ) 2>/dev/null
    assert_true "shell block replaces the previous marked range" \
        "! grep -q 'old()' '$USERCONF_SANDBOX/rc'"
    assert_true "shell block writes the new body" \
        "grep -q 'new()' '$USERCONF_SANDBOX/rc'"
    assert_true "shell block writes exactly one marked range" \
        "[[ \$(grep -c '>>> omaconf sandbox >>>' '$USERCONF_SANDBOX/rc') -eq 1 ]]"

    printf '# rc\n\n# >>> omaconf sandbox >>>\nnew() { :; }\n# <<< omaconf sandbox <<<\n' > "$USERCONF_SANDBOX/rc-idem"
    (
        set -euo pipefail
        # shellcheck source=../scripts/lib/userconf.sh
        source "$USERCONF_LIB"
        install_shell_block "$USERCONF_SANDBOX/rc-idem" "# >>> omaconf sandbox >>>" "# <<< omaconf sandbox <<<" << 'BLOCK'
new() { :; }
BLOCK
    ) 2>/dev/null
    assert_true "shell block is idempotent" \
        "cmp -s '$USERCONF_SANDBOX/rc' '$USERCONF_SANDBOX/rc-idem'"
    rm -rf "$USERCONF_SANDBOX"
fi

test_summary
