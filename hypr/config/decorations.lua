-- Look and feel configuration

hl.config({
    general = {
        gaps_in = 3,
        gaps_out = {
            top = 4,
            right = 4,
            bottom = 4,
            left = 4
        },
        border_size = 0,
        extend_border_grab_area = 10,
        resize_on_border = false,
        col = {
            active_border = "#ffffff9c",
            inactive_border = "#ffffff00",
        },
    },

    decoration = {
        dim_special = 0.2,
        rounding = 10,
        active_opacity = 0.92,
        inactive_opacity = 0.92,
        fullscreen_opacity = 1,
        blur = {
            size = 3,
            passes = 4,
            special = true,
        },
    },
})
