local mainMod = "SUPER"
local noctCall = "noctalia msg "
local launchPrefix = "uwsm app -- "


-- hl.config({
--     plugin = {
--         scrolloverview = {
--             gesture_distance = 300, -- how far is the "max" for the gesture
--             scale = 0.67,           -- preferred overview scale
--             workspace_gap = 100,
--             layout = "horizontal",  -- vertical, horizontal, or auto (per-monitor orientation)
--             wallpaper = 0,          -- 0: global only, 1: per-workspace only, 2: both
--             blur = true,            -- blur only the main overview wallpaper
--         },
--     },
-- })

hl.config({
    plugin = {
        overview = {
            panelColor = "rgba(0, 5, 8, 0.0)",
            panelBorderColor = "rgba(49, 50, 68, 0.0)",
            workspaceActiveBackground = "rgba(49, 50, 68, 0.8)",
            workspaceActiveBorder = "rgba(255, 255, 255, 0.3)",
            onBottom = false,
            autoDrag = true,
            showNewWorkspace = false,
            vertical = true,
            fitWindows = false,
            scaleWorkspace = true,
            stageGap = 50,
            stageMargin = 100,
            stageBlur = true,
            stageDim = "rgba(0, 5, 8, 0.2)"
            -- Add other overview settings here
        }
    }
})
