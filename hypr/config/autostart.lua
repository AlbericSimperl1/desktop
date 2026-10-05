-- Auto-start config
-- if you dont use UWSM add your auto start programs here, otherwise use XDG autostart https://wiki.archlinux.org/title/XDG_Autostart

hl.on("hyprland.start", function()
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("xhost +SI:localuser:root")
    hl.exec_cmd("quickshell -p ~/.config/bar/horizontaal")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hyprctl setcursor MacTahoe-cursors 25")
    hl.exec_cmd("noctalia")
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd("~/.config/hypr/scripts/wallpapers.sh")
    hl.exec_cmd("~/.config/hypr/scripts/ws.py")
end)
