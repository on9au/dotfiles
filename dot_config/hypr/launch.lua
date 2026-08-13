-- Helpers for starting programs with the session, shared by autostart.lua and
-- the per-host autostart files in hosts/<host>/.
--
-- Everything goes through `uwsm app`, which puts each program in its own
-- systemd user unit. That means `systemctl --user` can see and restart them,
-- and they get cleaned up properly on logout. It works whether or not the
-- session itself was launched via uwsm.

local M = {}

---Launch a program in its own systemd unit.
---@param cmd string
function M.app(cmd)
    hl.exec_cmd("uwsm app -- " .. cmd)
end

---Launch a program and place it on a workspace.
---
---The rule is attached to this launch only, so it does not follow the app
---around: opening a second terminal later still lands wherever you are, which
---a `hl.window_rule` matching on class would not.
---
---`silent` puts the window on the workspace without switching to it, so
---startup does not shuffle you between workspaces while things come up.
---@param cmd string
---@param workspace string|number
function M.app_on(cmd, workspace)
    hl.exec_cmd("uwsm app -- " .. cmd, { workspace = workspace .. " silent" })
end

return M
