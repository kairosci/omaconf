#!/usr/bin/env bash

set -euo pipefail

log "keyring.install"
for pkg in libsecret pass; do
    if ! pacman -Q "$pkg" &>/dev/null; then
        pacman -S --noconfirm --needed "$pkg" || warn "keyring.pkg_failed" "$pkg"
    fi
done

keyring_switch() {
    local backend="$1" user_home user dbus_dir keyring_dir cfg keyring
    case "$backend" in
        keepassxc)
            if ! pacman -Q keepassxc &>/dev/null; then
                pacman -S --noconfirm --needed keepassxc
            fi
            systemctl --global mask gnome-keyring-daemon.service gnome-keyring-daemon.socket 2>/dev/null || warn "keyring.global_mask_skipped"
            ;;
        gnome-keyring)
            systemctl --global unmask gnome-keyring-daemon.service gnome-keyring-daemon.socket 2>/dev/null || warn "keyring.global_mask_skipped"
            ;;
        *)
            err "keyring.backend_invalid" "$backend"
            ;;
    esac

    for user_home in /home/*; do
        [[ -d "$user_home" ]] || continue
        user=$(basename "$user_home")
        dbus_dir="$user_home/.local/share/dbus-1/services"
        install -d -m 700 -o "$user" -g "$user" "$user_home/.local/share/dbus-1" "$dbus_dir"
        keyring_dir="$user_home/.config/python_keyring"
        mkdir -p "$keyring_dir"
        printf '[backend]\ndefault-keyring=keyring.backends.SecretService.Keyring\n' > "$keyring_dir/keyringrc.cfg"
        chmod 644 "$keyring_dir/keyringrc.cfg"

        if [[ $backend == keepassxc ]]; then
            mkdir -p "$dbus_dir" "$user_home/.config/keepassxc"
            mkdir -p "$user_home/.config/autostart"
            for keyring in gnome-keyring-pkcs11.desktop gnome-keyring-secrets.desktop gnome-keyring-ssh.desktop; do
                cat > "$user_home/.config/autostart/$keyring" << 'AUTOEOF'
[Desktop Entry]
Hidden=true
AUTOEOF
                chown "$user":"$user" "$user_home/.config/autostart/$keyring"
            done
            cat > "$dbus_dir/org.freedesktop.secrets.service" << 'DBUSEOF'
[D-BUS Service]
Name=org.freedesktop.secrets
Exec=/usr/bin/keepassxc
DBUSEOF
            cfg="$user_home/.config/keepassxc/keepassxc.ini"
            if [[ ! -f "$cfg" ]]; then
                printf '[FdoSecrets]\nEnabled=true\n' > "$cfg"
            elif grep -q '^\[FdoSecrets\]$' "$cfg"; then
                sed -i '/^\[FdoSecrets\]/,/^\[/ { /^Enabled=/d; }' "$cfg"
                sed -i '/^\[FdoSecrets\]/a Enabled=true' "$cfg"
            else
                printf '\n[FdoSecrets]\nEnabled=true\n' >> "$cfg"
            fi
            chown -R "$user":"$user" "$dbus_dir" "$user_home/.config/keepassxc"
            user_as "$user" systemctl --user mask gnome-keyring-daemon.service gnome-keyring-daemon.socket 2>/dev/null || warn "keyring.user_mask_skipped" "$user"
            user_as "$user" systemctl --user stop gnome-keyring-daemon.service gnome-keyring-daemon.socket 2>/dev/null || warn "keyring.stop_skipped" "$user"
        else
            rm -f "$dbus_dir/org.freedesktop.secrets.service"
            for unit in gnome-keyring-daemon.service gnome-keyring-daemon.socket; do
                unit_mask="$user_home/.config/systemd/user/$unit"
                if [[ -L "$unit_mask" ]] && [[ $(readlink "$unit_mask") == /dev/null ]]; then
                    rm -f "$unit_mask"
                fi
            done
            user_as "$user" systemctl --user unmask gnome-keyring-daemon.service gnome-keyring-daemon.socket 2>/dev/null || warn "keyring.user_mask_skipped" "$user"
            for keyring in gnome-keyring-pkcs11.desktop gnome-keyring-secrets.desktop gnome-keyring-ssh.desktop; do
                rm -f "$user_home/.config/autostart/$keyring"
            done
        fi

        chown -R "$user":"$user" "$keyring_dir"
    done
}

KEYRING_CONFIG=/etc/omaconf/keyring-backend
if [[ -n "${OMACONF_KEYRING_BACKEND:-}" ]]; then
    KEYRING_BACKEND=$OMACONF_KEYRING_BACKEND
elif [[ -f "$KEYRING_CONFIG" ]]; then
    IFS= read -r KEYRING_BACKEND < "$KEYRING_CONFIG"
else
    KEYRING_BACKEND=keepassxc
fi
log "keyring.switch"
keyring_switch "$KEYRING_BACKEND"
mkdir -p "$(dirname "$KEYRING_CONFIG")"
printf '%s\n' "$KEYRING_BACKEND" > "$KEYRING_CONFIG"
chmod 644 "$KEYRING_CONFIG"

log "keyring.pam_cleanup"
for pam_file in /etc/pam.d/sddm /etc/pam.d/sddm-autologin /etc/pam.d/login /etc/pam.d/passwd; do
    if [[ -f "$pam_file" ]] && grep -q 'pam_gnome_keyring' "$pam_file"; then
        sed -i '/pam_gnome_keyring/d' "$pam_file" 2>/dev/null || warn "keyring.pam_sed_skipped" "$pam_file"
    fi
done

if [[ $KEYRING_BACKEND == keepassxc ]]; then
    pkill -x gnome-keyring-daemon 2>/dev/null || warn "keyring.stop_skipped" "daemon"
fi
