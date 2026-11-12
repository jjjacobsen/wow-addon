local _, addon = ...
local pending = {}
local timer
local indicator

local function ManaCost(spellID)
    if issecretvalue(spellID) or spellID == nil then
        return
    end
    local costs = C_Spell.GetSpellPowerCost(spellID)
    if issecretvalue(costs) or costs == nil then
        return
    end
    for _, cost in ipairs(costs) do
        if issecretvalue(cost) or issecretvalue(cost.type) then
            return
        end
        if cost.type == Enum.PowerType.Mana then
            if issecretvalue(cost.cost) then
                return
            end
            return cost.cost
        end
    end
end

local function OnEvent(self, event, _, first, second, third)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent(event)
        self:SetParent(PlayerFrame)
        self:SetSize(6, 6)
        self:SetPoint("RIGHT", PlayerFrame.PlayerFrameContainer.PlayerPortrait, "LEFT", -30, -45)
        self:Hide()
        local dot = self:CreateTexture(nil, "OVERLAY")
        dot:SetAllPoints()
        dot:SetColorTexture(1, 0.82, 0)
        local mask = self:CreateMaskTexture()
        mask:SetAllPoints()
        mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        dot:AddMaskTexture(mask)
        for _, castEvent in ipairs({ "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED",
            "UNIT_SPELLCAST_FAILED_QUIET", "UNIT_SPELLCAST_INTERRUPTED" }) do
            self:RegisterUnitEvent(castEvent, "player")
        end
        return
    end

    -- SENT includes a target name before the GUID. Never retain that name.
    local castGUID, spellID = first, second
    if event == "UNIT_SPELLCAST_SENT" then
        castGUID, spellID = second, third
    end
    if issecretvalue(castGUID) or castGUID == nil then
        -- Unreadable GUIDs cannot be matched. Discard pending snapshots, not the running timer.
        pending = {}
        return
    end
    if event == "UNIT_SPELLCAST_SENT" then
        pending[castGUID] = ManaCost(spellID)
        return
    end

    local cost = pending[castGUID]
    pending[castGUID] = nil
    if event == "UNIT_SPELLCAST_SUCCEEDED" and cost and cost > 0 then
        if timer then
            timer:Cancel()
        end
        indicator:Show()
        timer = C_Timer.NewTimer(5, function()
            indicator:Hide()
            timer = nil
        end)
    end
end

addon.RegisterFeature("fiveSecondRule", "Five-second rule", function(enabled)
    if not enabled then
        return
    end
    indicator = CreateFrame("Frame")
    indicator:RegisterEvent("PLAYER_LOGIN")
    indicator:SetScript("OnEvent", OnEvent)
end, false)
