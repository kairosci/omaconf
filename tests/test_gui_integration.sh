#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/test_lib.sh"
source "$PROJECT_DIR/scripts/lib/userconf.sh"
SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT
export HOME="$SANDBOX/home" XDG_CONFIG_HOME="$SANDBOX/config" XDG_DATA_HOME="$SANDBOX/data" XDG_STATE_HOME="$SANDBOX/state" XDG_BIN_HOME="$SANDBOX/bin" OMACONF_LANG=en
export OMACONF_I18N_BOOT="$PROJECT_DIR/scripts/lib/i18n-boot.sh"
mkdir -p "$HOME" "$SANDBOX/bin" "$SANDBOX/project with spaces"
export PATH="$SANDBOX/bin:$PATH" GUI_TEST_ARGS="$SANDBOX/arguments"
cat > "$SANDBOX/bin/gsettings" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
[[ "$1" != get ]] || printf "'Sans 11'\n"
MOCK
cat > "$SANDBOX/bin/update-desktop-database" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
exit 0
MOCK
chmod 755 "$SANDBOX/bin/"*

test_section "Graphical Application Integration"
assert_true "Zed native configuration installs" "bash '$PROJECT_DIR/conf/zed/install.sh'"
assert_true "Zed uses native project preferences" "jq -e '.restore_on_startup == \"last_workspace\" and .project_panel.git_status == true and .terminal.shell == \"system\"' '$XDG_CONFIG_HOME/zed/settings.json'"
assert_true "Zed settings installation is idempotent" "before=\$(sha256sum '$XDG_CONFIG_HOME/zed/settings.json'); bash '$PROJECT_DIR/conf/zed/install.sh'; [[ \"\$before\" == \"\$(sha256sum '$XDG_CONFIG_HOME/zed/settings.json')\" ]]"
assert_true "Nautilus native settings install" "bash '$PROJECT_DIR/conf/nautilus/install.sh'"
printf 'mode = "dark"\nbackground = "#101010"\nforeground = "#eeeeee"\naccent = "#abcdef"\nselection = "#303030"\nmuted = "#777777"\nred = "#ff0000"\ngreen = "#00ff00"\nblue = "#0000ff"\nyellow = "#ffff00"\ncyan = "#00ffff"\nmagenta = "#ff00ff"\n' > "$SANDBOX/palette.toml"
export OMACONF_THEME_NAME=test OMACONF_THEME_COLORS="$SANDBOX/palette.toml"
assert_true "Zed palette generates and selects a native theme" "bash '$PROJECT_DIR/conf/zed/theme.sh'"
assert_true "Zed theme uses the palette and preserves editor preferences" "jq -e '.themes[0].appearance == \"dark\" and .themes[0].style[\"editor.background\"] == \"#101010\" and .themes[0].style.syntax.keyword.color == \"#ff00ff\"' '$XDG_CONFIG_HOME/zed/themes/omaconf-test.json' && jq -e '.disable_ai == true and (.theme | startswith(\"Omaconf \"))' '$XDG_CONFIG_HOME/zed/settings.json'"
assert_true "Zed theme synchronization is idempotent" "before=\$(sha256sum '$XDG_CONFIG_HOME/zed/themes/omaconf-test.json' '$XDG_CONFIG_HOME/zed/settings.json'); bash '$PROJECT_DIR/conf/zed/theme.sh'; [[ \"\$before\" == \"\$(sha256sum '$XDG_CONFIG_HOME/zed/themes/omaconf-test.json' '$XDG_CONFIG_HOME/zed/settings.json')\" ]]"
sed -i 's/"dark"/"light"/; s/#101010/#f0f0f0/' "$OMACONF_THEME_COLORS"
assert_true "Zed follows a subsequent light palette" "bash '$PROJECT_DIR/conf/zed/theme.sh' && jq -e '.themes[0].appearance == \"light\" and .themes[0].style[\"editor.background\"] == \"#f0f0f0\"' '$XDG_CONFIG_HOME/zed/themes/omaconf-test.json'"
sed -i 's/#f0f0f0/invalid/' "$OMACONF_THEME_COLORS"
assert_false "invalid Zed palette fails before replacing the theme" "bash '$PROJECT_DIR/conf/zed/theme.sh'"
assert_true "invalid palette preserves the previous Zed theme" "jq -e '.themes[0].style[\"editor.background\"] == \"#f0f0f0\"' '$XDG_CONFIG_HOME/zed/themes/omaconf-test.json'"
unset OMACONF_THEME_NAME OMACONF_THEME_COLORS
printf '[Desktop Entry]\nType=Application\nName=Sample\nExec=/usr/bin/sample --original %%U\n' > "$SANDBOX/sample.desktop"
assert_true "Electron integration preserves packaged launcher arguments" "install_user_electron_launcher '$SANDBOX/sample.desktop' '$SANDBOX/result.desktop'"
assert_file_contains_literal "Electron uses Wayland and native portals" "$SANDBOX/result.desktop" 'Exec=env GTK_USE_PORTAL=1 /usr/bin/sample --ozone-platform=auto --original %U'
if command -v desktop-file-validate >/dev/null; then
    assert_true "generated launcher is a valid desktop entry" "desktop-file-validate '$SANDBOX/result.desktop'"
fi
test_summary
