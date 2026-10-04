# Application configurations

Every per-application configuration lives under this directory. Configuration installers use `scripts/lib/userconf.sh`; Terminal Code uses its upstream binary installer.

Applications: `cli`, `disk`, `herdr`, `micro`, `terminal-code` and `zed`.

Brave owns its native launcher flags in `brave/data/brave-flags.conf`; its existing user profile is retained. Setup automatically executes every `conf/*/install.sh` in each user's environment, so app installers do not require individual stage registrations.
