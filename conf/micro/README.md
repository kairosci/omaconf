# microconf

Micro is the default terminal editor. Its configuration uses native completion and the built-in linter, with ShellCheck, shfmt, Ruff and yamllint available for supported file types. The official plugin channel provides `detectindent`, `jump`, `snippets`, `run` and `editorconfig`; `jump` uses universal-ctags. F4 navigates symbols, F5 runs supported files, F9 starts `make` in the background and F12 runs `make`.

Terminal Code is available for projects that need the larger VS Code extension ecosystem. Micro remains the default editor for shell tools.

Install with `make micro` or `bash conf/micro/install.sh`. `mh` prints the key reference; Ctrl+G opens Micro's current help.

Common editing keys match Zed: Ctrl+S save, Ctrl+F find, Ctrl+Z undo, Ctrl+Y redo, Ctrl+C/X/V copy/cut/paste and Ctrl+Q quit. Ctrl+H opens replace. Omarchy Super shortcuts remain managed by Hyprland.
