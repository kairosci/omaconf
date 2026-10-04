#!/usr/bin/env bash

set -euo pipefail

log "defaults.browser_install"
if ! pacman -Q brave-bin &>/dev/null; then
    aur_verified_install brave-bin || err "defaults.browser_failed"
fi

log "defaults.browser"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    user_as "$_user" xdg-settings set default-web-browser brave-browser.desktop 2>/dev/null || warn "defaults.browser_skipped_user" "$_user"
done

log "defaults.graphical_apps"
pacman -S --noconfirm --needed geany papers loupe celluloid baobab resources || err "defaults.app_failed" "graphical desktop"

log "defaults.micro_install"
for pkg in micro fzf universal-ctags shellcheck shfmt ruff yamllint; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        pacman -S --noconfirm --needed "$pkg" || err "defaults.micro_dependency_failed" "$pkg"
    fi
done

log "defaults.collaboration_apps"
for pkg in slack-desktop discord; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        aur_verified_install "$pkg" || err "defaults.app_failed" "$pkg"
    fi
done

log "defaults.terminal_code"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    if [[ -x "$PROJECT_DIR/conf/terminal-code/install.sh" ]]; then
        user_as "$_user" bash "$PROJECT_DIR/conf/terminal-code/install.sh" || err "defaults.app_failed" "terminal-code"
    fi
done

log "defaults.editor"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    mkdir -p "$user_home/.local/state/omarchy/defaults"
    printf 'geany\n' > "$user_home/.local/state/omarchy/defaults/editor"
    chown -R "$_user":"$_user" "$user_home/.local/state" 2>/dev/null || warn "defaults.editor_state_failed" "$_user"
    if [[ -x "$PROJECT_DIR/conf/micro/install.sh" ]]; then
        user_as "$_user" bash "$PROJECT_DIR/conf/micro/install.sh" 2>/dev/null || warn "defaults.microconf_skipped" "$_user"
    fi
done

log "defaults.yazi_install"
if ! pacman -Q yazi &>/dev/null; then
    pacman -S --noconfirm --needed yazi
fi

log "defaults.7zip_install"
if ! pacman -Q 7zip &>/dev/null; then
    pacman -S --noconfirm --needed 7zip
fi

log "defaults.kitty_install"
if ! pacman -Q kitty &>/dev/null; then
    pacman -S --noconfirm --needed kitty
fi
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    omarchy_as "$_user" default terminal kitty 2>/dev/null || warn "defaults.terminal_skipped" "$_user"
done

log "defaults.yaziconf"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    if [[ -x "$PROJECT_DIR/conf/yazi/install.sh" ]]; then
        user_as "$_user" bash "$PROJECT_DIR/conf/yazi/install.sh" 2>/dev/null || warn "defaults.yaziconf_skipped" "$_user"
    fi
done

log "defaults.herdrconf"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    if [[ -x "$PROJECT_DIR/conf/herdr/install.sh" ]]; then
        user_as "$_user" bash "$PROJECT_DIR/conf/herdr/install.sh" 2>/dev/null || warn "defaults.herdrconf_skipped" "$_user"
    fi
done

log "defaults.disk_install"
if ! pacman -Q gdu &>/dev/null; then
    pacman -S --noconfirm --needed gdu || warn "defaults.disk_failed" "gdu"
fi

log "defaults.diskconf"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    if [[ -x "$PROJECT_DIR/conf/disk/install.sh" ]]; then
        user_as "$_user" bash "$PROJECT_DIR/conf/disk/install.sh" 2>/dev/null || warn "defaults.diskconf_skipped" "$_user"
    fi
done

log "defaults.trash_install"
if ! pacman -Q trash-cli &>/dev/null; then
    pacman -S --noconfirm --needed trash-cli
fi

log "defaults.imv_install"
if ! pacman -Q imv &>/dev/null; then
    pacman -S --noconfirm --needed imv
fi

log "defaults.mpv_install"
if ! pacman -Q mpv &>/dev/null; then
    pacman -S --noconfirm --needed mpv
fi

log "defaults.pdf_install"
if ! pacman -Q mupdf &>/dev/null; then
    pacman -S --noconfirm --needed mupdf
fi

log "defaults.filemanager"
for pkg in thunar gvfs gvfs-mtp tumbler thunar-archive-plugin file-roller; do
    pacman -S --noconfirm --needed "$pkg" || err "defaults.app_failed" "$pkg"
done
source "$PROJECT_DIR/scripts/lib/desktop-workflow.sh"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    desktop_workflow_defaults "$_user" "$user_home"
done

log "defaults.rebind"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _bindings="$user_home/.config/hypr/bindings.lua"
    if [[ -f "$_bindings" ]] && grep -qE '^-- om(ablot|aconf)-yazi-fm:' "$_bindings"; then
        sed -i \
            -e '/^-- omablot-yazi-fm:/,/^o\.bind("SUPER + ALT + SHIFT + F"/d' \
            -e '/^-- omaconf-yazi-fm:/,/^o\.bind("SUPER + ALT + SHIFT + F"/d' \
            "$_bindings" || warn "defaults.bindings_migration_skipped" "$_user"
        chown "$_user":"$_user" "$_bindings" 2>/dev/null || warn "defaults.bindings_chown" "$_user"
    fi
    if [[ -f "$_bindings" ]] && ! grep -q 'omaconf-thunar-fm' "$_bindings" 2>/dev/null; then
        cat >> "$_bindings" << 'LUAEOF'

-- omaconf-thunar-fm
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "File manager", "thunar")
hl.unbind("SUPER + ALT + SHIFT + F")
o.bind("SUPER + ALT + SHIFT + F", "File manager (cwd)", "thunar \"$(omarchy-cmd-terminal-cwd)\"")
LUAEOF
        chown "$_user":"$_user" "$_bindings" 2>/dev/null || warn "defaults.bindings_chown" "$_user"
    fi
    if [[ -f "$_bindings" ]] && ! grep -q 'omaconf-graphical-apps' "$_bindings"; then
        cat >> "$_bindings" << 'LUAEOF'

-- omaconf-graphical-apps
hl.unbind("SUPER + SHIFT + N")
o.bind("SUPER + SHIFT + N", "Editor", "geany")
hl.unbind("SUPER + CTRL + T")
o.bind("SUPER + CTRL + T", "Activity", "resources")
LUAEOF
        chown "$_user:$_user" "$_bindings"
    fi
    if [[ -f "$_bindings" ]] && ! grep -qF 'o.window("^(geany|' "$_bindings"; then
        cat >> "$_bindings" << 'LUAEOF'
o.window("^(geany|Geany|thunar|Thunar|org.gnome.Papers|org.gnome.Loupe|io.github.celluloid_player.Celluloid|net.nokyan.Resources|org.gnome.baobab|xdg-desktop-portal-gtk)$", { tag = "-default-opacity", opacity = "1 1" })
LUAEOF
        chown "$_user:$_user" "$_bindings"
    fi
    if [[ -f "$_bindings" ]] && ! grep -q 'brave --incognito' "$_bindings" 2>/dev/null; then
        cat >> "$_bindings" << 'LUAEOF'

hl.unbind("SUPER + SHIFT + ALT + B")
o.bind("SUPER + SHIFT + ALT + B", "Private browser", { launch = "brave --incognito" })
LUAEOF
        chown "$_user":"$_user" "$_bindings" 2>/dev/null || warn "defaults.bindings_chown" "$_user"
    fi
done

log "defaults.podman"
for pkg in podman podman-compose podman-docker slirp4netns; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        pacman -S --noconfirm --needed "$pkg" || warn "defaults.podman_failed" "$pkg"
    fi
done
systemctl enable podman.socket 2>/dev/null || warn "defaults.podman_socket_skipped"

log "defaults.btop_install"
if ! pacman -Q btop &>/dev/null; then
    pacman -S --noconfirm --needed btop || warn "defaults.btop_failed"
fi

log "defaults.cursors_install"
if ! pacman -Q capitaine-cursors &>/dev/null; then
    pacman -S --noconfirm --needed capitaine-cursors || warn "defaults.cursors_failed"
fi

log "defaults.icons_install"
if ! pacman -Q papirus-icon-theme &>/dev/null; then
    pacman -S --noconfirm --needed papirus-icon-theme || warn "defaults.icons_failed"
fi

log "defaults.btop_theme"
for user_home in /home/*; do
    [[ -d "$user_home" ]] || continue
    _user=$(basename "$user_home")
    _btop_conf="$user_home/.config/btop/btop.conf"
    if [[ -f "$_btop_conf" ]] && ! grep -q '^color_theme *= *"current"' "$_btop_conf" 2>/dev/null; then
        sed -i 's|^color_theme *= *".*"|color_theme = "current"|' "$_btop_conf" 2>/dev/null || warn "defaults.btop_theme_skipped" "$_user"
        chown "$_user":"$_user" "$_btop_conf" 2>/dev/null || warn "defaults.btop_conf_chown" "$_user"
    fi
done

log "desktop.sweep"
if [[ -f "$PROJECT_DIR/scripts/lib/desktop-cleanup.sh" ]]; then
    # shellcheck source=../desktop-cleanup.sh
    source "$PROJECT_DIR/scripts/lib/desktop-cleanup.sh"
    desktop_cleanup_sweep || warn "desktop.refresh_skipped"
fi
