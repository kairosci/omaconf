#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
source "$SCRIPT_DIR/test_lib.sh"
source "$SCRIPT_DIR/../scripts/lib/os-identity.sh"
SANDBOX=$(mktemp -d)
trap 'rm -rf "$SANDBOX"' EXIT
mkdir -p "$SANDBOX/etc" "$SANDBOX/usr/lib"
printf 'NAME="Arch Linux"\nPRETTY_NAME="Arch Linux"\nID=arch\nLOGO=archlinux-logo\nANSI_COLOR="blue"\n' > "$SANDBOX/usr/lib/os-release"
printf 'NAME="Omarchy"\nID=omarchy\nLOGO=omarchy\nANSI_COLOR="green"\n' > "$SANDBOX/etc/os-release"
vendor_hash=$(sha256sum "$SANDBOX/usr/lib/os-release")
test_section "Native Arch Linux Identity"
assert_true "Arch identity replaces the local override" 'arch_identity_apply "$SANDBOX"'
assert_true "identity uses native Arch metadata" 'grep -q "^ID=arch$" "$SANDBOX/etc/os-release" && grep -q "^PRETTY_NAME=\"Arch Linux\"$" "$SANDBOX/etc/os-release"'
assert_true "identity verifier accepts the reconciled metadata" 'arch_identity_valid "$SANDBOX"'
assert_true "original Omarchy logo and display colors are preserved" 'grep -q "^LOGO=omarchy$" "$SANDBOX/etc/os-release" && grep -q "^ANSI_COLOR=\"green\"$" "$SANDBOX/etc/os-release"'
assert_true "original identity is preserved" 'grep -q "^ID=omarchy$" "$SANDBOX/var/lib/omaconf/os-identity/os-release"'
backup_hash=$(sha256sum "$SANDBOX/var/lib/omaconf/os-identity/os-release")
assert_true "reapplying identity preserves the original backup and vendor data" 'arch_identity_apply "$SANDBOX" && [[ "$backup_hash" == "$(sha256sum "$SANDBOX/var/lib/omaconf/os-identity/os-release")" && "$vendor_hash" == "$(sha256sum "$SANDBOX/usr/lib/os-release")" ]]'
printf 'ID=other\n' > "$SANDBOX/usr/lib/os-release"
assert_false "non Arch vendor identity is rejected" 'arch_identity_apply "$SANDBOX"'
rm "$SANDBOX/usr/lib/os-release"
assert_false "missing vendor metadata is rejected" 'arch_identity_apply "$SANDBOX"'
test_summary
