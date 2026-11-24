local _, addon = ...
local carrotID = 11122

addon.RegisterFeature("carrotOnAStick", "Carrot on a Stick reminder", function(enabled)
    if not enabled then
        return
    end

    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(36, 36)
    local position = JJSettings.carrotPosition or { "CENTER", "CENTER", 0, -100 }
    frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("RightButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, x, y = self:GetPoint()
        JJSettings.carrotPosition = { point, relativePoint, x, y }
    end)
    frame:Hide()
    local icon = frame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()

    frame:RegisterEvent("PLAYER_ENTERING_WORLD")
    frame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    frame:SetScript("OnEvent", function()
        for slot = 13, 14 do
            if GetInventoryItemID("player", slot) == carrotID then
                icon:SetTexture(GetInventoryItemTexture("player", slot))
                frame:Show()
                return
            end
        end
        frame:Hide()
    end)
end)
