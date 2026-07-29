-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Copilot's tfidf worker opens a per-project SQLite index at
-- ~/.cache/github-copilot/project-index/<name>.<hash>/local-index.db. Those are
-- created with journal_mode=delete, where a writer takes an exclusive lock that
-- blocks every other connection -- so two nvim instances on the same project make
-- the worker die with "database is locked" (it creates its tables outside the
-- try/catch that would otherwise fall back to an in-memory db). WAL lets readers
-- and a writer coexist. The mode lives in the db header, so this is a one-time
-- conversion per project; the pass below only exists to catch newly created ones.
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  group = vim.api.nvim_create_augroup("copilot_index_wal", { clear = true }),
  callback = function()
    if vim.fn.executable("sqlite3") == 0 then
      return
    end

    local dir = vim.fn.expand("~/.cache/github-copilot/project-index")

    local function convert()
      for _, db in ipairs(vim.fn.glob(dir .. "/*/local-index.db", true, true)) do
        -- A locked db is one another instance is actively using; skip it and let
        -- a later session convert it. -cmd runs before the pragma, hence the order.
        vim.system({ "sqlite3", "-cmd", ".timeout 3000", db, "PRAGMA journal_mode=WAL;" }, { text = true })
      end
    end

    convert()
    -- A project opened for the first time has its db created after startup.
    vim.defer_fn(convert, 30000)
  end,
})

-- lazy-lock.json and lazyvim.json are written by nvim, not by hand, so the
-- chezmoi source goes stale every time plugins or extras change. That drift is
-- not harmless: `chezmoi apply` would then roll the live files *back*, which can
-- silently uninstall extras (e.g. lang.java, taking nvim-jdtls with it). Push the
-- live state into the source instead, which is what `chezmoi re-add` does.
local readd_group = vim.api.nvim_create_augroup("chezmoi_readd_nvim_json", { clear = true })

local function chezmoi_readd(detached)
  if vim.fn.executable("chezmoi") == 0 then
    return
  end

  local cmd = { "chezmoi", "re-add" }
  for _, name in ipairs({ "lazy-lock.json", "lazyvim.json" }) do
    local path = vim.fs.joinpath(vim.fn.stdpath("config"), name)
    if vim.uv.fs_stat(path) then
      table.insert(cmd, path)
    end
  end
  if #cmd == 2 then
    return
  end

  if detached then
    -- At VimLeavePre an async vim.system would be killed before it runs.
    vim.fn.jobstart(cmd, { detach = true })
    return
  end

  vim.system(cmd, { text = true }, function(out)
    if out.code ~= 0 then
      vim.schedule(function()
        vim.notify("chezmoi re-add failed: " .. (out.stderr or ""), vim.log.levels.WARN)
      end)
    end
  end)
end

-- Fires after lazy.nvim finishes install/update/sync/clean/restore, which is
-- when the lockfile has just been rewritten.
vim.api.nvim_create_autocmd("User", {
  pattern = { "LazyInstall", "LazyUpdate", "LazySync", "LazyClean", "LazyRestore" },
  group = readd_group,
  callback = function()
    chezmoi_readd(false)
  end,
})

-- Catch-all: LazyVim rewrites lazyvim.json when extras are toggled and emits no
-- event for it, so sync on exit as well.
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = readd_group,
  callback = function()
    chezmoi_readd(true)
  end,
})
