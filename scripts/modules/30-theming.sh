#!/usr/bin/env bash

set -euo pipefail

if [[ -f "$PROJECT_DIR/scripts/lib/theme-preview.sh" ]]; then
    # shellcheck source=../lib/theme-preview.sh
    source "$PROJECT_DIR/scripts/lib/theme-preview.sh"
fi

log "theming.desktop"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _uid=$(id -u "$_user" 2>/dev/null) || continue

    if [[ -f "$user_home/.local/state/omarchy/current/theme.name" ]]; then
        _theme_name=$(tr '[:upper:]' '[:lower:]' < "$user_home/.local/state/omarchy/current/theme.name" | tr ' ' '-')
    else
        _theme_name="default"
    fi
    case "$_theme_name" in
        white|flexoki-light|catppuccin-latte|solarized-light)
            _icon_theme="Papirus"; _color_scheme="default" ;;
        *)
            _icon_theme="Papirus-Dark"; _color_scheme="prefer-dark" ;;
    esac

    if [[ -e "/run/user/$_uid/bus" ]]; then
        user_as "$_user" gsettings set org.gnome.desktop.interface icon-theme "$_icon_theme" 2>/dev/null || warn "theming.icon_skipped" "$_user"
        user_as "$_user" gsettings set org.gnome.desktop.interface cursor-theme "capitaine-cursors" 2>/dev/null || warn "theming.cursor_skipped" "$_user"
        user_as "$_user" gsettings set org.gnome.desktop.interface color-scheme "$_color_scheme" 2>/dev/null || warn "theming.cscheme_skipped" "$_user"
    fi

    mkdir -p "$user_home/.icons/default"
    cat > "$user_home/.icons/default/index.theme" << 'EOF'
[Icon Theme]
Name=default
Comment=Fallback cursor theme
Inherits=capitaine-cursors
EOF
    chown -R "$_user":"$_user" "$user_home/.icons" 2>/dev/null || warn "theming.icons_chown" "$_user"

    _hyland="$user_home/.config/hypr/hyprland.lua"
    if [[ -f "$_hyland" ]] && grep -q '^-- omablot cursor env (managed)$' "$_hyland"; then
        sed -i '/^-- omablot cursor env (managed)$/,/^-- end omablot cursor env (managed)$/d' "$_hyland" || warn "theming.cursor_migration_skipped" "$_user"
        chown "$_user":"$_user" "$_hyland" 2>/dev/null || warn "theming.hypr_chown" "$_user"
    fi
    if [[ -f "$_hyland" ]] && ! grep -q 'omaconf cursor env' "$_hyland" 2>/dev/null; then
        cat >> "$_hyland" << 'LUAEOF'

-- omaconf cursor env (managed)
hl.env("XCURSOR_THEME", "capitaine-cursors")
hl.env("HYPRCURSOR_THEME", "capitaine-cursors")
-- end omaconf cursor env (managed)
LUAEOF
        chown "$_user":"$_user" "$_hyland" 2>/dev/null || warn "theming.hypr_chown" "$_user"
    fi
    if [[ -f "$_hyland" ]] && ! grep -q 'omaconf qt env' "$_hyland" 2>/dev/null; then
        cat >> "$_hyland" << 'LUAEOF'

-- omaconf qt env (managed)
hl.env("QT_QPA_PLATFORMTHEME", "xdgdesktop")
-- end omaconf qt env (managed)
LUAEOF
        chown "$_user":"$_user" "$_hyland" 2>/dev/null || warn "theming.hypr_chown" "$_user"
    fi
done

log "theming.preview_size"
if declare -F theme_preview_normalize >/dev/null; then
    theme_preview_normalize || warn "theming.preview_size_skipped"
fi

log "theming.hooks"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _hook_dir="$user_home/.config/omarchy/hooks/theme-set.d"
    _i18n_dir="$user_home/.config/omarchy/hooks/i18n"
    _lib_dir="$user_home/.config/omarchy/hooks/lib"
    mkdir -p "$_hook_dir" "$_i18n_dir/messages" "$_lib_dir"
    for hook_file in "$PROJECT_DIR"/hooks/theme-set.d/*; do
        [[ -f "$hook_file" ]] || continue
        hook_name=$(basename "$hook_file")
        cp "$hook_file" "$_hook_dir/$hook_name"
        chmod +x "$_hook_dir/$hook_name"
        user_as "$_user" bash "$_hook_dir/$hook_name" 2>/dev/null || warn "theming.hook_failed" "$hook_name" "$_user"
    done
    cp "$PROJECT_DIR/scripts/lib/i18n.sh" "$PROJECT_DIR/scripts/lib/i18n-boot.sh" "$_i18n_dir/"
    cp "$PROJECT_DIR"/scripts/lib/messages/*.msg "$_i18n_dir/messages/"
    cp "$PROJECT_DIR/scripts/lib/theme-preview.sh" "$_lib_dir/"
    chmod 644 "$_i18n_dir/i18n.sh" "$_i18n_dir"/messages/*.msg "$_lib_dir/theme-preview.sh"
    chown -R "$_user":"$_user" "$_hook_dir" "$_i18n_dir" "$_lib_dir"
done
