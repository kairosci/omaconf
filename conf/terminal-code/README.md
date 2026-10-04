# Terminal Code

Terminal Code (`tode`) opens a VS Code workspace rendered inside Kitty. It uses the Kitty graphics protocol and embeds Electron through terminal-browser. Run `tode` from a project directory or pass a project path.

The installer is downloaded from the upstream `tode.sh` endpoint and checks the SHA256 of its application archive. The upstream installer is not version-pinned, so each setup installs the current release. It installs per user under `~/.local` and requires the Chromium and Electron shared libraries provided by Arch packages.

Micro remains the default editor for shell tools. Terminal Code is the full project IDE. Some keyboard shortcuts can conflict with Kitty; run `tode --shortcut-setup` once after installation to resolve them.
