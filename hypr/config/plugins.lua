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
            workspaceActiveBorder = "rgba(255, 255, 255, 0.9)",
            workspaceBorderSize = 4,
            onBottom = true,
            autoDrag = true,
            showNewWorkspace = false,
            vertical = true,
            fitWindows = true,
            scaleWorkspace = 1,
            stageGap = 30,
            stageMargin = 60,
            stageBlur = true,
            stageDim = "rgba(0, 5, 8, 0.2)",
            stageRounding = 30,
            showPanel = 1,
            panelInStage = false,
            panelHeight = 230,
            workspaceMargin = 20
            -- Add other overview settings here
        }
    }
})

hl.config({
    plugin = {
        hymission = {
            -- Stage (zijbalk)
            -- stage_enabled = 1,
            -- stage_card_min_width = 120,
            -- stage_card_max_width = 0,
            -- stage_show_empty = 1,
            -- stage_show_active = 0,

            -- Sneller dan de standaardwaarden
            -- hover_relayout_duration = 80, -- standaard 140
            vim_keys = 1,
            -- stage_transition_ms = 150, -- standaard 300
            hide_bar_animation = 0, -- bar verdwijnt direct

            -- Optie A: natuurlijke indeling, vult lege ruimte beter
            layout_engine = "natural",
            natural_scale_flex = 0.25, -- max. toegestaan (standaard 0.22)
            small_window_boost = 1.35, -- kleine vensters worden groter (standaard 1.35)

            -- Minder verloren ruimte
            outer_padding_top = 40,
            outer_padding_right = 40,
            outer_padding_bottom = 40,
            outer_padding_left = 40,
            row_spacing = 16,
            column_spacing = 16,

        },
    },
})
