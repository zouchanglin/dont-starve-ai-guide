local Widget = require("widgets/widget")
local Text = require("widgets/text")
local Image = require("widgets/image")
local AiGuideState = require("ai_guide_state")

local ANCHOR_LEFT = GLOBAL.ANCHOR_LEFT
local ANCHOR_MIDDLE = GLOBAL.ANCHOR_MIDDLE
local ANCHOR_RIGHT = GLOBAL.ANCHOR_RIGHT
local ANCHOR_TOP = GLOBAL.ANCHOR_TOP
local CHATFONT = GLOBAL.CHATFONT
local Class = GLOBAL.Class
local SCALEMODE_PROPORTIONAL = GLOBAL.SCALEMODE_PROPORTIONAL
local UICOLOURS = GLOBAL.UICOLOURS

local PANEL_WIDTH = 520
local PANEL_HEIGHT = 300
local UPDATE_INTERVAL = 2

local PRIORITY_LABELS = {
    high = "[HIGH]",
    medium = "[MED]",
    low = "[OK]",
}

local AiGuidePanel = Class(Widget, function(self)
    Widget._ctor(self, "AiGuidePanel")

    self:SetVAnchor(ANCHOR_MIDDLE)
    self:SetHAnchor(ANCHOR_RIGHT)
    self:SetPosition(-290, 20, 0)
    self:SetScaleMode(SCALEMODE_PROPORTIONAL)

    self.bg = self:AddChild(Image("images/global.xml", "square.tex"))
    self.bg:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    self.bg:SetTint(0.05, 0.055, 0.06, 0.88)

    self.title = self:AddChild(Text(CHATFONT, 28, "AI Realtime Guide", UICOLOURS.GOLD))
    self.title:SetHAlign(ANCHOR_LEFT)
    self.title:SetRegionSize(PANEL_WIDTH - 40, 34)
    self.title:SetPosition(0, 120, 0)

    self.summary = self:AddChild(Text(CHATFONT, 21, "", UICOLOURS.WHITE))
    self.summary:SetHAlign(ANCHOR_LEFT)
    self.summary:SetVAlign(ANCHOR_TOP)
    self.summary:SetRegionSize(PANEL_WIDTH - 44, 58)
    self.summary:SetPosition(0, 72, 0)

    self.body = self:AddChild(Text(CHATFONT, 22, "", UICOLOURS.WHITE))
    self.body:SetHAlign(ANCHOR_LEFT)
    self.body:SetVAlign(ANCHOR_TOP)
    self.body:SetRegionSize(PANEL_WIDTH - 44, 156)
    self.body:SetPosition(0, -28, 0)

    self.footer = self:AddChild(Text(CHATFONT, 18, "Press toggle key to close", UICOLOURS.GREY))
    self.footer:SetHAlign(ANCHOR_RIGHT)
    self.footer:SetRegionSize(PANEL_WIDTH - 44, 24)
    self.footer:SetPosition(0, -132, 0)

    self.elapsed = UPDATE_INTERVAL
    self:StartUpdating()
end)

local function FormatAdvice(advice)
    local lines = {}

    for index, item in ipairs(advice) do
        if index > 4 then
            break
        end

        local label = PRIORITY_LABELS[item.priority] or "[INFO]"
        table.insert(lines, string.format("%s %s\n%s", label, item.title, item.detail))
    end

    return table.concat(lines, "\n\n")
end

function AiGuidePanel:RefreshNow()
    local ok, guide = pcall(AiGuideState.GetGuide)
    if not ok or guide == nil then
        self.summary:SetString("Waiting for player state...")
        self.body:SetString("The guide will refresh after the player HUD is ready.")
        return
    end

    self.summary:SetString(guide.summary)
    self.body:SetString(FormatAdvice(guide.advice))

    if guide.snapshot.auto_show_warnings and not self.shown then
        for _, item in ipairs(guide.advice) do
            if item.priority == "high" then
                self:Show()
                break
            end
        end
    end
end

function AiGuidePanel:OnUpdate(dt)
    self.elapsed = self.elapsed + dt
    if self.elapsed < UPDATE_INTERVAL then
        return
    end

    self.elapsed = 0
    self:RefreshNow()
end

return AiGuidePanel
