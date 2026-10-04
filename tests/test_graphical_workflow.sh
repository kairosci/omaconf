#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/test_lib.sh"

WORKFLOW_SANDBOX=$(mktemp -d)
WORKFLOW_USER=$(id -un)
trap 'rm -rf "$WORKFLOW_SANDBOX"' EXIT
mkdir -p "$WORKFLOW_SANDBOX/home/.config/gtk-3.0" "$WORKFLOW_SANDBOX/home/.config/gtk-4.0"
printf '%s\n' 'label { font-weight: bold; }' > "$WORKFLOW_SANDBOX/home/.config/gtk-3.0/gtk.css"
cat > "$WORKFLOW_SANDBOX/colors.toml" <<'COLORS'
background = "#112233"
foreground = "#eeeeee"
accent = "#88aaff"
selection = "#334455"
COLORS

run_gtk_hook() {
    HOME="$WORKFLOW_SANDBOX/home" XDG_CONFIG_HOME="$WORKFLOW_SANDBOX/home/.config" \
        OMACONF_THEME_COLORS="$WORKFLOW_SANDBOX/colors.toml" bash "$PROJECT_DIR/hooks/theme-set.d/gtk-theme"
}

test_section "Graphical Desktop Workflow"
assert_true "GTK palette hook succeeds with valid colors" "run_gtk_hook"
assert_file_contains_literal "GTK hook preserves existing user CSS" "$WORKFLOW_SANDBOX/home/.config/gtk-3.0/gtk.css" 'label { font-weight: bold; }'
assert_file_contains_literal "GTK 3 uses the supplied palette" "$WORKFLOW_SANDBOX/home/.config/gtk-3.0/omaconf.css" '@define-color theme_bg_color #112233;'
assert_file_contains_literal "GTK 4 uses the supplied accent" "$WORKFLOW_SANDBOX/home/.config/gtk-4.0/omaconf.css" '@define-color accent_bg_color #88aaff;'
assert_file_contains "Geany selects the generated native colorscheme" "$WORKFLOW_SANDBOX/home/.config/geany/geany.conf" '^color_scheme=omaconf.conf$'
assert_file_contains_literal "Geany syntax uses the supplied palette" "$WORKFLOW_SANDBOX/home/.config/geany/colorschemes/omaconf.conf" 'default=#eeeeee;#112233;false;false'
assert_true "GTK hook is idempotent" "before=\$(sha256sum '$WORKFLOW_SANDBOX/home/.config/gtk-3.0/'*.css); run_gtk_hook; after=\$(sha256sum '$WORKFLOW_SANDBOX/home/.config/gtk-3.0/'*.css); [[ \"\$before\" == \"\$after\" ]]"
sed -i 's/#88aaff/invalid/' "$WORKFLOW_SANDBOX/colors.toml"
assert_false "GTK hook rejects invalid colors" "run_gtk_hook"
assert_file_contains_literal "invalid GTK palette leaves the previous style intact" "$WORKFLOW_SANDBOX/home/.config/gtk-3.0/omaconf.css" '@define-color accent_bg_color #88aaff;'

source "$PROJECT_DIR/scripts/lib/desktop-workflow.sh"
# shellcheck disable=SC2329
user_as() {
    shift
    printf '%s\n' "$*" >> "$WORKFLOW_SANDBOX/commands"
}
assert_true "desktop defaults apply with an isolated home" "desktop_workflow_defaults '$WORKFLOW_USER' '$WORKFLOW_SANDBOX/home'"
assert_file_contains_literal "desktop defaults use the graphical directory handler" "$WORKFLOW_SANDBOX/commands" 'xdg-mime default thunar.desktop inode/directory'
assert_file_contains_literal "desktop defaults keep Brave for HTTPS" "$WORKFLOW_SANDBOX/commands" 'xdg-mime default brave-browser.desktop x-scheme-handler/https'
assert_file_contains_literal "text defaults use Geany" "$WORKFLOW_SANDBOX/commands" 'xdg-mime default geany.desktop text/plain'
assert_file_contains_literal "PDF defaults use Papers" "$WORKFLOW_SANDBOX/commands" 'xdg-mime default org.gnome.Papers.desktop application/pdf'
assert_file_contains_literal "image defaults use Loupe" "$WORKFLOW_SANDBOX/commands" 'xdg-mime default org.gnome.Loupe.desktop image/png'
assert_file_contains_literal "media defaults use Celluloid" "$WORKFLOW_SANDBOX/commands" 'xdg-mime default io.github.celluloid_player.Celluloid.desktop video/mp4'
assert_file_contains "Omarchy file manager state records Thunar" "$WORKFLOW_SANDBOX/home/.local/state/omarchy/defaults/file-manager" '^thunar$'

user_as() { return 1; }
assert_false "desktop default failures propagate to callers" "desktop_workflow_defaults '$WORKFLOW_USER' '$WORKFLOW_SANDBOX/home'"
assert_false "preview capture refuses direct session changes" "bash '$PROJECT_DIR/theme-previews/rebuild-previews.sh' fake-theme"

test_summary
