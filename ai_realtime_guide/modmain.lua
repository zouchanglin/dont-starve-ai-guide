local AiGuidePanel = require("widgets/ai_guide_panel")

local TOGGLE_KEY = GetModConfigData("toggle_key")

local function GetGuidePanel()
    local player = GLOBAL.ThePlayer
    if player == nil or player.HUD == nil or player.HUD.controls == nil then
        return nil
    end

    return player.HUD.controls.ai_realtime_guide_panel
end

AddClassPostConstruct("widgets/controls", function(self)
    if self.ai_realtime_guide_panel ~= nil then
        return
    end

    self.ai_realtime_guide_panel = self:AddChild(AiGuidePanel())
    self.ai_realtime_guide_panel:Hide()
end)

local function ToggleGuidePanel()
    local panel = GetGuidePanel()
    if panel == nil then
        return
    end

    if panel.shown then
        panel:Hide()
    else
        panel:Show()
        panel:RefreshNow()
    end
end

local function RegisterKeyHandler()
    if GLOBAL.TheInput == nil or GLOBAL.AI_REALTIME_GUIDE_KEY_REGISTERED then
        return
    end

    GLOBAL.AI_REALTIME_GUIDE_KEY_REGISTERED = true
    GLOBAL.TheInput:AddKeyDownHandler(TOGGLE_KEY, ToggleGuidePanel)
end

RegisterKeyHandler()

AddPlayerPostInit(function()
    RegisterKeyHandler()
end)
