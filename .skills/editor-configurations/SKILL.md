---
name: editor-configurations
description: >-
  Procedures for managing Geany, Zed, Micro and Brave configurations in Omarchy.
---

# Editor Configurations

`conf/<app>/` is the single home for application configurations. Each app folder owns its data and exposes one user-scope installer. Every installer uses `scripts/lib/userconf.sh` for atomic installs, backups and marked shell blocks.

## Geany

Geany is the graphical editor default. The GTK theme hook generates its native colorscheme from the active Omarchy palette and changes only the color scheme setting in existing configuration. Common editing shortcuts remain native. Micro remains an optional terminal tool. Yazi is retired.

## Micro

The Micro installer merges settings, deploys bindings and adds the shell helper. Keep completion native and linting on the built-in linter. The plugin channel may supply symbol navigation, snippets, indentation detection and run/make integration. Do not present the experimental LSP plugin as a mature default.

## Zed

Zed settings use the base JSON, optional Linux overlay and native keymap. Merge user settings with `jq` when available and retain the documented fallback when it is not.

Install one module through its Make target or installer. `make editors` installs the editor and CLI configurations. The theme target synchronizes Micro colors from the active Omarchy palette.

The setup stage discovers every `conf/*/install.sh` automatically and executes it inside each real user session before theme hooks. A new app config directory must provide an installer using `userconf.sh`; never edit browser profile databases or overwrite active browser preferences. Brave's launcher reads its native flags file, while its existing profiles remain in the standard user config directory.
