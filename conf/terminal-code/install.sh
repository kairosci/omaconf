#!/usr/bin/env bash

set -euo pipefail

bin_home="${XDG_BIN_HOME:-$HOME/.local/bin}"
if [[ "${TODE_FORCE_INSTALL:-0}" != 1 && -x "$bin_home/tode" ]]; then
    exit 0
fi

tmp_dir=$(mktemp -d)
trap 'rm -rf "$tmp_dir"' EXIT

curl --fail --location --silent --show-error https://tode.sh/install --output "$tmp_dir/install.sh"
bash -n "$tmp_dir/install.sh"
bash "$tmp_dir/install.sh"
