local _, addon = ...

function addon.AddMinimapButton(key, label, spellID, defaultAngle, onClick)
    JJSettings.minimapButtons = JJSettings.minimapButtons or {}
    local settings = JJSettings.minimapButtons
    local angle = settings[key] or defaultAngle

    local button = CreateFrame("Button", nil, Minimap)
    button:SetSize(32, 32)
    button:SetFrameLevel(Minimap:GetFrameLevel() + 5)
    button:RegisterForClicks("LeftButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(24, 24)
    icon:SetPoint("CENTER")
    local texture = C_Spell.GetSpellTexture(spellID)
    icon:SetTexture(texture)
    local mask = button:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetAtlas("ui-hud-minimap-frame-generic-mask")
    icon:AddMaskTexture(mask)

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetAllPoints()
    border:SetAtlas("UI-HUD-Minimap-Frame-Cycle")
    button:SetHighlightAtlas("UI-HUD-Minimap-Frame-Cycle", "ADD")

    local function UpdatePosition()
        local radians = math.rad(angle)
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER",
            math.cos(radians) * (Minimap:GetWidth() / 2 + 2),
            math.sin(radians) * (Minimap:GetHeight() / 2 + 2))
    end

    local function StopDragging(self)
        self:SetScript("OnUpdate", nil)
        settings[key] = angle
    end

    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(label)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnDragStart", function(self)
        GameTooltip:Hide()
        self:SetScript("OnUpdate", function()
            local x, y = GetCursorPosition()
            local centerX, centerY = Minimap:GetCenter()
            local scale = Minimap:GetEffectiveScale()
            angle = math.deg(math.atan2(y / scale - centerY, x / scale - centerX))
            UpdatePosition()
        end)
    end)
    button:SetScript("OnDragStop", StopDragging)
    button:SetScript("OnHide", function(self)
        StopDragging(self)
        GameTooltip:Hide()
    end)
    UpdatePosition()
end
