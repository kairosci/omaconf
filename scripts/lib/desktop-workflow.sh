#!/usr/bin/env bash

DESKTOP_WORKFLOW_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DESKTOP_WORKFLOW_PORTALS="${DESKTOP_WORKFLOW_PORTALS:-$DESKTOP_WORKFLOW_LIB_DIR/../../conf/xdg-desktop-portal/data/portals.conf}"

desktop_workflow_defaults() {
    local user="$1" home="$2" mime
    user_as "$user" xdg-settings set default-web-browser brave-browser.desktop || return 1
    for mime in x-scheme-handler/http x-scheme-handler/https text/html; do
        user_as "$user" xdg-mime default brave-browser.desktop "$mime" || return 1
    done
    user_as "$user" xdg-mime default thunar.desktop inode/directory || return 1
    user_as "$user" gio mime inode/directory thunar.desktop || return 1
    user_as "$user" xdg-mime default geany.desktop text/plain text/x-shellscript text/x-python text/markdown || return 1
    user_as "$user" xdg-mime default org.gnome.Papers.desktop application/pdf || return 1
    user_as "$user" xdg-mime default org.gnome.Loupe.desktop image/png image/jpeg image/gif image/webp image/avif || return 1
    user_as "$user" xdg-mime default io.github.celluloid_player.Celluloid.desktop video/mp4 video/x-matroska video/webm audio/mpeg audio/flac audio/ogg || return 1
    install -d -m 700 -o "$user" -g "$user" "$home/.local/state/omarchy/defaults" || return 1
    printf 'thunar\n' > "$home/.local/state/omarchy/defaults/file-manager" || return 1
    chown "$user:$user" "$home/.local/state/omarchy/defaults/file-manager" || return 1
    printf 'geany\n' > "$home/.local/state/omarchy/defaults/editor" || return 1
    printf 'celluloid\n' > "$home/.local/state/omarchy/defaults/media-player" || return 1
    chown "$user:$user" "$home/.local/state/omarchy/defaults/editor" "$home/.local/state/omarchy/defaults/media-player" || return 1
}

desktop_workflow_portals() {
    local user="$1" home="$2" name backend uid
    local config="$home/.config/xdg-desktop-portal"
    install -d -m 700 -o "$user" -g "$user" "$config" || return 1
    for name in portals.conf hyprland-portals.conf; do
        install -m 644 -o "$user" -g "$user" "$DESKTOP_WORKFLOW_PORTALS" "$config/$name" || return 1
    done
    uid=$(id -u "$user") || return 1
    [[ -S "/run/user/$uid/bus" ]] || return 0
    user_as "$user" systemctl --user unmask xdg-desktop-portal-gtk.service || return 1
    for backend in termfilechooser gnome; do
        if user_as "$user" systemctl --user cat "xdg-desktop-portal-$backend.service" >/dev/null 2>&1; then
            user_as "$user" systemctl --user stop "xdg-desktop-portal-$backend.service" || return 1
            user_as "$user" systemctl --user mask "xdg-desktop-portal-$backend.service" || return 1
        fi
    done
    user_as "$user" systemctl --user restart xdg-desktop-portal-gtk.service xdg-desktop-portal.service || return 1
}
