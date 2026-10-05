local gtk_apps = "^(org\\.gnome\\.(Nautilus|Papers|Loupe|Baobab|FileRoller)|net\\.nokyan\\.Resources|io\\.github\\.celluloid_player\\.Celluloid)$"

o.window({ class = gtk_apps }, {
  tag = "-default-opacity",
  opacity = "1 1",
  rounding = 0,
  no_shadow = true,
  no_blur = true,
  no_anim = true,
})
o.window({ class = gtk_apps, modal = false, tag = "negative:floating-window" }, { tile = true })
