-- Default applications, referenced from binds.lua and rules.lua.
-- Change them here once instead of hunting through the keybindings.

local host_apps = require("host").load("apps")

return {
	terminal = "kitty",
	file_manager = "nautilus",
	launcher = "fuzzel",
	browser = "firefox",

	-- Screenshots land here; hyprshot creates the directory if missing.
	screenshot_dir = os.getenv("HOME") .. "/Pictures/Screenshots",

	-- Spotify, named once because both host autostart files launch it at every
	-- login. Arch packages the client as `spotify-launcher` (a downloader
	-- wrapper, and what spotify-launcher.conf configures); nixpkgs and most
	-- others ship it as plain `spotify`. Resolved at launch rather than
	-- hardcoded, because the wrong name here is not a missing app, it is a
	-- failed unit on every single login.
	--
	-- `exec` so the shell replaces itself and the unit ends up supervising
	-- Spotify rather than a sh wrapping it. uwsm names the unit after argv[0]
	-- all the same, so look for it as app-sh-*, not app-spotify-*.
	music = "sh -c 'command -v spotify-launcher >/dev/null 2>&1 "
		.. "&& exec spotify-launcher || exec spotify'",

	-- Wallpaper shown at login (see autostart.lua). Per-machine, because the
	-- panels are not the same shape -- 16:10 on the laptop, 16:9 on the
	-- desktop -- and the wrong one crops or letterboxes.
	wallpaper = host_apps.wallpaper,
}
