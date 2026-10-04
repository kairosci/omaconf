#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
DEBLOAT_MODULE="$PROJECT_DIR/scripts/modules/10-debloat.sh"
DEFAULTS_MODULE="$PROJECT_DIR/scripts/modules/20-defaults.sh"
THEMING_MODULE="$PROJECT_DIR/scripts/modules/30-theming.sh"

source "$SCRIPT_DIR/test_lib.sh"

test_section "Debloat, Application Parity & Theming"

assert_file_exists "debloat module exists" "$DEBLOAT_MODULE"
assert_file_contains "debloat module defines package removal" "$DEBLOAT_MODULE" "pacman -Rns"
assert_file_contains "debloat module defines IgnorePkg pinning" "$DEBLOAT_MODULE" "IgnorePkg.*MERGED_PINS"
assert_file_contains "debloat module merges pins instead of overwriting" "$DEBLOAT_MODULE" "EXISTING_PINS"
assert_file_contains "debloat module installs persistence hooks" "$DEBLOAT_MODULE" "99-omaconf-persist"
assert_file_contains "debloat removes Neovim" "$DEBLOAT_MODULE" "neovim"
assert_file_contains "debloat removes the Omarchy Neovim package" "$DEBLOAT_MODULE" "omarchy-nvim"
assert_file_contains "debloat module removes the sushi previewer orphan" "$DEBLOAT_MODULE" "sushi"
assert_file_contains "debloat module removes the sushi sourceview dependency" "$DEBLOAT_MODULE" "gtksourceview4"
assert_file_contains "debloat module removes the sushi gtk plugin dependency" "$DEBLOAT_MODULE" "gst-plugin-gtk"
assert_file_exists "no-gtk skill exists" "$PROJECT_DIR/.skills/no-gtk/SKILL.md"
assert_file_contains "no-gtk skill registered in the agent contract" "$PROJECT_DIR/AGENTS.md" "no-gtk"

assert_file_exists "defaults module exists" "$DEFAULTS_MODULE"
assert_file_contains "defaults module configures qutebrowser" "$DEFAULTS_MODULE" "qutebrowser"
assert_file_contains "defaults module configures micro editor" "$DEFAULTS_MODULE" "micro"
assert_file_contains "defaults module installs Micro symbol navigation dependencies" "$DEFAULTS_MODULE" "universal-ctags"
assert_file_contains "defaults module provisions quteconf" "$DEFAULTS_MODULE" "quteconf/install.sh"
assert_file_contains "defaults module configures yazi file manager" "$DEFAULTS_MODULE" "yazi"
assert_file_contains "defaults module configures 7zip archive support" "$DEFAULTS_MODULE" "7zip"
assert_file_contains "defaults module installs Kitty" "$DEFAULTS_MODULE" "pacman -S --noconfirm --needed kitty"
assert_file_contains "defaults module configures imv image viewer" "$DEFAULTS_MODULE" "imv"
assert_file_contains "defaults module configures trash-cli safe delete" "$DEFAULTS_MODULE" "trash-cli"
assert_file_contains "defaults module configures mpv player" "$DEFAULTS_MODULE" "mpv"
assert_file_contains "defaults module configures MuPDF pdf viewer" "$DEFAULTS_MODULE" "mupdf"

assert_file_exists "theming module exists" "$THEMING_MODULE"
assert_file_contains "theming module installs hooks" "$THEMING_MODULE" "hooks/theme-set.d"
assert_file_not_contains "theming module does not set a GTK theme" "$THEMING_MODULE" "gsettings set org.gnome.desktop.interface gtk-theme"
assert_file_contains "theming module propagates color-scheme from the active theme" "$THEMING_MODULE" "gsettings set org.gnome.desktop.interface color-scheme"
assert_file_not_contains "theming module does not write GTK settings" "$THEMING_MODULE" "gtk-settings"
assert_file_contains "theming module routes Qt through the xdgdesktop platform theme" "$THEMING_MODULE" 'QT_QPA_PLATFORMTHEME", "xdgdesktop"'
assert_file_exists "theme preview apply helper exists" "$PROJECT_DIR/theme-previews/apply.sh"
assert_file_contains "theme preview apply creates missing user overlays" "$PROJECT_DIR/theme-previews/apply.sh" 'install -d -m 700'
assert_file_contains "theme preview apply clears selector cache" "$PROJECT_DIR/theme-previews/apply.sh" 'theme-selector'

REBUILD_PREVIEWS="$PROJECT_DIR/theme-previews/rebuild-previews.sh"
assert_file_exists "theme preview rebuild helper exists" "$REBUILD_PREVIEWS"
assert_file_not_contains "rebuild script no longer hardcodes a default theme list" "$REBUILD_PREVIEWS" 'themes=\(last-horizon lupine\)'
assert_file_not_contains "rebuild script no longer special-cases lupine" "$REBUILD_PREVIEWS" "theme.*==.*'lupine'"

PREVIEW_LIB="$PROJECT_DIR/scripts/lib/theme-preview.sh"
assert_file_exists "theme preview normalization library exists" "$PREVIEW_LIB"
assert_file_contains "theme preview library declares the canvas" "$PREVIEW_LIB" "THEME_PREVIEW_CANVAS"
assert_file_contains "theme preview canvas matches the stock theme grid" "$PREVIEW_LIB" "1800x1012"
assert_file_contains "theme preview library keeps the stock backup" "$PREVIEW_LIB" "theme-preview-stock"
assert_file_contains "theme preview library backs the original up" "$PREVIEW_LIB" 'cp -a "\$preview" "\$original"'
assert_file_contains "theme preview library resizes with magick" "$PREVIEW_LIB" "magick"
assert_file_contains "theme preview library installs the result" "$PREVIEW_LIB" "install -m 644"
assert_file_contains "theme preview library requires an alpha channel" "$PREVIEW_LIB" '\[\[ "\$type" == \*Alpha \]\]'
assert_file_contains "theme preview library writes an rgba png" "$PREVIEW_LIB" "PNG32:"
assert_true "theme preview library never forces pixel density units" "! grep -q 'PixelsPerInch' '$PREVIEW_LIB'"
assert_file_contains "theme preview library keeps the overlay store" "$PREVIEW_LIB" "theme-preview-overlay"
assert_file_contains "theme preview library restores stored overlays" "$PREVIEW_LIB" "theme_preview_restore_overlays"
assert_file_contains "theming module sources the preview library" "$THEMING_MODULE" "lib/theme-preview.sh"
assert_file_contains "theming module normalizes preview size" "$THEMING_MODULE" "theme_preview_normalize"
assert_file_contains "theming module deploys the preview library to hooks lib" "$THEMING_MODULE" 'hooks/lib'
assert_file_contains "post-update hook resolves the deployed preview library" "$PROJECT_DIR/hooks/post-update.d/99-omaconf-persist" "lib/theme-preview.sh"
assert_file_contains "post-update hook reapplies preview normalization" "$PROJECT_DIR/hooks/post-update.d/99-omaconf-persist" "theme_preview_normalize"

REBUILD_GEOMETRY="$PROJECT_DIR/theme-previews/rebuild-previews.sh"
assert_file_contains "rebuild script captures Micro" "$REBUILD_GEOMETRY" 'capture_app micro'
assert_file_contains "rebuild script captures btop" "$REBUILD_GEOMETRY" 'capture_app btop'
assert_file_contains "rebuild script builds a paired preview canvas" "$REBUILD_GEOMETRY" 'CANVAS_WIDTH=1800'
assert_file_contains "rebuild script writes the composite as rgba" "$REBUILD_GEOMETRY" 'PNG32:\$output_dir/preview.png'

PREVIEW_APPLY="$PROJECT_DIR/theme-previews/apply.sh"
assert_file_contains "apply helper supports a system scope" "$PREVIEW_APPLY" "SYSTEM_SCOPE"
assert_file_contains "apply helper installs system previews as root" "$PREVIEW_APPLY" 'install -m 644 -o root -g root'
assert_file_contains "apply helper records the overlay for the post-update hook" "$PREVIEW_APPLY" "theme_preview_store_overlay"
assert_file_contains "apply helper refuses an implicit system scope" "$PREVIEW_APPLY" "System scope requires explicit themes"

if command -v magick &>/dev/null; then
    PREVIEW_SANDBOX="$(mktemp -d)"
    mkdir -p "$PREVIEW_SANDBOX/themes/last-horizon" "$PREVIEW_SANDBOX/themes/nord" "$PREVIEW_SANDBOX/themes/lupine" \
        "$PREVIEW_SANDBOX/cache" "$PREVIEW_SANDBOX/store"
    magick -size 2880x1800 xc:red "$PREVIEW_SANDBOX/themes/last-horizon/preview.png"
    magick -size 1800x1012 xc:blue -alpha off "$PREVIEW_SANDBOX/themes/nord/preview.png"
    magick -size 1800x1012 xc:green "$PREVIEW_SANDBOX/store/lupine.png"
    magick -size 2880x1800 xc:yellow "$PREVIEW_SANDBOX/themes/lupine/preview.png"
    (
        set -euo pipefail
        # shellcheck disable=SC2329
        warn() { printf '%s\n' "$1" >&2; }
        # shellcheck disable=SC2329
        log() { :; }
        # shellcheck source=../scripts/lib/theme-preview.sh
        source "$PREVIEW_LIB"
        THEME_PREVIEW_THEMES_ROOT="$PREVIEW_SANDBOX/themes"
        THEME_PREVIEW_BACKUP_DIR="$PREVIEW_SANDBOX/cache"
        THEME_PREVIEW_OVERLAY_STORE="$PREVIEW_SANDBOX/store"
        theme_preview_normalize
    ) 2>/dev/null
    assert_true "theme preview library normalizes an oversized stock preview" \
        "[[ \"\$(identify -format '%wx%h' '$PREVIEW_SANDBOX/themes/last-horizon/preview.png')\" == 1800x1012 ]]"
    assert_true "theme preview library leaves a preview already on the canvas alone" \
        "[[ \"\$(identify -format '%wx%h' '$PREVIEW_SANDBOX/themes/nord/preview.png')\" == 1800x1012 ]]"
    assert_true "theme preview library adds the missing alpha channel" \
        "[[ \"\$(identify -format '%[type]' '$PREVIEW_SANDBOX/themes/nord/preview.png')\" == *Alpha ]]"
    assert_true "theme preview library keeps the stock density at 72" \
        "[[ \"\$(identify -format '%x' '$PREVIEW_SANDBOX/themes/nord/preview.png')\" == 72 ]]"
    assert_true "theme preview library normalizes depth to 8" \
        "[[ \"\$(identify -format '%z' '$PREVIEW_SANDBOX/themes/nord/preview.png')\" == 8 ]]"
    assert_true "theme preview library keeps the stock original as a backup" \
        "[[ -f '$PREVIEW_SANDBOX/cache/last-horizon-2880x1800.png' ]]"
    assert_true "theme preview library restores a stored overlay" \
        "cmp -s '$PREVIEW_SANDBOX/store/lupine.png' '$PREVIEW_SANDBOX/themes/lupine/preview.png'"
    assert_true "theme preview library is idempotent" \
        "before=\$(md5sum '$PREVIEW_SANDBOX'/themes/*/preview.png); source '$PREVIEW_LIB'; THEME_PREVIEW_THEMES_ROOT='$PREVIEW_SANDBOX/themes' THEME_PREVIEW_BACKUP_DIR='$PREVIEW_SANDBOX/cache' THEME_PREVIEW_OVERLAY_STORE='$PREVIEW_SANDBOX/store' theme_preview_normalize; after=\$(md5sum '$PREVIEW_SANDBOX'/themes/*/preview.png); [[ \"\$before\" == \"\$after\" ]]"
    rm -rf "$PREVIEW_SANDBOX"
fi

if command -v pacman &>/dev/null && [[ -f /etc/arch-release ]] && [[ -f /etc/pacman.d/omaconf/ignore-pkgs.list ]]; then
    assert_true "herdr installed" "pacman -Q herdr &>/dev/null"
    assert_true "gum installed" "pacman -Q gum &>/dev/null"
    assert_true "qutebrowser installed" "pacman -Q qutebrowser &>/dev/null"
    assert_true "micro installed" "pacman -Q micro &>/dev/null"
    assert_true "yazi installed" "pacman -Q yazi &>/dev/null"
    assert_true "7zip installed" "pacman -Q 7zip &>/dev/null"
    assert_true "imv installed" "pacman -Q imv &>/dev/null"
    assert_true "mpv installed" "pacman -Q mpv &>/dev/null"
    assert_true "mupdf installed" "pacman -Q mupdf &>/dev/null"
    assert_true "btop installed" "pacman -Q btop &>/dev/null"
    assert_true "capitaine-cursors installed" "pacman -Q capitaine-cursors &>/dev/null"
    assert_true "papirus-icon-theme installed" "pacman -Q papirus-icon-theme &>/dev/null"

    assert_true "kitty terminal installed" "pacman -Q kitty &>/dev/null"
    assert_false "foot terminal removed" "pacman -Q foot &>/dev/null"
    for debloated in chromium brave-origin-bin zathura zathura-pdf-mupdf nautilus yaru-icon-theme system-config-printer totem evince eog dolphin okular gwenview xdg-desktop-portal-kde breeze breeze-gtk haruna kdenlive obs-studio libreoffice-fresh obsidian gnome-disk-utility gnome-themes-extra sushi gtksourceview4 gst-plugin-gtk foot; do
        assert_false "debloat verified: $debloated removed" "pacman -Q '$debloated' &>/dev/null"
    done
    assert_false "docker daemon absent" "command -v dockerd &>/dev/null"
    assert_true "podman installed" "pacman -Q podman &>/dev/null"
fi

if [[ -f /etc/pacman.d/omaconf/ignore-pkgs.list ]]; then
    assert_file_exists "pacman ignore-pkgs.list exists" "/etc/pacman.d/omaconf/ignore-pkgs.list"
    assert_file_contains "pacman.conf has IgnorePkg" "/etc/pacman.conf" "^IgnorePkg"
fi

HOOK_FILE="$PROJECT_DIR/hooks/theme-set.d/folder-color"
assert_file_exists "folder-color hook exists in repo" "$HOOK_FILE"
assert_file_executable "folder-color hook executable" "$HOOK_FILE"

MICRO_HOOK="$PROJECT_DIR/hooks/theme-set.d/micro-theme"
assert_file_exists "micro-theme hook exists in repo" "$MICRO_HOOK"
assert_file_executable "micro-theme hook executable" "$MICRO_HOOK"

PERSIST_PRE="$PROJECT_DIR/hooks/pre-refresh-pacman.d/99-omaconf-persist"
assert_file_exists "pre-refresh persist hook exists in repo" "$PERSIST_PRE"
assert_file_executable "pre-refresh persist hook executable" "$PERSIST_PRE"
assert_file_contains "pre-refresh hook re-merges IgnorePkg" "$PERSIST_PRE" "IgnorePkg"

PERSIST_POST="$PROJECT_DIR/hooks/post-update.d/99-omaconf-persist"
assert_file_exists "post-update persist hook exists in repo" "$PERSIST_POST"
assert_file_executable "post-update persist hook executable" "$PERSIST_POST"
assert_file_contains "post-update hook reapplies yazi default" "$PERSIST_POST" "yazi-terminal.desktop inode/directory"
assert_file_contains "post-update hook reapplies termfilechooser routing" "$PERSIST_POST" "FileChooser=termfilechooser"
assert_file_not_contains "post-update hook does not set a GTK theme" "$PERSIST_POST" 'gtk-theme'
assert_file_contains "post-update hook reapplies color-scheme" "$PERSIST_POST" 'gsettings set org.gnome.desktop.interface color-scheme'
assert_file_contains "post-update hook stops only the gnome portal backend" "$PERSIST_POST" "stop xdg-desktop-portal-gnome.service"
assert_file_contains "post-update hook stops the gtk portal backend" "$PERSIST_POST" "stop xdg-desktop-portal-gtk"
assert_file_contains "post-update hook reloads portal after routing reapply" "$PERSIST_POST" "systemctl --user restart xdg-desktop-portal.service"

assert_file_exists "plugin index exists" "$PROJECT_DIR/plugins/index.json"
assert_file_contains "plugin index references omamp" "$PROJECT_DIR/plugins/index.json" "omamp"

assert_file_exists "zedconf install script exists" "$PROJECT_DIR/zedconf/install.sh"
assert_file_exists "microconf install script exists" "$PROJECT_DIR/microconf/install.sh"
assert_file_exists "microconf settings exists" "$PROJECT_DIR/microconf/data/settings.json"
assert_file_exists "microconf bindings exists" "$PROJECT_DIR/microconf/data/bindings.json"
assert_file_exists "yaziconf install script exists" "$PROJECT_DIR/yaziconf/install.sh"
assert_file_exists "yaziconf yazi.toml template exists" "$PROJECT_DIR/yaziconf/data/yazi.toml"
assert_file_contains "defaults module provisions yaziconf" "$DEFAULTS_MODULE" "yaziconf"
assert_file_contains "defaults module enforces gio file manager default" "$DEFAULTS_MODULE" "gio mime inode/directory"
assert_file_contains "defaults module enforces mimeapps file manager" "$DEFAULTS_MODULE" "mimeapps"
assert_file_contains "defaults module records file-manager state" "$DEFAULTS_MODULE" "defaults/file-manager"
assert_file_contains "defaults module rebinding hypr file manager keys" "$DEFAULTS_MODULE" "omaconf-yazi-fm"
PORTALS_MODULE="$PROJECT_DIR/scripts/modules/22-portals.sh"
assert_file_contains "portals module installs termfilechooser portal" "$PORTALS_MODULE" "xdg-desktop-portal-termfilechooser"
assert_file_contains "portals module routes FileChooser to termfilechooser" "$PORTALS_MODULE" "FileChooser=termfilechooser"
assert_file_contains "portals module masks the gtk portal backend" "$PORTALS_MODULE" "mask xdg-desktop-portal-gtk.service"
assert_file_contains "portals module keeps the gnome portal masked" "$PORTALS_MODULE" "mask xdg-desktop-portal-gnome.service"
assert_file_contains "portals module stops only the stale gnome backend" "$PORTALS_MODULE" "stop xdg-desktop-portal-gnome.service"
assert_file_contains "portals module stops the gtk portal backend" "$PORTALS_MODULE" "stop xdg-desktop-portal-gtk"
assert_file_contains "portals module reloads portal after routing" "$PORTALS_MODULE" "systemctl --user restart xdg-desktop-portal.service"
assert_file_contains "yaziconf template uses current file placeholders" "$PROJECT_DIR/yaziconf/data/yazi.toml" "%s"
assert_file_contains "yaziconf template respects EDITOR with micro fallback" "$PROJECT_DIR/yaziconf/data/yazi.toml" "EDITOR:-micro"
assert_false "yaziconf template has no legacy placeholders" "grep -qF -e '\"\$@\"' -e '\"\$1\"' '$PROJECT_DIR/yaziconf/data/yazi.toml'"

test_icon_mapping() {
    local theme="$1" expected="$2"
    local mapped
    case "$theme" in
        white|flexoki-light|catppuccin-latte|solarized-light) mapped="Papirus" ;;
        *) mapped="Papirus-Dark" ;;
    esac
    [[ "$mapped" == "$expected" ]]
}

assert_true "icon map: everforest -> Papirus-Dark" "test_icon_mapping 'everforest' 'Papirus-Dark'"
assert_true "icon map: vantablack -> Papirus-Dark" "test_icon_mapping 'vantablack' 'Papirus-Dark'"
assert_true "icon map: white -> Papirus" "test_icon_mapping 'white' 'Papirus'"
assert_true "icon map: flexoki-light -> Papirus" "test_icon_mapping 'flexoki-light' 'Papirus'"
assert_true "icon map: catppuccin-latte -> Papirus" "test_icon_mapping 'catppuccin-latte' 'Papirus'"
assert_true "icon map: solarized-light -> Papirus" "test_icon_mapping 'solarized-light' 'Papirus'"
assert_true "icon map: default -> Papirus-Dark" "test_icon_mapping 'default' 'Papirus-Dark'"

test_summary
