local _, addon = ...
local decoration

addon.RegisterFeature("rareElitePlayerPortrait", "Rare-elite player portrait", function(enabled)
    if not decoration then
        local container = PlayerFrame.PlayerFrameContainer
        decoration = container:CreateTexture(nil, "ARTWORK", nil, 2)
        decoration:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver-Winged", true)
        decoration:SetTexCoord(1, 0, 0, 1)
        decoration:SetPoint("TOPLEFT", container, "TOPLEFT", -8, -7)
    end
    decoration:SetShown(enabled)
end)
