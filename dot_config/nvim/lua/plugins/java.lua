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

-- nvim applies .editorconfig itself and records what it applied in
-- b:editorconfig, so read the property rather than 'shiftwidth' -- shiftwidth is
-- 2 by LazyVim default and cannot tell "the project asked for 2" from "nobody
-- asked". Only properties nvim understands land there, so a file with no
-- indent_size simply reads as absent and keeps Google style.
local warned = {}

local function warn_once(key, message)
  if not warned[key] then
    warned[key] = true
    vim.notify(message, vim.log.levels.WARN)
  end
end

--- Extra google-java-format args implied by the buffer's .editorconfig.
--- @param bufnr integer
--- @return string[]
local function gjf_style(bufnr)
  local editorconfig = vim.b[bufnr].editorconfig
  if type(editorconfig) ~= "table" then
    return {}
  end

  if editorconfig.indent_style == "tab" then
    warn_once("tab", ".editorconfig asks for tabs; google-java-format only emits spaces")
    return {}
  end

  local size = tonumber(editorconfig.indent_size) or tonumber(editorconfig.tab_width)
  if size == 4 then
    return { "--aosp" }
  end
  if size and size ~= 2 then
    warn_once("size:" .. size, ("google-java-format has no indent_size %d; using Google style (2)"):format(size))
  end
  return {}
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
          -- Formatting belongs to conform (google-java-format, below). Left on,
          -- jdtls is a second formatter that LazyVim falls back to whenever
          -- conform has nothing available, and it reformats to Eclipse defaults
          -- at a width taken from 'shiftwidth' -- which looks exactly like a
          -- successful google-java-format run and is not one. Disabled, jdtls
          -- still answers a formatting request but returns no edits, so the
          -- fallback becomes a no-op instead of the wrong style.
          format = { enabled = false },
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

  -- The formatter is a hard dependency now that jdtls no longer formats: without
  -- it a java buffer has no working formatter at all, which is the intended
  -- failure -- a save that visibly does nothing, rather than one that quietly
  -- writes the wrong style. `:LazyFormatInfo` names the formatter in use.
  { "mason-org/mason.nvim", opts = { ensure_installed = { "google-java-format" } } },

  -- google-java-format in true Google style: 2-space indent, 100 columns,
  -- Google's import order. Formats on save via LazyVim's autoformat.
  --
  -- google-java-format has exactly two indent widths -- Google style (2) and
  -- --aosp (4) -- and no flag for anything else. A project .editorconfig is the
  -- stronger signal where one exists, since it is checked into the repo and
  -- IntelliJ obeys it too, so indent_size decides which of the two is used.
  -- Anything gjf cannot express warns once per session instead of silently
  -- formatting against the project's own stated config.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- lsp_format = "never" is the same guard as `format.enabled = false` on
        -- the jdtls side, for the path where conform is called directly.
        java = { "google-java-format", lsp_format = "never" },
      },
      formatters = {
        ["google-java-format"] = function(bufnr)
          return { prepend_args = gjf_style(bufnr) }
        end,
      },
    },
  },
}
