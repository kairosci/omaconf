hl.config({
  general = { gaps_in = 0, gaps_out = 0, border_size = 1, layout = "dwindle" },
  decoration = {
    rounding = 0,
    active_opacity = 1,
    inactive_opacity = 1,
    shadow = { enabled = false },
    blur = { enabled = false },
  },
  animations = { enabled = false },
  group = { groupbar = { gradients = false, gradient_rounding = 0 } },
})

o.window(".*", {
  tag = "-default-opacity",
  opacity = "1 1",
  rounding = 0,
  no_shadow = true,
  no_blur = true,
  no_anim = true,
})
o.window({ modal = false, tag = "negative:floating-window" }, { tile = true })
