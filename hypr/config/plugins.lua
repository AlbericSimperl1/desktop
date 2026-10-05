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
            workspaceActiveBorder = "rgba(255, 255, 255, 0.6)",
            workspaceBorderSize = 3,
            onBottom = true,
            autoDrag = true,
            showNewWorkspace = false,
            vertical = false,
            fitWindows = true,
            scaleWorkspace = true,
            stageGap = 30,
            stageMargin = 60,
            stageBlur = true,
            stageDim = "rgba(0, 5, 8, 0.3)",
            stageRounding = 30,
            showPanel = 1,
            panelInStage = false,
            panelHeight = 230,
            workspaceMargin = 20
            -- Add other overview settings here
        }
    }
})
