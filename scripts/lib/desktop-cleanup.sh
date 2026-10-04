#!/usr/bin/env bash

OMACONF_OMARCHY_APPS_DIR="${OMACONF_OMARCHY_APPS_DIR:-/usr/share/omarchy/applications}"
OMACONF_HOMES_ROOT="${OMACONF_HOMES_ROOT:-/home}"
OMACONF_SYSTEM_APPS_DIRS="${OMACONF_SYSTEM_APPS_DIRS:-/usr/share/applications:/usr/local/share/applications}"

_desktop_cleanup_has_cmd() {
    local cmd="$1"
    [[ -n "$cmd" ]] || return 1
    if [[ "$cmd" == /* ]]; then
        [[ -x "$cmd" ]] && return 0
        return 1
    fi
    command -v "$cmd" >/dev/null 2>&1
}

_desktop_cleanup_strip_field_codes() {
    local line="$1"
    printf '%s' "$line" | sed 's/%[a-zA-Z]//g'
}

_desktop_cleanup_first_token() {
    local line="$1" token rest
    line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [[ -n "$line" ]] || return 1
    case "$line" in
        '"'*)
            token="${line#\"}"
            token="${token%%\"*}"
            printf '%s' "$token"
            return 0
            ;;
        "'"*)
            rest="${line#\'}"
            token="${rest%%\'*}"
            printf '%s' "$token"
            return 0
            ;;
    esac
    token="${line%%[[:space:]]*}"
    printf '%s' "$token"
    return 0
}

_desktop_cleanup_unwrap_once() {
    local line="$1" head rest tok
    head="$(_desktop_cleanup_first_token "$line")" || return 1
    case "$(basename "$head")" in
        xdg-terminal-exec|uwsm-app|omarchy-launch-or-focus-tui|omarchy-launch-tui|omarchy-launch-or-focus|env|sudo|pkexec)
            rest="${line#*"${head}"}"
            rest="$(printf '%s' "$rest" | sed -E 's/^[[:space:]]+//; s/^--app-id=[^[:space:]]+[[:space:]]*//; s/^--app-id[[:space:]]+[^[:space:]]+[[:space:]]*//; s/^--title[[:space:]]+[^[:space:]]+[[:space:]]*//; s/^--title=[^[:space:]]+[[:space:]]*//; s/^--dir=[^[:space:]]+[[:space:]]*//; s/^--dir[[:space:]]+[^[:space:]]+[[:space:]]*//; s/^[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]+[[:space:]]*//; s/^-e[[:space:]]+//; s/^--[[:space:]]*//')"
            printf '%s' "$rest"
            return 0
            ;;
        sh|bash|dash|zsh|fish)
            rest="${line#*"${head}"}"
            rest="$(printf '%s' "$rest" | sed -E 's/^[[:space:]]+//')"
            case "$rest" in
                -c*)
                    rest="$(printf '%s' "$rest" | sed -E 's/^-c[[:space:]]+//; s/^--[[:space:]]*//')"
                    case "$rest" in
                        "\""*|"'"*)
                            tok="$(_desktop_cleanup_first_token "$rest")" || return 1
                            printf '%s' "$tok"
                            ;;
                        *)
                            printf '%s' "$rest"
                            ;;
                    esac
                    return 0
                    ;;
            esac
            return 1
            ;;
    esac
    return 1
}

desktop_cleanup_resolve_target() {
    local exec_line="$1" depth=0 unwrapped head inner
    exec_line="$(_desktop_cleanup_strip_field_codes "$exec_line")"
    while [[ $depth -lt 6 ]]; do
        head="$(_desktop_cleanup_first_token "$exec_line")" || return 1
        [[ -n "$head" ]] || return 1
        if unwrapped="$(_desktop_cleanup_unwrap_once "$exec_line")"; then
            exec_line="$unwrapped"
            depth=$((depth + 1))
            continue
        fi
        if [[ "$head" == -* ]]; then
            exec_line="${exec_line#*"${head}"}"
            exec_line="$(printf '%s' "$exec_line" | sed 's/^[[:space:]]*//')"
            depth=$((depth + 1))
            continue
        fi
        if [[ "$head" == *=* && "$head" != /* ]]; then
            exec_line="${exec_line#*"${head}"}"
            exec_line="$(printf '%s' "$exec_line" | sed 's/^[[:space:]]*//')"
            depth=$((depth + 1))
            continue
        fi
        inner="$head"
        printf '%s' "$inner"
        return 0
    done
    return 1
}

desktop_cleanup_exec_missing() {
    local file="$1" tryexec exec_line target
    [[ -f "$file" ]] || return 1
    tryexec="$(sed -n 's/^TryExec=//p' "$file" 2>/dev/null | head -1 | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    if [[ -n "$tryexec" ]]; then
        tryexec="${tryexec%%[[:space:]]*}"
        if ! _desktop_cleanup_has_cmd "$tryexec"; then
            return 0
        fi
    fi
    exec_line="$(sed -n 's/^Exec=//p' "$file" 2>/dev/null | head -1)"
    [[ -n "$exec_line" ]] || return 1
    target="$(desktop_cleanup_resolve_target "$exec_line" 2>/dev/null)" || return 1
    [[ -n "$target" ]] || return 1
    if ! _desktop_cleanup_has_cmd "$target"; then
        return 0
    fi
    return 1
}

_desktop_cleanup_patch_disk_usage() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    if _desktop_cleanup_has_cmd baobab && grep -qE '^Exec=.*(dua|gdu)' "$file"; then
        sed -i -e 's|^Exec=.*|Exec=baobab|' -e 's|^Terminal=.*|Terminal=false|' \
            -e 's|^Icon=.*|Icon=org.gnome.baobab|' "$file" || return 1
        return 0
    fi
    grep -q 'dua' "$file" 2>/dev/null || return 1
    if _desktop_cleanup_has_cmd dua; then
        return 1
    fi
    sed -i 's/dua *i *\//gdu \//g' "$file" 2>/dev/null || return 1
    if grep -q 'dua' "$file" 2>/dev/null; then
        return 1
    fi
    return 0
}

_desktop_cleanup_own() {
    local user="$1" file="$2"
    [[ -n "$user" ]] || return 0
    [[ -e "$file" ]] || return 0
    id -u "$user" >/dev/null 2>&1 || return 0
    chown "$user:$user" "$file" 2>/dev/null || warn "desktop.chown_skipped" "$file"
}

_desktop_cleanup_refresh_dir() {
    local dir="$1" user="${2:-}"
    [[ -d "$dir" ]] || return 0
    command -v update-desktop-database >/dev/null 2>&1 || return 0
    if [[ -n "$user" ]] && command -v sudo >/dev/null 2>&1; then
        if sudo -n -u "$user" update-desktop-database "$dir" 2>/dev/null; then
            return 0
        fi
    fi
    update-desktop-database "$dir" 2>/dev/null || warn "desktop.refresh_skipped"
    _desktop_cleanup_own "$user" "$dir/mimeinfo.cache"
}

desktop_cleanup_file() {
    local file="$1" base
    [[ -f "$file" ]] || return 1
    base="$(basename "$file")"
    case "$base" in
        foot.desktop|footclient.desktop|foot-server.desktop)
            if _desktop_cleanup_has_cmd foot; then
                return 1
            fi
            rm -f "$file" 2>/dev/null || return 1
            printf '%s' "$base"
            return 0
            ;;
        "Disk Usage.desktop")
            if _desktop_cleanup_patch_disk_usage "$file"; then
                printf 'patched:%s' "$base"
                return 2
            fi
            if desktop_cleanup_exec_missing "$file"; then
                rm -f "$file" 2>/dev/null || return 1
                printf '%s' "$base"
                return 0
            fi
            return 1
            ;;
        Docker.desktop)
            if _desktop_cleanup_has_cmd lazydocker; then
                return 1
            fi
            rm -f "$file" 2>/dev/null || return 1
            printf '%s' "$base"
            return 0
            ;;
    esac
    if desktop_cleanup_exec_missing "$file"; then
        rm -f "$file" 2>/dev/null || return 1
        printf '%s' "$base"
        return 0
    fi
    return 1
}

_desktop_cleanup_owned_by_pacman() {
    local file="$1" owner
    command -v pacman >/dev/null 2>&1 || return 0
    owner="$(pacman -Qqo "$file" 2>/dev/null)" || return 1
    [[ -n "$owner" ]] || return 1
    return 0
}

desktop_cleanup_system_file() {
    local file="$1"
    [[ -f "$file" ]] || return 1
    if _desktop_cleanup_owned_by_pacman "$file"; then
        return 1
    fi
    desktop_cleanup_file "$file"
}

_desktop_cleanup_mimeapps() {
    local mimeapps="$1"
    shift
    local removed="$1"
    [[ -f "$mimeapps" ]] || return 1
    [[ -n "$removed" ]] || return 1
    local entry touched=1
    for entry in $removed; do
        [[ -n "$entry" ]] || continue
        if grep -qF "$entry" "$mimeapps" 2>/dev/null; then
            sed -i "s/${entry//\//\\/};//g" "$mimeapps" 2>/dev/null || return 1
            sed -i "s/;${entry//\//\\/}/;/g" "$mimeapps" 2>/dev/null || return 1
            sed -i "s=${entry//\//\\/}==g" "$mimeapps" 2>/dev/null || return 1
            touched=0
        fi
    done
    if [[ $touched -eq 0 ]]; then
        sed -i 's/;;/;/g; s/;$/\n/; s/=$//' "$mimeapps" 2>/dev/null || return 1
        return 0
    fi
    return 1
}

desktop_cleanup_sweep() {
    local omarchy_dir="${OMACONF_OMARCHY_APPS_DIR:-/usr/share/omarchy/applications}"
    local homes_root="${OMACONF_HOMES_ROOT:-/home}"
    local sys_dirs="${OMACONF_SYSTEM_APPS_DIRS:-/usr/share/applications:/usr/local/share/applications}"
    local removed_list="" outcome rc entry _u
    local file user_home mimeapps sys_dir
    local -a _sys_dirs=()
    IFS=':' read -ra _sys_dirs <<< "$sys_dirs"
    for sys_dir in "${_sys_dirs[@]}"; do
        [[ -d "$sys_dir" ]] || continue
        for file in "$sys_dir"/*.desktop; do
            [[ -f "$file" ]] || continue
            outcome=""
            rc=0
            outcome="$(desktop_cleanup_system_file "$file")" || rc=$?
            if [[ $rc -eq 0 ]]; then
                removed_list="$removed_list ${outcome}"
                log "desktop.removed" "$file" 2>/dev/null || printf 'Removed orphan entry: %s\n' "$file"
            elif [[ $rc -eq 2 ]]; then
                log "desktop.patched" "$file" 2>/dev/null || printf 'Repointed entry to replacement: %s\n' "$file"
            fi
            unset outcome
        done
    done
    for file in "$omarchy_dir"/*.desktop; do
        [[ -f "$file" ]] || continue
        outcome=""
        rc=0
        outcome="$(desktop_cleanup_file "$file")" || rc=$?
        if [[ $rc -eq 0 ]]; then
            removed_list="$removed_list ${outcome}"
            log "desktop.removed" "$file" 2>/dev/null || printf 'Removed orphan entry: %s\n' "$file"
        elif [[ $rc -eq 2 ]]; then
            log "desktop.patched" "$file" 2>/dev/null || printf 'Repointed entry to replacement: %s\n' "$file"
        fi
        unset outcome
    done
    local u_home
    for u_home in "$homes_root"/*; do
        [[ -d "$u_home" ]] || continue
        _u="$(basename "$u_home")"
        for file in "$u_home/.local/share/applications"/*.desktop; do
            [[ -f "$file" ]] || continue
            outcome=""
            rc=0
            outcome="$(desktop_cleanup_file "$file")" || rc=$?
            if [[ $rc -eq 0 ]]; then
                removed_list="$removed_list ${outcome}"
                log "desktop.removed" "$file" 2>/dev/null || printf 'Removed orphan entry: %s\n' "$file"
            elif [[ $rc -eq 2 ]]; then
                _desktop_cleanup_own "$_u" "$file"
                log "desktop.patched" "$file" 2>/dev/null || printf 'Repointed entry to replacement: %s\n' "$file"
            fi
            unset outcome
        done
    done
    removed_list="$(printf '%s' "$removed_list" | xargs 2>/dev/null)"
    if [[ -n "$removed_list" ]]; then
        for user_home in "$homes_root"/*; do
            [[ -d "$user_home" ]] || continue
            _u="$(basename "$user_home")"
            for mimeapps in "$user_home/.config/mimeapps.list" "$user_home/.local/share/applications/mimeapps.list"; do
                if _desktop_cleanup_mimeapps "$mimeapps" "$removed_list"; then
                    _desktop_cleanup_own "$_u" "$mimeapps"
                    log "desktop.mime_cleaned" "$_u" 2>/dev/null || printf 'Cleaned stale reference: %s\n' "$_u"
                fi
            done
            if [[ -f "$user_home/.local/share/applications/mimeinfo.cache" ]]; then
                for entry in $removed_list; do
                    [[ "$entry" == patched:* ]] && continue
                    sed -i "/=${entry//\//\\/};/d" "$user_home/.local/share/applications/mimeinfo.cache" 2>/dev/null || warn "desktop.mime_clean_skipped" "$entry"
                    sed -i "s/${entry//\//\\/};//g" "$user_home/.local/share/applications/mimeinfo.cache" 2>/dev/null || warn "desktop.mime_clean_skipped" "$entry"
                done
                _desktop_cleanup_own "$_u" "$user_home/.local/share/applications/mimeinfo.cache"
            fi
        done
    fi
    if [[ "${OMACONF_DESKTOP_SKIP_REFRESH:-0}" == "1" ]]; then
        return 0
    fi
    _desktop_cleanup_refresh_dir "$omarchy_dir"
    for sys_dir in "${_sys_dirs[@]}"; do
        _desktop_cleanup_refresh_dir "$sys_dir"
    done
    for user_home in "$homes_root"/*; do
        [[ -d "$user_home" ]] || continue
        _u="$(basename "$user_home")"
        _desktop_cleanup_refresh_dir "$user_home/.local/share/applications" "$_u"
    done
    if command -v update-mime-database >/dev/null 2>&1; then
        for user_home in "$homes_root"/*; do
            [[ -d "$user_home/.local/share/mime" ]] || continue
            update-mime-database "$user_home/.local/share/mime" 2>/dev/null || warn "desktop.refresh_skipped"
        done
    fi
    if command -v omarchy >/dev/null 2>&1; then
        omarchy menu refresh 2>/dev/null || warn "desktop.refresh_skipped"
    fi
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
    SCRIPT_LIB_DIR="$(cd "$(dirname "$0")" && pwd)"
    if [[ -f "$SCRIPT_LIB_DIR/i18n.sh" ]]; then
        # shellcheck source=/dev/null
        source "$SCRIPT_LIB_DIR/i18n.sh"
        i18n_init >/dev/null 2>&1 || warn "desktop.refresh_skipped"
    else
        log() { printf '%s\n' "$2"; }
        warn() { printf 'Warning: %s\n' "$1" >&2; }
    fi
    desktop_cleanup_sweep
fi
