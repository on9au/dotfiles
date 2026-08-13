-- Workspace layout -- LAPTOP-ON9AU.
--
-- One output, so there is no monitor pinning to do: every workspace lives on
-- the panel and SUPER + <n> always lands where you are looking.
--
-- Five persistent rather than the desktop's ten. `persistent` is what makes a
-- workspace show in waybar while it is empty, and ten permanently-lit numbers
-- across a 16" bar is most of the space gone to workspaces nobody opened.
-- SUPER + 6..0 still work -- those workspaces are simply created on demand and
-- appear in the bar once something is on them, then disappear again.
--
-- The binds go up to 10 regardless; see binds.lua.
for i = 1, 5 do
    hl.workspace_rule({
        workspace  = tostring(i),
        persistent = true,
    })
end
