# Brave

Setup automatically runs `install.sh` and installs `data/brave-flags.conf` at the native XDG config path read by the Arch Brave launcher. Browser profiles remain in Brave's existing user directory.

The privileged setup stage creates the protected managed-policy directory and applies the current desktop background color through Omarchy's packaged browser-policy helper. The color scheme follows the system; first setup defaults to dark. Running Brave instances refresh platform policies without opening a new window or editing their profile files.
