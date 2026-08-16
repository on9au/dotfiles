return {
  {
    "3rd/diagram.nvim",
    dependencies = { "3rd/image.nvim" },
    opts = {
      renderer_options = {
        mermaid = {
          theme = "dark", -- or "default", "forest", "neutral"
        },
      },
    },
  },
}
