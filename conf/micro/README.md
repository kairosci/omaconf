# microconf

Micro is the default terminal editor. Its configuration uses native completion and the built-in linter, with ShellCheck, shfmt, Ruff and yamllint available for supported file types. The official plugin channel provides `detectindent`, `jump`, `snippets`, `runit` and `editorconfig`; `jump` uses universal-ctags. Use the installed plugins' help for symbol navigation and run commands.

Micro remains the default editor for shell tools.

Install with `make micro` or `bash conf/micro/install.sh`. `mh` prints the key reference; Ctrl+G opens Micro's current help.

Common editing keys match Zed: Ctrl+S save, Ctrl+F find, Ctrl+Z undo, Ctrl+Y redo, Ctrl+C/X/V copy/cut/paste and Ctrl+Q quit. Ctrl+H opens replace. Omarchy Super shortcuts remain managed by Hyprland.
