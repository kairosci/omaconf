local animations = {}
local config = {}
hl = {
  config = function(value) config = value end,
  curve = function(_, value)
    for _, point in ipairs(value.points) do
      assert(point[1] >= 0 and point[1] <= 1)
      assert(point[2] >= 0 and point[2] <= 1)
    end
  end,
  animation = function(value) animations[value.leaf] = value end,
}
o = { window = function() end }
for _, leaf in ipairs({ "windowsIn", "windowsOut", "windowsMove", "workspacesIn", "workspacesOut", "specialWorkspaceIn", "specialWorkspaceOut" }) do
  animations[leaf] = { enabled = true, style = "slide" }
end
dofile(arg[1])
assert(config.general.allow_tearing == false)
for _, leaf in ipairs({ "global", "windows", "windowsIn", "windowsOut", "windowsMove", "workspaces", "workspacesIn", "workspacesOut", "specialWorkspace", "specialWorkspaceIn", "specialWorkspaceOut", "borderangle" }) do
  assert(animations[leaf].enabled == false, leaf)
end
for _, leaf in ipairs({ "layers", "layersIn", "layersOut" }) do
  assert(animations[leaf].enabled and animations[leaf].style == "fade", leaf)
end
assert(animations.fadeIn.enabled and animations.fadeOut.enabled)
assert(animations.border.enabled)
