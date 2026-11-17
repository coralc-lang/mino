-- Animations — snappy

hl.config({
  animations = {
    enabled = true,
  },
})

hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
hl.curve("easeOut", { type = "bezier", points = { { 0.22, 1 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })

hl.animation({ leaf = "windows", enabled = true, speed = 4, bezier = "quick", style = "slide" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "quick", style = "slide" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "easeOut", style = "popin 80%" })
hl.animation({ leaf = "border", enabled = true, speed = 4, bezier = "linear" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 6, bezier = "linear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "quick" })
hl.animation({ leaf = "layers", enabled = true, speed = 3, bezier = "quick", style = "slide" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 3, bezier = "quick", style = "slide" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 2, bezier = "easeOut", style = "fade" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4, bezier = "quick", style = "slide" })
hl.animation({ leaf = "workspacesIn", enabled = true, speed = 4, bezier = "quick", style = "slide" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 3, bezier = "easeOut", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn", enabled = true, speed = 3, bezier = "quick", style = "slide top" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 3, bezier = "quick", style = "slide bottom" })
