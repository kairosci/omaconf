#!/usr/bin/env bash

arch_identity_valid() {
    local root="${1:-}" vendor destination
    vendor="$root/usr/lib/os-release"
    destination="$root/etc/os-release"
    [[ -r "$vendor" && -r "$destination" ]] || return 1
    grep -qE '^ID=(arch|"arch")$' "$vendor" || return 1
    cmp -s <(sed '/^\(LOGO\|ANSI_COLOR\)=/d' "$vendor") <(sed '/^\(LOGO\|ANSI_COLOR\)=/d' "$destination")
}

arch_identity_apply() {
    local root="${1:-}" vendor destination backup branding staged
    vendor="$root/usr/lib/os-release"
    destination="$root/etc/os-release"
    backup="$root/var/lib/omaconf/os-identity"
    [[ -r "$vendor" ]] || return 1
    grep -qE '^ID=(arch|"arch")$' "$vendor" || return 1
    [[ ! -d "$destination" ]] || return 1
    if [[ -e "$destination" && ! -e "$backup/os-release" ]]; then
        install -d -m 700 "$backup" || return 1
        cp -L --preserve=mode,timestamps "$destination" "$backup/os-release" || return 1
        chmod 600 "$backup/os-release" || return 1
    fi
    branding="$destination"
    [[ -r "$backup/os-release" ]] && branding="$backup/os-release"
    [[ -r "$branding" ]] || branding=/dev/null
    staged=$(mktemp "$root/etc/.os-release.XXXXXX") || return 1
    if ! awk '
        FILENAME == ARGV[1] {
            if (/^(LOGO|ANSI_COLOR)=/) {
                key=$0; sub(/=.*/, "", key); visual[key]=$0
            }
            next
        }
        /^(LOGO|ANSI_COLOR)=/ {
            key=$0; sub(/=.*/, "", key)
            if (key in visual) { print visual[key]; delete visual[key]; next }
        }
        { print }
        END { for (key in visual) print visual[key] }
    ' "$branding" "$vendor" > "$staged"; then
        rm -f "$staged"
        return 1
    fi
    chmod 644 "$staged" || { rm -f "$staged"; return 1; }
    if [[ -f "$destination" && ! -L "$destination" ]] && cmp -s "$staged" "$destination"; then
        rm -f "$staged"
        return 0
    fi
    mv -fT "$staged" "$destination" || { rm -f "$staged"; return 1; }
}
