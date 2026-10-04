# microconf

Micro is the default terminal editor. Its configuration uses native completion and the built-in linter, plus the official plugin channel's `detectindent`, `jump` and `snippets` plugins. `jump` needs universal-ctags. Project commands remain explicit through Micro's command line and the user's shell, avoiding unsupported plugin aliases.

Install with `make micro` or `bash microconf/install.sh`. `mh` prints the key reference; Ctrl+G opens Micro's current help.

Common editing keys match Zed: Ctrl+S save, Ctrl+F find, Ctrl+Z undo, Ctrl+Y redo, Ctrl+C/X/V copy/cut/paste and Ctrl+Q quit. Ctrl+H opens replace. Omarchy Super shortcuts remain managed by Hyprland.
