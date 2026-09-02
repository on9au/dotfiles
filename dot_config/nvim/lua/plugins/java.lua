-- FIT2099 mandates IntelliJ. For a project with no build file that just means
-- "src/ is the source root, compile it somewhere, run the main class" -- so this
-- mirrors that model rather than introducing Gradle, and keeps nvim and IntelliJ
-- interchangeable on the same checkout.
--
-- Nothing here writes into the repo: jdtls keeps its Eclipse metadata under
-- ~/.cache/nvim/jdtls/<project>/, so there is no .project/.classpath for tutors
-- or markers to trip over. The only artefact is bin/, which is gitignored.

local home = os.getenv("HOME")

-- The unit pins Java 17 Corretto in .sdkmanrc. sdkman's auto-env only fires in an
-- interactive shell that cd'd into the project, so if nvim was launched from
-- anywhere else `javac` would silently be whatever `current` points at (25.0.3).
-- Resolve the JDK from .sdkmanrc instead, so a build always uses the unit's
-- version regardless of how nvim was started.
local function project_jdk(root)
  local rc = vim.fs.joinpath(root, ".sdkmanrc")
  if not vim.uv.fs_stat(rc) then
    return nil
  end
  for _, line in ipairs(vim.fn.readfile(rc)) do
    local version = line:match("^%s*java%s*=%s*(%S+)")
    if version then
      local dir = vim.fs.joinpath(home, ".sdkman/candidates/java", version)
      if vim.uv.fs_stat(dir) then
        return dir
      end
      vim.notify(
        (".sdkmanrc requests java %s but it is not installed (sdk install java %s)"):format(version, version),
        vim.log.levels.WARN
      )
      return nil
    end
  end
end

local function project_root()
  local buf = vim.api.nvim_buf_get_name(0)
  return vim.fs.root(buf ~= "" and buf or vim.uv.cwd(), { ".git", "src" }) or vim.uv.cwd()
end

local function sources(root)
  return vim.fn.glob(vim.fs.joinpath(root, "src", "**", "*.java"), true, true)
end

-- IntelliJ picks the main class from a run configuration; without one, find the
-- single class declaring a main method and reconstruct its fully-qualified name.
local function main_class(root)
  for _, file in ipairs(sources(root)) do
    local text = table.concat(vim.fn.readfile(file), "\n")
    if text:find("static%s+void%s+main%s*%(") then
      local package = text:match("^%s*package%s+([%w%.]+)%s*;") or text:match("\n%s*package%s+([%w%.]+)%s*;")
      local name = vim.fn.fnamemodify(file, ":t:r")
      return package and (package .. "." .. name) or name
    end
  end
end

-- Build (and optionally run) in a terminal, so javac diagnostics are readable
-- rather than swallowed. interactive=false keeps the window open on exit.
local function javac_run(run)
  return function()
    local root = project_root()
    local files = sources(root)
    if #files == 0 then
      return vim.notify("No .java files under " .. vim.fs.joinpath(root, "src"), vim.log.levels.WARN)
    end

    local jdk = project_jdk(root)
    local javac = jdk and vim.fs.joinpath(jdk, "bin", "javac") or "javac"
    local java = jdk and vim.fs.joinpath(jdk, "bin", "java") or "java"

    -- Mirror the jdtls javadoc checks in jdt-javadoc.prefs, so <leader>jb reports
    -- the same gaps the editor does. doclint's `missing` group covers absent
    -- comments and tags; `/protected` limits it to protected-and-above. These are
    -- warnings, so an undocumented API still compiles.
    local parts =
      { vim.fn.shellescape(javac), "-d", "bin", "-encoding", "UTF-8", "-Xdoclint:missing/protected" }
    for _, file in ipairs(files) do
      table.insert(parts, vim.fn.shellescape(file))
    end
    local cmd = table.concat(parts, " ")

    if run then
      local main = main_class(root)
      if not main then
        return vim.notify("No class with a main method found under src/", vim.log.levels.WARN)
      end
      cmd = cmd .. " && " .. vim.fn.shellescape(java) .. " -cp bin " .. vim.fn.shellescape(main)
    end

    vim.cmd("silent! wall")
    Snacks.terminal.open(cmd, { cwd = root, interactive = false, win = { position = "bottom" } })
  end
end

return {
  {
    "mfussenegger/nvim-jdtls",
    opts = function(_, opts)
      -- jdtls itself must run on Java 21+, which is independent of the Java the
      -- *project* targets. The mason `jdtls` binary is a Python launcher, so pass
      -- the JVM via its --java-executable flag; prepending `java` to cmd makes it
      -- try to load the launcher script as a main class.
      if opts.cmd then
        table.insert(opts.cmd, "--java-executable=" .. home .. "/.sdkman/candidates/java/25.0.3-tem/bin/java")
      end

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
          -- With no pom.xml/build.gradle, jdtls falls back to "invisible project"
          -- mode and otherwise has no idea src/ is a source root -- which is why
          -- it reports phantom errors on a perfectly valid file. This is the
          -- equivalent of IntelliJ's "Mark Directory as > Sources Root".
          project = {
            sourcePaths = { "src" },
            outputPath = "bin",
            referencedLibraries = { "lib/**/*.jar" },
          },
          -- The "checks" half of the setup: jdtls is the compiler, so these are
          -- real diagnostics rather than style opinions.
          compile = {
            nullAnalysis = { mode = "automatic" },
          },
          -- Missing javadoc on the public/protected API is a compiler problem in
          -- JDT, but there is no LSP setting to turn it on -- the javadoc options
          -- exist only as Eclipse compiler preferences. Point jdtls at a .prefs
          -- file instead. Equivalent to IntelliJ's "missing javadoc" inspection.
          settings = {
            url = home .. "/.config/nvim/java/jdt-javadoc.prefs",
          },
          completion = {
            importOrder = { "java", "javax", "com", "org" },
          },
          sources = {
            organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
          },
        },
      })
    end,
    keys = {
      { "<leader>j", "", desc = "+java", ft = "java" },
      { "<leader>jb", javac_run(false), desc = "Build (javac -> bin/)", ft = "java" },
      { "<leader>jr", javac_run(true), desc = "Build & Run main class", ft = "java" },
    },
  },

  -- google-java-format in AOSP style: 4-space indent, matching .editorconfig and
  -- IntelliJ's default. Google style would be 2-space and contradict both.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        java = { "google-java-format" },
      },
      formatters = {
        ["google-java-format"] = {
          prepend_args = { "--aosp" },
        },
      },
    },
  },
}
