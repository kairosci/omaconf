#!/usr/bin/env bash

arch_identity_apply() {
    local root="${1:-}" vendor destination backup
    vendor="$root/usr/lib/os-release"
    destination="$root/etc/os-release"
    backup="$root/var/lib/omaconf/os-identity"
    [[ -r "$vendor" ]] || return 1
    grep -qE '^ID=(arch|"arch")$' "$vendor" || return 1
    [[ ! -d "$destination" ]] || return 1
    if [[ -L "$destination" && "$(readlink "$destination")" == ../usr/lib/os-release ]]; then
        return 0
    fi
    if [[ -e "$destination" && ! -e "$backup/os-release" ]]; then
        install -d -m 700 "$backup" || return 1
        cp -L --preserve=mode,timestamps "$destination" "$backup/os-release" || return 1
        chmod 600 "$backup/os-release" || return 1
    fi
    ln -sfnT ../usr/lib/os-release "$destination" || return 1
}
