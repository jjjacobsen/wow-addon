local container = PlayerFrame.PlayerFrameContainer
local decoration = container:CreateTexture(nil, "ARTWORK", nil, 2)
decoration:SetAtlas("UI-HUD-UnitFrame-Target-PortraitOn-Boss-Rare-Silver-Winged", true)
decoration:SetTexCoord(1, 0, 0, 1)
decoration:SetPoint("TOPLEFT", container, "TOPLEFT", -8, -7)
