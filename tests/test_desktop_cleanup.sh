#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LIB="$PROJECT_DIR/scripts/lib/desktop-cleanup.sh"

source "$SCRIPT_DIR/test_lib.sh"

log() { :; }
warn() { :; }

test_section "Orphan Launcher Entry Sweep"

assert_file_exists "desktop cleanup library exists" "$LIB"
assert_file_executable "desktop cleanup library executable" "$LIB"
assert_true "desktop cleanup library parses" "bash -n '$LIB'"
assert_true "desktop cleanup library has no failure suppression" "! grep -qE '[|][|][[:space:]]*true([^[:alnum:]_]|$)' '$LIB'"
assert_true "desktop cleanup library never exits the sourcing shell" "! grep -qE '^[[:space:]]*exit' '$LIB'"
assert_file_contains "library resolves wrapped executables" "$LIB" "desktop_cleanup_resolve_target"
assert_file_contains "library detects missing executables" "$LIB" "desktop_cleanup_exec_missing"
assert_file_contains "library repoints disk usage to gdu" "$LIB" "gdu"
assert_file_contains "library drops foot without its binary" "$LIB" "foot.desktop"
assert_file_contains "library drops docker without lazydocker" "$LIB" "lazydocker"
assert_file_contains "library refreshes the desktop database" "$LIB" "update-desktop-database"
assert_file_contains "library restores user ownership" "$LIB" "desktop.chown_skipped"

assert_file_contains "debloat module sweeps orphan entries" "$PROJECT_DIR/scripts/lib/modules/10-debloat.sh" "desktop-cleanup.sh"
assert_file_contains "debloat module runs the sweep" "$PROJECT_DIR/scripts/lib/modules/10-debloat.sh" "desktop_cleanup_sweep"
assert_file_contains "defaults module sweeps orphan entries" "$PROJECT_DIR/scripts/lib/modules/20-defaults.sh" "desktop_cleanup_sweep"
assert_file_contains "desktop module installs the cleanup helper" "$PROJECT_DIR/scripts/lib/modules/25-desktop-cleanup.sh" "omaconf-desktop-cleanup"
assert_file_contains "desktop module hooks package removal" "$PROJECT_DIR/scripts/lib/modules/25-desktop-cleanup.sh" "Operation = Remove"
assert_file_contains "desktop module runs the general sweep" "$PROJECT_DIR/scripts/lib/modules/25-desktop-cleanup.sh" "desktop_cleanup_sweep"
assert_file_contains "setup pipeline loads the desktop module" "$PROJECT_DIR/scripts/setup.sh" "25-desktop-cleanup.sh"
assert_file_contains "post-update hook reapplies the entry sweep" "$PROJECT_DIR/hooks/post-update.d/99-omaconf-persist" "omaconf-desktop-cleanup"
assert_file_contains "verify checks foot orphans" "$PROJECT_DIR/scripts/verify.sh" "check.desktop_no_foot"
assert_file_contains "verify validates the disk entry" "$PROJECT_DIR/scripts/verify.sh" "disk_entry_valid"
assert_file_contains "verify checks docker orphans" "$PROJECT_DIR/scripts/verify.sh" "check.desktop_no_docker"
assert_file_contains "verify checks the cleanup hook" "$PROJECT_DIR/scripts/verify.sh" "check.desktop_hook"
assert_file_contains "test runner includes the desktop suite" "$PROJECT_DIR/tests/run-all.sh" "test_desktop_cleanup.sh"

# shellcheck source=../scripts/lib/desktop-cleanup.sh
source "$LIB"

DC_SANDBOX="$(mktemp -d)"
DC_SYS="$DC_SANDBOX/sys"
DC_HOMES="$DC_SANDBOX/homes"
DC_BIN="$DC_SANDBOX/bin"
mkdir -p "$DC_SYS" "$DC_HOMES/tester/.local/share/applications" "$DC_HOMES/tester/.config" "$DC_BIN"
printf '#!/bin/bash\necho fake-gdu\n' > "$DC_BIN/gdu"
chmod +x "$DC_BIN/gdu"

printf '%s\n' '[Desktop Entry]' 'Type=Application' 'TryExec=foot' 'Exec=foot' 'Name=Foot' > "$DC_SYS/foot.desktop"
printf '%s\n' '[Desktop Entry]' 'Version=1.0' 'Name=Disk Usage' 'Exec=xdg-terminal-exec --app-id=TUI.float -e bash -c "dua i /"' 'Type=Application' > "$DC_SYS/Disk Usage.desktop"
printf '%s\n' '[Desktop Entry]' 'Version=1.0' 'Name=Docker' 'Exec=xdg-terminal-exec --app-id=TUI.tile -e omarchy-launch-docker-tui' 'Type=Application' > "$DC_SYS/Docker.desktop"
printf '%s\n' '[Desktop Entry]' 'Name=KeepMe' 'Exec=/usr/bin/true' 'Type=Application' > "$DC_SYS/keep.desktop"
printf '%s\n' '[Desktop Entry]' 'Name=Gone' 'Exec=/nonexistent-omaconf-app-xyz --foo' 'Type=Application' > "$DC_HOMES/tester/.local/share/applications/gone.desktop"
printf '%s\n' '[Default Applications]' 'inode/directory=yazi-terminal.desktop;foot.desktop;' > "$DC_HOMES/tester/.config/mimeapps.list"

export OMACONF_OMARCHY_APPS_DIR="$DC_SYS"
export OMACONF_HOMES_ROOT="$DC_HOMES"
export OMACONF_SYSTEM_APPS_DIRS="$DC_SANDBOX/sysapps"
export OMACONF_DESKTOP_SKIP_REFRESH=1
export PATH="$DC_BIN:/usr/bin:/bin"
mkdir -p "$DC_SANDBOX/sysapps"

assert_true "wrapped dua line resolves to dua" "[[ \"\$(desktop_cleanup_resolve_target 'xdg-terminal-exec --app-id=TUI.float -e bash -c \"dua i /\"')\" == dua ]]"
assert_true "plain binary resolves directly" "[[ \"\$(desktop_cleanup_resolve_target '/usr/bin/true')\" == /usr/bin/true ]]"
assert_true "foot entry is reported missing without its binary" "desktop_cleanup_exec_missing '$DC_SYS/foot.desktop'"
assert_true "valid entry is not reported missing" "! desktop_cleanup_exec_missing '$DC_SYS/keep.desktop'"

desktop_cleanup_sweep

assert_true "foot orphan removed from the system entries" "[[ ! -f '$DC_SYS/foot.desktop' ]]"
assert_true "docker orphan removed without lazydocker" "[[ ! -f '$DC_SYS/Docker.desktop' ]]"
assert_true "disk usage entry kept through the repoint" "[[ -f '$DC_SYS/Disk Usage.desktop' ]]"
if command -v baobab >/dev/null; then
    assert_file_contains "disk usage uses the installed graphical analyzer" "$DC_SYS/Disk Usage.desktop" '^Exec=baobab$'
else
    assert_true "disk usage falls back to the available gdu" "grep -q 'gdu /' '$DC_SYS/Disk Usage.desktop'"
fi
assert_true "disk usage entry no longer references dua" "! grep -q 'dua' '$DC_SYS/Disk Usage.desktop'"
assert_true "valid entry kept" "[[ -f '$DC_SYS/keep.desktop' ]]"
assert_true "user orphan removed" "[[ ! -f '$DC_HOMES/tester/.local/share/applications/gone.desktop' ]]"
assert_true "mimeapps reference cleaned" "! grep -q 'foot.desktop' '$DC_HOMES/tester/.config/mimeapps.list'"
assert_true "mimeapps keeps the valid default" "grep -q 'yazi-terminal.desktop' '$DC_HOMES/tester/.config/mimeapps.list'"

DC_BEFORE="$(md5sum "$DC_SYS"/*.desktop 2>/dev/null)"
desktop_cleanup_sweep
DC_AFTER="$(md5sum "$DC_SYS"/*.desktop 2>/dev/null)"
assert_equal "sweep is idempotent" "$DC_BEFORE" "$DC_AFTER"

printf '%s\n' '[Desktop Entry]' 'Name=AlsoGone' 'TryExec=/nonexistent-omaconf-tryexec' 'Exec=/usr/bin/true' 'Type=Application' > "$DC_HOMES/tester/.local/share/applications/alsogone.desktop"

DC_SYSAPPS="$DC_SANDBOX/sysapps-case"
DC_FAKEBIN="$DC_SANDBOX/fakebin"
mkdir -p "$DC_SYSAPPS" "$DC_FAKEBIN"
printf '%s\n' '[Desktop Entry]' 'Name=ValidUnowned' 'Exec=/usr/bin/true' 'Type=Application' > "$DC_SYSAPPS/valid.desktop"
printf '%s\n' '[Desktop Entry]' 'Name=OrphanUnowned' 'Exec=/nonexistent-omaconf-xyz' 'Type=Application' > "$DC_SYSAPPS/orphan.desktop"
printf '%s\n' '[Desktop Entry]' 'Name=Protected' 'Exec=/nonexistent-omaconf-xyz' 'Type=Application' > "$DC_SYSAPPS/protected.desktop"
printf '%s\n' '#!/bin/bash' 'if [[ "$1" == "-Qqo" && "$2" == *protected.desktop ]]; then echo fakepkg; exit 0; fi' 'exit 1' > "$DC_FAKEBIN/pacman"
chmod +x "$DC_FAKEBIN/pacman"
export PATH="$DC_FAKEBIN:$DC_BIN:/usr/bin:/bin"
assert_true "unowned valid system entry is kept" "! desktop_cleanup_system_file '$DC_SYSAPPS/valid.desktop'"
assert_true "package-owned entry is kept even with missing exec" "! desktop_cleanup_system_file '$DC_SYSAPPS/protected.desktop'"

export OMACONF_SYSTEM_APPS_DIRS="$DC_SYSAPPS"
desktop_cleanup_sweep
assert_true "unowned system orphan removed" "[[ ! -f '$DC_SYSAPPS/orphan.desktop' ]]"
assert_true "unowned valid system entry kept by the sweep" "[[ -f '$DC_SYSAPPS/valid.desktop' ]]"
assert_true "package-owned entry survives the sweep" "[[ -f '$DC_SYSAPPS/protected.desktop' ]]"
export PATH="$DC_BIN:/usr/bin:/bin"

OMACONF_OMARCHY_APPS_DIR="$DC_SYS" OMACONF_HOMES_ROOT="$DC_HOMES" OMACONF_SYSTEM_APPS_DIRS="$DC_SANDBOX/sysapps" OMACONF_DESKTOP_SKIP_REFRESH=1 bash "$LIB"
assert_true "standalone helper removes tryexec orphans" "[[ ! -f '$DC_HOMES/tester/.local/share/applications/alsogone.desktop' ]]"

printf '#!/bin/bash\nexit 0\n' > "$DC_BIN/baobab"
chmod +x "$DC_BIN/baobab"
printf '%s\n' '[Desktop Entry]' 'Type=Application' 'Exec=xdg-terminal-exec gdu /' 'Terminal=true' 'Icon=utilities-terminal' > "$DC_SYS/graphical-disk.desktop"
assert_true "disk launcher migrates to the graphical analyzer" "_desktop_cleanup_patch_disk_usage '$DC_SYS/graphical-disk.desktop'"
assert_file_contains "graphical disk launcher runs Baobab" "$DC_SYS/graphical-disk.desktop" '^Exec=baobab$'
assert_file_contains "graphical disk launcher does not open a terminal" "$DC_SYS/graphical-disk.desktop" '^Terminal=false$'
assert_file_contains "graphical disk launcher uses its application icon" "$DC_SYS/graphical-disk.desktop" '^Icon=org.gnome.baobab$'

rm -rf "$DC_SANDBOX"

test_summary
