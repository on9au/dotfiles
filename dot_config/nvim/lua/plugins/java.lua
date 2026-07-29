return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local home = os.getenv("HOME")

      -- 1. Point to the specific SDKMAN Java version used to RUN jdtls itself (Must be >= Java 21)
      -- Replace '21.0.2-tem' with your actual installed SDKMAN version
      local jdtls_runtime_java = home .. "/.sdkman/candidates/java/21.0.2-tem/bin/java"

      if opts.cmd then
        table.insert(opts.cmd, 1, jdtls_runtime_java)
      end

      -- 2. Map other SDKMAN Java environments for your project execution runtimes
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          configuration = {
            runtimes = {
              {
                name = "JavaSE-17",
                path = home .. "/.sdkman/candidates/java/17.0.10-tem",
              },
              {
                name = "JavaSE-21",
                path = home .. "/.sdkman/candidates/java/21.0.2-tem",
                default = true,
              },
            },
          },
        },
      })
    end,
  },
}
