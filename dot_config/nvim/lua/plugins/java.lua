return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      local home = os.getenv("HOME")

      -- 1. Point to the specific SDKMAN Java version used to RUN jdtls itself (Must be >= Java 21).
      -- The mason `jdtls` binary is a Python launcher, so pass the JVM via its
      -- --java-executable flag; prepending `java` to cmd makes it try to load the
      -- launcher script as a main class.
      local jdtls_runtime_java = home .. "/.sdkman/candidates/java/25.0.3-tem/bin/java"

      if opts.cmd then
        table.insert(opts.cmd, "--java-executable=" .. jdtls_runtime_java)
      end

      -- 2. Map other SDKMAN Java environments for your project execution runtimes
      opts.settings = vim.tbl_deep_extend("force", opts.settings or {}, {
        java = {
          configuration = {
            runtimes = {
              {
                name = "JavaSE-17",
                path = home .. "/.sdkman/candidates/java/17.0.20-amzn",
                default = true,
              },
              {
                name = "JavaSE-25",
                path = home .. "/.sdkman/candidates/java/25.0.3-tem",
              },
            },
          },
        },
      })
    end,
  },
}
