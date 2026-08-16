-- Mermaid (and d2/plantuml/gnuplot) diagrams rendered inline in markdown.
--
-- diagram.nvim shells out to `mmdc` (pacman: mermaid-cli) to turn a fenced code
-- block into a PNG, then hands the PNG to image.nvim, which draws it with the
-- kitty graphics protocol. Requires kitty (or another graphics-capable term) and
-- ImageMagick; inside tmux it also needs `allow-passthrough on`, which
-- dot_tmux.conf already sets.

-- Standalone diagram files aren't a filetype nvim knows about.
vim.filetype.add({
  extension = {
    mmd = "mermaid",
    mermaid = "mermaid",
  },
})

-- mmdc reads this for the catppuccin-mocha palette; keep in sync with the
-- colorscheme in plugins/catppuccin.lua.
local mermaid_config = vim.fn.expand("~/.config/mermaid/config.json")

return {
  {
    "3rd/image.nvim",
    -- No build step: the default magick_cli processor shells out to ImageMagick
    -- instead of needing the `magick` luarock (magick_rock).
    build = false,
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        -- diagram.nvim drives the diagram rendering; this is for plain image
        -- links (![](foo.png)) in markdown.
        markdown = {
          enabled = true,
          clear_in_insert_mode = true,
          only_render_image_at_cursor = false,
        },
      },
      max_width_window_percentage = 80,
      max_height_window_percentage = 50,
      -- Images are drawn over the terminal grid, so they survive splits/floats
      -- that should be covering them unless we clear on overlap.
      window_overlap_clear_enabled = true,
      editor_only_render_when_focused = true,
      tmux_show_only_in_active_window = true,
    },
  },
  {
    "3rd/diagram.nvim",
    dependencies = { "3rd/image.nvim" },
    ft = { "markdown", "markdown.mdx", "norg" },
    opts = {
      events = {
        render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
        clear_buffer = { "BufLeave" },
      },
      renderer_options = {
        mermaid = {
          -- theme is left unset on purpose: -t would override the "base" theme
          -- the config file selects, discarding the palette below it.
          background = "transparent",
          scale = 3, -- render above 1x so the downscaled image stays sharp
          cli_args = vim.fn.filereadable(mermaid_config) == 1 and { "-c", mermaid_config } or nil,
        },
      },
    },
    keys = {
      {
        "<leader>md",
        function()
          require("diagram").show_diagram_hover()
        end,
        desc = "Diagram at cursor (float)",
        ft = { "markdown", "markdown.mdx", "norg" },
      },
      {
        "<leader>mr",
        function()
          require("diagram").render()
        end,
        desc = "Re-render diagrams",
        ft = { "markdown", "markdown.mdx", "norg" },
      },
      {
        "<leader>mc",
        function()
          require("diagram").clear()
        end,
        desc = "Clear diagrams",
        ft = { "markdown", "markdown.mdx", "norg" },
      },
    },
  },
  -- Syntax highlighting for the fenced blocks and for standalone .mmd files.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "mermaid" } },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>m", group = "mermaid/diagram", icon = "󰙅 " },
      },
    },
  },
}
