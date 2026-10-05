#!/usr/bin/env bash
set -euo pipefail

source "$PROJECT_DIR/scripts/lib/os-identity.sh"
log "identity.arch"
arch_identity_apply || err "identity.failed"
install -D -m 644 "$PROJECT_DIR/scripts/lib/os-identity.sh" /usr/local/lib/omaconf/os-identity.sh
