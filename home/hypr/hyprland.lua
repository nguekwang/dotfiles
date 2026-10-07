local border_size = 1
local main  = "SUPER"
local terminal = "foot"
-- Chrome is the default browser because password and passkey sync to a Google
-- account is a Chrome feature. qutebrowser stays installed and keeps its own
-- binding below, for the keyboard-driven browsing it is better at.
local browser  = "google-chrome-stable"
local browser_alt = "qutebrowser"
local editor   = "nvim"

hl.on("hyprland.start", function ()
    -- Hand the session variables (WAYLAND_DISPLAY, HYPRLAND_INSTANCE_SIGNATURE,
    -- the fcitx IM variables) to the systemd user manager and the D-Bus
    -- activation environment before anything is spawned, or portal-launched
    -- and D-Bus-activated apps start without them and stall for seconds.
    hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
    hl.exec_cmd("dbus-update-activation-environment --systemd --all")
    hl.exec_cmd("waybar")
    hl.exec_cmd("mako")
    hl.exec_cmd("foot --server")
    hl.exec_cmd("fcitx5 -d")
    -- Chrome stays running in the background from login (needed for
    -- `claude --chrome` and for password/passkey sync), the same way
    -- `foot --server` does.
    hl.exec_cmd(browser)
    -- qutebrowser stays running too, as the SUPER+comma overlay target (see
    -- the "qute" special workspace below) -- running from login means the
    -- toggle only ever has to show/hide an already-running window instead of
    -- paying launch latency.
    hl.exec_cmd(browser_alt)
    -- The secret service Chrome stores passwords through. `libsecret` is only the
    -- client library; without a daemon answering `org.freedesktop.secrets` the
    -- `--password-store=gnome-libsecret` flag has nowhere to write, and Chrome
    -- silently keeps no passwords, which is the whole reason Chrome is here. A
    -- GNOME session starts this itself; Hyprland does not, so it is started here.
    -- `--start --components=secrets` brings up only the secret service, not the
    -- ssh or gpg agents, which this machine handles elsewhere.
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
end)

hl.env(
  "XCURSOR_SIZE", "24", false,
  "HYPRCURSOR_SIZE", "24", false,
  "EDITOR", "nvim", false
)

-- Prefer the Wayland backend in every toolkit and fall back to X11 only where
-- Wayland is unavailable; name the desktop so portals and screen sharing
-- identify the session.
hl.env(
  "GDK_BACKEND", "wayland,x11,*", false,
  "QT_QPA_PLATFORM", "wayland;xcb", false,
  "MOZ_ENABLE_WAYLAND", "1", false,
  "ELECTRON_OZONE_PLATFORM_HINT", "wayland", false,
  "XDG_SESSION_TYPE", "wayland", false,
  "XDG_CURRENT_DESKTOP", "Hyprland", false,
  "XDG_SESSION_DESKTOP", "Hyprland", false
)

hl.permission(
  "/usr/(bin|local/bin)/grim", "screencopy", "allow",
  "/usr/(bin|local/bin)/wf-recorder", "screencopy", "allow",
  "/usr/(lib|libexec|lib64)/xdg-desktop-portal-hyprland", "screencopy", "allow",
  "/usr/(bin|local/bin)/hyprpm", "plugin", "allow"
)

hl.config({
    ecosystem = {
        enforce_permissions = true,
        no_update_news = true,
    },
    xwayland = {
        -- Leave X11 windows unscaled so they stay crisp instead of being
        -- stretched by the compositor; GDK_SCALE sizes them if needed.
        force_zero_scaling = true,
    },
    input = {
        kb_layout = "us",
        -- kb_variant = "intl",
        -- 1 (the Hyprland default) refocuses whatever window ends up under
        -- the stationary cursor after a tiling change, so SUPER+hjkl's
        -- keyboard focus move got immediately overridden back. 2 detaches
        -- cursor focus from keyboard focus: focus only changes on click or
        -- an explicit focus dispatch, not just because the cursor is hovering.
        follow_mouse   = 2,
        natural_scroll = true,
        sensitivity    = 1.0,
        touchpad = {
            natural_scroll       = true,
            disable_while_typing = true,
        },
    },
    general = {
        gaps_in     = 5,
        gaps_out    = 5,
        border_size = border_size,
        col = {
            active_border   = "rgba(888888ff)",
            inactive_border = "rgba(111111ff)",
        },
        layout        = "dwindle",
        allow_tearing = false,
    },
    dwindle = {
        preserve_split      = true,
        default_split_ratio = 1.0,
        force_split         = 2,
    },
    decoration = {
        rounding         = 5,
        active_opacity   = 1.0,
        inactive_opacity = 1.0,
        blur = {
            enabled = true,
            size    = 10,
            passes  = 1,
        },
    },
    animations = {
        enabled = true,
    },
    misc = {
        font_family              = "Noto Sans",
        disable_hyprland_logo    = true,
        force_default_wallpaper  = 0,
        disable_splash_rendering = true,
        -- Wake the screens on input after DPMS put them to sleep.
        key_press_enables_dpms   = true,
        mouse_move_enables_dpms  = true,
    },
    cursor = {
        hide_on_key_press = true,
    },
})

-- hl.animation() only applies the first table when given several in one
-- variadic call (checked live with `hyprctl animations`: cramming all seven
-- leaves into a single hl.animation(t1, t2, ...) call left every leaf past
-- the first at its untouched Hyprland default). One call per leaf, the same
-- way hl.bind() is already called separately for each keybind in this file.
hl.animation({ leaf = "windows",    enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 7,  bezier = "default", style = "popin 80%" })
hl.animation({ leaf = "border",     enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "borderangle",enabled = true, speed = 8,  bezier = "default" })
hl.animation({ leaf = "fade",       enabled = true, speed = 7,  bezier = "default" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 6,  bezier = "default" })
-- Without its own leaf, the special workspace (used for the qutebrowser overlay
-- toggle) inherits "workspaces"' horizontal slide and enters from the right.
-- Plain "slidevert" is vertical but hardcoded to enter from the bottom, with
-- no direction option (github.com/hyprwm/Hyprland/discussions/1757) -- a
-- negative percentage on "slidefadevert" is the documented workaround to
-- flip it to enter from the top instead.
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 6, bezier = "default", style = "slidefadevert -50%" })

hl.window_rule(
  {
    name  = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
  },
  {
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus = true,
  }
)

-- Pins every newly-opened window to workspace 1, except qutebrowser, which
-- goes to the "qute" special workspace instead so SUPER+comma can show/hide
-- it as an overlay (see the toggle bind below). hl.window_rule's spec only
-- takes {enabled, match, name} in this Hyprland Lua build (checked against
-- /usr/share/hypr/stubs/hl.meta.lua) -- there is no "workspace" effect field
-- on it, unlike the classic .conf windowrule syntax. A per-window "move to
-- workspace" dispatch on window.open is the mechanism that actually moves the
-- window (verified live: spawned test windows landed on workspace 1).
hl.on("window.open", function(win)
  if win.class == "org.qutebrowser.qutebrowser" then
    hl.dispatch(hl.dsp.window.move({ workspace = "special:qute" }))
  else
    hl.dispatch(hl.dsp.window.move({ workspace = "1" }))
  end
end)

-- Screenshot (1: area, 2: full), screen record (3: area, 4: full, 5: stop)
local pictureDir = "~/horrea/capture/picture"
local recordDir  = "~/horrea/capture/record"
local screenshot_area = [[mkdir -p ]] .. pictureDir .. [[ && grim -g "$(slurp)" - | tee ]] .. pictureDir .. [[/screenshot-$(date +%Y%m%d-%H%M%S).png | wl-copy && notify-send "Screenshot" "Area captured and copied to clipboard"]]
local screenshot_full = [[mkdir -p ]] .. pictureDir .. [[ && grim - | tee ]] .. pictureDir .. [[/screenshot-$(date +%Y%m%d-%H%M%S).png | wl-copy && notify-send "Screenshot" "Full screen captured and copied to clipboard"]]
local record_area = [[mkdir -p ]] .. recordDir .. [[ && notify-send "Recording" "Area recording started (SUPER+5 to stop)" && wf-recorder -g "$(slurp)" -f ]] .. recordDir .. [[/recording-$(date +'%Y-%m-%d-%H:%M:%S').mp4]]
local record_full = [[mkdir -p ]] .. recordDir .. [[ && notify-send "Recording" "Full screen recording started (SUPER+5 to stop)" && wf-recorder -o "$(hyprctl monitors | awk '/^Monitor/ {m=$2} /focused: yes/ {print m; exit}')" -f ]] .. recordDir .. [[/recording-$(date +'%Y-%m-%d-%H:%M:%S').mp4]]
local record_stop = [[pkill --signal SIGINT wf-recorder && notify-send "Recording" "Stopped and saved to ]] .. recordDir .. [["]]

hl.bind(main .. " + 1", hl.dsp.exec_cmd(screenshot_area), { description = "Screenshot area" })
hl.bind(main .. " + 2", hl.dsp.exec_cmd(screenshot_full), { description = "Screenshot full screen" })
hl.bind(main .. " + 3", hl.dsp.exec_cmd(record_area), { description = "Record area" })
hl.bind(main .. " + 4", hl.dsp.exec_cmd(record_full), { description = "Record full screen" })
hl.bind(main .. " + 5", hl.dsp.exec_cmd(record_stop), { description = "Stop recording" })

-- Brightness and volume: `repeating` so a held key keeps stepping, `locked` so
-- the keys still work on the lock screen. Every bind carries a description so
-- `hyprctl binds` reads as a cheat sheet.
hl.bind(main .. " + f", hl.dsp.exec_cmd("brightnessctl set +5%"),
  { description = "Brightness up", repeating = true, locked = true })
hl.bind(main .. " + b", hl.dsp.exec_cmd("brightnessctl set 5%-"),
  { description = "Brightness down", repeating = true, locked = true })

hl.bind(
  main .. " + n",
  hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 10%-"),
  { description = "Volume down", repeating = true, locked = true }
)

hl.bind(
  main .. " + p",
  hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 10%+"),
  { description = "Volume up", repeating = true, locked = true }
)

-- Workspace-switch/move binds (comma/period, SHIFT+comma/period) removed:
-- every window is pinned to workspace 1 on open, so there is nothing to
-- switch or move to on another workspace.

hl.bind(
  main .. " + SHIFT + h",
  hl.dsp.window.move({ direction = "left" }),
  { description = "Move window left" }
)

hl.bind(
  main .. " + SHIFT + j",
  hl.dsp.window.move({ direction = "down" }),
  { description = "Move window down" }
)

hl.bind(
  main .. " + SHIFT + k",
  hl.dsp.window.move({ direction = "up" }),
  { description = "Move window up" }
)

hl.bind(
  main .. " + SHIFT + l",
  hl.dsp.window.move({ direction = "right" }),
  { description = "Move window right" }
)

hl.bind(main .. " + h", hl.dsp.focus({ direction = "left" }), { description = "Focus left" })
hl.bind(main .. " + j", hl.dsp.focus({ direction = "down" }), { description = "Focus down" })
hl.bind(main .. " + k", hl.dsp.focus({ direction = "up" }), { description = "Focus up" })
hl.bind(main .. " + l", hl.dsp.focus({ direction = "right" }), { description = "Focus right" })

hl.bind(main .. " + comma", hl.dsp.workspace.toggle_special("qute"),
  { description = "Toggle qutebrowser overlay" })
hl.bind(main .. " + SHIFT + semicolon", hl.dsp.exec_cmd(browser_alt),
  { description = "Browser (qutebrowser)" })
hl.bind(main .. " + Return", hl.dsp.exec_cmd(terminal), { description = "Terminal" })
hl.bind(main .. " + m", hl.dsp.window.fullscreen(), { description = "Full screen" })
hl.bind(main .. " + q", hl.dsp.window.close(), { description = "Close window" })
