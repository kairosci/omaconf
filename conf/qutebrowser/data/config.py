from qutebrowser.api import config

config.load_autoconfig()

config.set("downloads.location.directory", "~/Downloads")
config.set("tabs.background", True)
config.set("tabs.show", "multiple")

config.bind("<Ctrl+S>", "download --mhtml")
config.bind("<Ctrl+Q>", "quit")
config.bind("<Ctrl+R>", "reload")
config.bind("<Ctrl+Shift+R>", "reload -f")
config.bind("<Ctrl+W>", "tab-close")
config.bind("<Ctrl+T>", "open -t about:blank")
config.bind("<Ctrl+Shift+T>", "undo")
