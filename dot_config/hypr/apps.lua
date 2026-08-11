-- Default applications, referenced from binds.lua and rules.lua.
-- Change them here once instead of hunting through the keybindings.

return {
    terminal     = "kitty",
    file_manager = "dolphin",
    launcher     = "fuzzel",
    browser      = "chromium",

    -- Screenshots land here; hyprshot creates the directory if missing.
    screenshot_dir = os.getenv("HOME") .. "/Pictures/Screenshots",

    -- Wallpaper shown at login (see autostart.lua). Native 3840x2160, so it
    -- fits both panels exactly -- the 3840x1080 files in that folder are from
    -- the old dual-1080p setup and will letterbox badly on these screens.
    wallpaper = os.getenv("HOME") .. "/Pictures/Wallpapers/wallhaven-je8p85.jpg",
}
