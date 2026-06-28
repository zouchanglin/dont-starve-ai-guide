local MOD_NAME = "ai_realtime_guide"
local DEFAULT_PLAYSTYLE = "new_player_survival"
local DEFAULT_AUTO_SHOW_WARNINGS = true

local SEASON_NAMES = {
    autumn = "Autumn",
    winter = "Winter",
    spring = "Spring",
    summer = "Summer",
}

local function Round(value)
    if value == nil then
        return nil
    end

    return math.floor(value + 0.5)
end

local function GetConfig(name, default)
    local ok, value = pcall(GetModConfigData, name, MOD_NAME)
    if ok and value ~= nil then
        return value
    end

    return default
end

local function ReadClassifiedValue(classified, current_name, max_name)
    if classified == nil then
        return nil, nil
    end

    local current = classified[current_name]
    local max = classified[max_name]

    current = current ~= nil and current:value() or nil
    max = max ~= nil and max:value() or nil

    return current, max
end

local function ReadPlayerStats(player)
    if player == nil then
        return {}
    end

    local classified = player.player_classified
    local health, max_health = ReadClassifiedValue(classified, "currenthealth", "maxhealth")
    local hunger, max_hunger = ReadClassifiedValue(classified, "currenthunger", "maxhunger")
    local sanity, max_sanity = ReadClassifiedValue(classified, "currentsanity", "maxsanity")
    local temperature = classified ~= nil and classified.currenttemperature ~= nil and classified.currenttemperature:value() or nil

    return {
        health = health,
        max_health = max_health,
        hunger = hunger,
        max_hunger = max_hunger,
        sanity = sanity,
        max_sanity = max_sanity,
        temperature = temperature,
    }
end

local function CountInventoryPrefabs(player)
    local counts = {}

    if player == nil or player.replica == nil or player.replica.inventory == nil then
        return counts
    end

    local inventory = player.replica.inventory
    local items = inventory.GetItems ~= nil and inventory:GetItems() or nil

    if items ~= nil then
        for _, item in pairs(items) do
            if item ~= nil and item.prefab ~= nil then
                local stack = item.replica ~= nil and item.replica.stackable ~= nil and item.replica.stackable:StackSize() or 1
                counts[item.prefab] = (counts[item.prefab] or 0) + stack
            end
        end
    end

    local equips = inventory.GetEquips ~= nil and inventory:GetEquips() or nil
    if equips ~= nil then
        for _, item in pairs(equips) do
            if item ~= nil and item.prefab ~= nil then
                counts[item.prefab] = (counts[item.prefab] or 0) + 1
            end
        end
    end

    return counts
end

local function HasAny(counts, prefabs)
    for _, prefab in ipairs(prefabs) do
        if (counts[prefab] or 0) > 0 then
            return true
        end
    end

    return false
end

local function CountAny(counts, prefabs)
    local total = 0
    for _, prefab in ipairs(prefabs) do
        total = total + (counts[prefab] or 0)
    end

    return total
end

local function ReadWorldState()
    local world = GLOBAL.TheWorld
    local state = world ~= nil and world.state or nil

    return {
        day = state ~= nil and state.cycles ~= nil and state.cycles + 1 or nil,
        phase = state ~= nil and state.phase or nil,
        season = state ~= nil and state.season or nil,
    }
end

local function PushAdvice(advice, priority, title, detail)
    table.insert(advice, {
        priority = priority,
        title = title,
        detail = detail,
    })
end

local function AddUniversalAdvice(advice, snapshot)
    local stats = snapshot.stats
    local inventory = snapshot.inventory

    if stats.health ~= nil and stats.max_health ~= nil and stats.health <= stats.max_health * 0.35 then
        PushAdvice(advice, "high", "Health is low", "Avoid fighting. Eat healing food, use a poultice, or return to base before exploring.")
    end

    if stats.hunger ~= nil and stats.max_hunger ~= nil and stats.hunger <= stats.max_hunger * 0.30 then
        PushAdvice(advice, "high", "Hunger is low", "Cook food now. Do not start a long trip until hunger is stable.")
    end

    if stats.sanity ~= nil and stats.max_sanity ~= nil and stats.sanity <= stats.max_sanity * 0.35 then
        PushAdvice(advice, "medium", "Sanity is dropping", "Pick flowers, cook green caps, prototype an item, or prepare for shadow creatures.")
    end

    if snapshot.world.phase == "night" and not HasAny(inventory, { "torch", "lantern", "minerhat" }) then
        PushAdvice(advice, "high", "No portable light", "Carry a torch, lantern, or miner hat before leaving camp at night.")
    end

    if CountAny(inventory, { "grass" }) < 6 or CountAny(inventory, { "twigs" }) < 6 then
        PushAdvice(advice, "medium", "Basic materials are low", "Keep at least 6 grass and 6 twigs for torches, tools, traps, and emergency crafts.")
    end
end

local function AddPlaystyleAdvice(advice, snapshot)
    local day = snapshot.world.day or 1
    local season = snapshot.world.season
    local inventory = snapshot.inventory
    local playstyle = snapshot.playstyle

    if playstyle == "winter_prep" or (playstyle == "new_player_survival" and season == "autumn" and day >= 12) then
        if not HasAny(inventory, { "heatrock" }) then
            PushAdvice(advice, "high", "Prepare a thermal stone", "Winter usually starts around day 21. Make a thermal stone before long winter trips.")
        end

        if not HasAny(inventory, { "winterhat", "beefalohat", "trunkvest_winter", "earmuffshat" }) then
            PushAdvice(advice, "medium", "Prepare warm clothing", "Prioritize beefalo wool, silk, or koalefant trunk for winter insulation.")
        end

        PushAdvice(advice, "medium", "Stockpile food", "Dry meat, fill crock pot ingredients, or build an ice box before winter pressure starts.")
        return
    end

    if playstyle == "rush_science" then
        if CountAny(inventory, { "goldnugget" }) < 1 then
            PushAdvice(advice, "high", "Find gold", "Mine boulders with gold veins or trade with Pig King to unlock the science machine.")
        elseif CountAny(inventory, { "boards" }) < 4 or CountAny(inventory, { "cutstone" }) < 2 then
            PushAdvice(advice, "medium", "Refine tech materials", "Make boards and cut stone so you can place an alchemy engine quickly.")
        else
            PushAdvice(advice, "medium", "Build core science", "Place an alchemy engine near base and prototype backpack, spear, shovel, and crock pot.")
        end
        return
    end

    if playstyle == "caves_ruins" then
        if not HasAny(inventory, { "lantern", "minerhat" }) then
            PushAdvice(advice, "high", "Bring stable cave light", "Craft a lantern or miner hat before entering caves.")
        end

        if not HasAny(inventory, { "footballhat", "armorwood", "armormarble" }) then
            PushAdvice(advice, "high", "Bring armor", "Wear a football helmet or log suit before fighting cave mobs.")
        end

        if CountAny(inventory, { "pierogies", "honeyham", "meatballs", "dragonpie", "healingsalve", "bandage" }) < 3 then
            PushAdvice(advice, "medium", "Pack recovery items", "Bring food and healing before committing to a cave or ruins route.")
        end
        return
    end

    if CountAny(inventory, { "flint" }) < 2 then
        PushAdvice(advice, "medium", "Collect flint", "Keep spare flint so you can remake axe, pickaxe, or torch tools.")
    end

    if not HasAny(inventory, { "spear", "hambat", "tentaclespike" }) then
        PushAdvice(advice, "medium", "Craft a weapon", "Make a spear before fighting spiders, hounds, or tallbirds.")
    end
end

local function BuildSnapshot()
    local player = GLOBAL.ThePlayer

    return {
        playstyle = GetConfig("playstyle", DEFAULT_PLAYSTYLE),
        auto_show_warnings = GetConfig("auto_show_warnings", DEFAULT_AUTO_SHOW_WARNINGS),
        stats = ReadPlayerStats(player),
        inventory = CountInventoryPrefabs(player),
        world = ReadWorldState(),
    }
end

local function BuildAdvice(snapshot)
    local advice = {}

    AddUniversalAdvice(advice, snapshot)
    AddPlaystyleAdvice(advice, snapshot)

    if #advice == 0 then
        PushAdvice(advice, "low", "Current route looks stable", "Keep scouting resources, improve base tech, and prepare for the next seasonal threat.")
    end

    return advice
end

local function FormatSnapshot(snapshot)
    local stats = snapshot.stats
    local world = snapshot.world
    local season = world.season ~= nil and (SEASON_NAMES[world.season] or world.season) or "Unknown"
    local day = world.day ~= nil and tostring(world.day) or "?"
    local phase = world.phase ~= nil and world.phase or "?"

    return string.format(
        "Day %s | %s | %s\nHP %s/%s  Hunger %s/%s  Sanity %s/%s  Temp %s",
        day,
        season,
        phase,
        stats.health ~= nil and Round(stats.health) or "?",
        stats.max_health ~= nil and Round(stats.max_health) or "?",
        stats.hunger ~= nil and Round(stats.hunger) or "?",
        stats.max_hunger ~= nil and Round(stats.max_hunger) or "?",
        stats.sanity ~= nil and Round(stats.sanity) or "?",
        stats.max_sanity ~= nil and Round(stats.max_sanity) or "?",
        stats.temperature ~= nil and Round(stats.temperature) or "?"
    )
end

local function GetGuide()
    local snapshot = BuildSnapshot()

    return {
        snapshot = snapshot,
        advice = BuildAdvice(snapshot),
        summary = FormatSnapshot(snapshot),
    }
end

return {
    GetGuide = GetGuide,
}
