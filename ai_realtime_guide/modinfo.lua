name = "AI Realtime Guide"
description = "Realtime survival guidance with configurable playstyle goals. MVP uses local rule-based advice."
author = "Codex"
version = "0.1.0"

api_version = 10
dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
shipwrecked_compatible = false
hamlet_compatible = false

client_only_mod = true
all_clients_require_mod = false

server_filter_tags = {
    "guide",
    "assistant",
}

configuration_options = {
    {
        name = "playstyle",
        label = "Core Playstyle",
        hover = "Choose the high-level strategy used by the guide.",
        options = {
            { description = "New Player Survival", data = "new_player_survival", hover = "General advice for stable survival." },
            { description = "Winter Prep", data = "winter_prep", hover = "Prioritize preparation before winter." },
            { description = "Rush Science", data = "rush_science", hover = "Prioritize early tech progression." },
            { description = "Caves / Ruins", data = "caves_ruins", hover = "Prioritize cave and ruins readiness." },
        },
        default = "new_player_survival",
    },
    {
        name = "toggle_key",
        label = "Toggle Panel Key",
        hover = "Open or close the realtime guide panel.",
        options = {
            { description = "G", data = 103 },
            { description = "F6", data = 291 },
            { description = "F7", data = 292 },
            { description = "F8", data = 293 },
        },
        default = 103,
    },
    {
        name = "auto_show_warnings",
        label = "Auto Show Warnings",
        hover = "Show the guide panel automatically when urgent advice appears.",
        options = {
            { description = "Enabled", data = true },
            { description = "Disabled", data = false },
        },
        default = true,
    },
}
