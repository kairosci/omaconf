---
name: editor-configurations
description: >-
  Procedures for managing native configurations for Zed, Micro, qutebrowser and Yazi in Omarchy.
---

# Editor Configurations

`conf/<app>/` is the single home for application configurations. Each app folder owns its data and exposes one user-scope installer. Every installer uses `scripts/lib/userconf.sh` for atomic installs, backups and marked shell blocks.

## Micro

The Micro installer merges settings, deploys bindings and adds the shell helper. Keep completion native and linting on the built-in linter. The plugin channel may supply symbol navigation, snippets, indentation detection and run/make integration. Do not present the experimental LSP plugin as a mature default.

## qutebrowser

The `conf/qutebrowser` installer deploys `data/config.py` to the user config directory. Preserve qutebrowser defaults unless an override is needed. Check setting names, values and commands against the installed qutebrowser version before adding them.

## Zed

Zed settings use the base JSON, optional Linux overlay and native keymap. Merge user settings with `jq` when available and retain the documented fallback when it is not.

## Yazi

Yazi owns its configuration, theme, terminal desktop entry, directory handler and shell helpers. After a full setup, rerun the `obscure` subproject to regenerate its gate because theming rewrites Yazi configuration.

Install one module through its Make target or installer. `make editors` installs the editor and CLI configurations. The theme target synchronizes Micro colors from the active Omarchy palette.
