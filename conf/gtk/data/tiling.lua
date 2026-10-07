hl.config({
  general = { gaps_in = 0, gaps_out = 0, border_size = 1, layout = "dwindle" },
  decoration = {
    rounding = 0,
    active_opacity = 1,
    inactive_opacity = 1,
    shadow = { enabled = false },
    blur = { enabled = false },
  },
  animations = { enabled = true },
  group = { groupbar = { gradients = false, gradient_rounding = 0 } },
})

hl.curve("omaconfSmooth", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
hl.animation({ leaf = "global", enabled = false })
for _, leaf in ipairs({ "windows", "windowsIn", "windowsOut", "windowsMove", "borderangle" }) do
  hl.animation({ leaf = leaf, enabled = false })
end
hl.animation({ leaf = "border", enabled = true, speed = 1.4, bezier = "omaconfSmooth" })
for _, leaf in ipairs({ "fade", "fadeIn", "fadeLayers", "fadeLayersIn", "fadePopups" }) do
  hl.animation({ leaf = leaf, enabled = true, speed = 1.8, bezier = "omaconfSmooth" })
end
for _, leaf in ipairs({ "fadeOut", "fadeLayersOut" }) do
  hl.animation({ leaf = leaf, enabled = true, speed = 1.4, bezier = "omaconfSmooth" })
end
for _, leaf in ipairs({ "layers", "layersIn", "layersOut", "workspaces", "specialWorkspace" }) do
  hl.animation({ leaf = leaf, enabled = true, speed = 1.8, bezier = "omaconfSmooth", style = "fade" })
end

o.window(".*", {
  tag = "-default-opacity",
  opacity = "1 1",
  rounding = 0,
  no_shadow = true,
  no_blur = true,
})
o.window({ modal = false, tag = "negative:floating-window" }, { tile = true })
