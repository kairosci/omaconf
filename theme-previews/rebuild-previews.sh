#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
[[ "${OMACONF_APPLY_PIPELINE:-0}" == 1 ]] || { printf 'Run preview regeneration through the setup pipeline.\n' >&2; exit 1; }
(($#)) || { printf 'Usage: %s <theme> [theme...]\n' "${0##*/}" >&2; exit 2; }
themes=("$@")
for dependency in awk hyprctl identify jq magick grim setsid dbus-run-session geany thunar; do
    command -v "$dependency" >/dev/null || { printf 'Required command is missing: %s\n' "$dependency" >&2; exit 1; }
done
for theme in "${themes[@]}"; do
    [[ "$theme" =~ ^[a-z0-9-]+$ && -r "/usr/share/omarchy/themes/$theme/colors.toml" ]] || {
        printf 'Invalid or missing theme: %s\n' "$theme" >&2
        exit 2
    }
done

GEANY_PID=""
THUNAR_PID=""
CAPTURE_WORKSPACE=""
ORIGINAL_WORKSPACE="$(hyprctl -j activeworkspace | jq -er '.id')"
ARTIFACTS_DIR="$(mktemp -d "${TMPDIR:-/tmp}/omaconf-preview.XXXXXX")"
CANVAS_WIDTH=1800
CANVAS_HEIGHT=1012

stop_capture_process() {
    local pid="$1" status
    if kill -0 "$pid" 2>/dev/null; then kill -- "-$pid" || return 1; fi
    if wait "$pid"; then return 0; else status=$?; fi
    [[ "$status" == 143 ]] || { printf 'Capture process exited with status %s\n' "$status" >&2; return 1; }
}
focus_workspace() {
    hyprctl dispatch "hl.dsp.focus({ workspace = \"$1\" })"
}
cleanup() {
    local status=$?
    trap - EXIT INT TERM
    if [[ -n "$GEANY_PID" ]]; then stop_capture_process "$GEANY_PID" || status=1; fi
    if [[ -n "$THUNAR_PID" ]]; then stop_capture_process "$THUNAR_PID" || status=1; fi
    if [[ -n "$CAPTURE_WORKSPACE" ]]; then focus_workspace "$ORIGINAL_WORKSPACE" || status=1; fi
    rm -rf -- "$ARTIFACTS_DIR" || status=1
    exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

for candidate in {90..999}; do
    if ! hyprctl -j workspaces | jq -e --argjson id "$candidate" '.[] | select(.id == $id)' >/dev/null; then
        CAPTURE_WORKSPACE="$candidate"
        break
    fi
done
[[ -n "$CAPTURE_WORKSPACE" ]] || { printf 'No free capture workspace is available.\n' >&2; exit 1; }
mkdir -p "$ARTIFACTS_DIR/dbus-services"
cp /usr/share/dbus-1/services/org.xfce.Xfconf.service "$ARTIFACTS_DIR/dbus-services/"
cat > "$ARTIFACTS_DIR/session.conf" <<EOF_BUS
<busconfig>
  <type>session</type>
  <listen>unix:tmpdir=/tmp</listen>
  <auth>EXTERNAL</auth>
  <servicedir>$ARTIFACTS_DIR/dbus-services</servicedir>
  <policy context="default">
    <allow own="*"/>
    <allow send_destination="*"/>
    <allow receive_sender="*"/>
  </policy>
</busconfig>
EOF_BUS
mkdir -p "$ARTIFACTS_DIR/Files/Documents" "$ARTIFACTS_DIR/Files/Pictures" "$ARTIFACTS_DIR/Files/Projects"
cat > "$ARTIFACTS_DIR/Files/Projects/sample.lua" <<'LUA'
local M = {}

function M.sorted_unique(items)
    local seen = {}
    local result = {}
    for _, item in ipairs(items) do
        if not seen[item] then
            seen[item] = true
            result[#result + 1] = item
        end
    end
    table.sort(result)
    return result
end

return M
LUA

capture_app() {
    local app="$1" client="" geometry
    for _ in {1..100}; do
        client="$(hyprctl -j clients | jq -c --arg app "$app" --argjson workspace "$CAPTURE_WORKSPACE" \
            '.[] | select((.class | ascii_downcase) == $app and .workspace.id == $workspace)')"
        [[ -n "$client" ]] && break
        sleep 0.1
    done
    [[ -n "$client" ]] || { printf '%s window did not appear\n' "$app" >&2; return 1; }
    geometry=$(jq -er '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' <<< "$client")
    grim -g "$geometry" "$ARTIFACTS_DIR/$app.png"
}

for theme in "${themes[@]}"; do
    printf 'Capturing Geany and Thunar for %s\n' "$theme"
    palette="/usr/share/omarchy/themes/$theme/colors.toml"
    config="$ARTIFACTS_DIR/config-$theme"
    XDG_CONFIG_HOME="$config" OMACONF_THEME_COLORS="$palette" bash "$PROJECT_DIR/hooks/theme-set.d/gtk-theme"
    mode=$(awk -F '"' '/^mode[[:space:]]*=/ { print $2; exit }' "$palette")
    if [[ "$mode" == light ]]; then gtk_theme=Adwaita; icons=Papirus; else gtk_theme=Adwaita-dark; icons=Papirus-Dark; fi
    printf '[Settings]\ngtk-theme-name=%s\ngtk-icon-theme-name=%s\ngtk-cursor-theme-name=capitaine-cursors\n' "$gtk_theme" "$icons" > "$config/gtk-3.0/settings.ini"
    focus_workspace "$CAPTURE_WORKSPACE"
    setsid env XDG_CONFIG_HOME="$config" XDG_DATA_HOME="$config/data" XDG_CACHE_HOME="$config/cache" \
        GIO_USE_VFS=local GSETTINGS_BACKEND=memory NO_AT_BRIDGE=1 GTK_USE_PORTAL=0 GTK_THEME="$gtk_theme" \
        dbus-run-session --config-file "$ARTIFACTS_DIR/session.conf" -- geany --new-instance --no-session "$ARTIFACTS_DIR/Files/Projects/sample.lua" &
    GEANY_PID=$!
    sleep 0.5
    setsid env XDG_CONFIG_HOME="$config" XDG_DATA_HOME="$config/data" XDG_CACHE_HOME="$config/cache" \
        GIO_USE_VFS=local GSETTINGS_BACKEND=memory NO_AT_BRIDGE=1 GTK_USE_PORTAL=0 GTK_THEME="$gtk_theme" \
        dbus-run-session --config-file "$ARTIFACTS_DIR/session.conf" -- thunar --window "$ARTIFACTS_DIR/Files" &
    THUNAR_PID=$!
    sleep 2
    capture_app geany
    capture_app thunar
    stop_capture_process "$GEANY_PID"
    GEANY_PID=""
    stop_capture_process "$THUNAR_PID"
    THUNAR_PID=""
    output_dir="$SCRIPT_DIR/$theme"
    mkdir -p "$output_dir"
    background=$(awk -F '"' '/^background[[:space:]]*=/ { print $2; exit }' "$palette")
    margin=$((CANVAS_WIDTH * 3 / 100))
    gap=$((CANVAS_WIDTH * 2 / 100))
    tile_width=$(((CANVAS_WIDTH - margin * 2 - gap) / 2))
    tile_height=$((CANVAS_HEIGHT - margin * 2))
    magick "$ARTIFACTS_DIR/geany.png" -resize "${tile_width}x${tile_height}" "$ARTIFACTS_DIR/geany-tile.png"
    magick "$ARTIFACTS_DIR/thunar.png" -resize "${tile_width}x${tile_height}" "$ARTIFACTS_DIR/thunar-tile.png"
    magick -size "${CANVAS_WIDTH}x${CANVAS_HEIGHT}" "xc:$background" \
        "$ARTIFACTS_DIR/geany-tile.png" -geometry "+$margin+$margin" -composite \
        "$ARTIFACTS_DIR/thunar-tile.png" -geometry "+$((margin + tile_width + gap))+$margin" -composite \
        -depth 8 -density 72 "PNG32:$output_dir/preview.png"
done
source "$PROJECT_DIR/scripts/lib/theme-preview.sh"
for theme in "${themes[@]}"; do theme_preview_normalize_file "$SCRIPT_DIR/$theme/preview.png"; done
printf 'Rebuilt %s preview(s).\n' "${#themes[@]}"
