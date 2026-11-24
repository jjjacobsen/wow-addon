local _, addon = ...
local POISED_ROGUE_AURA_ID = 1328826
local POISED_DRUID_AURA_ID = 1328827
local poisedName = C_Spell.GetSpellName(POISED_DRUID_AURA_ID)

local function IsPoised(instanceID)
    if issecretvalue(instanceID) or not instanceID then
        return
    end

    local aura = C_UnitAuras.GetAuraDataByAuraInstanceID("player", instanceID)
    if issecretvalue(aura) or not aura or not canaccesstable(aura) then
        return
    end

    local spellID = aura.spellId
    if not issecretvalue(spellID) and (spellID == POISED_ROGUE_AURA_ID or spellID == POISED_DRUID_AURA_ID) then
        return true
    end

    local name = aura.name
    return poisedName and not issecretvalue(name) and name == poisedName
end

local function HookAuraFrame(frame)
    local hidden

    hooksecurefunc(frame.AuraContainer, "UpdateGridLayout", function(container, icons, doNotAnchorDisabledFrames)
        if not hidden then
            return
        end

        -- Forever's grid still anchors hidden buttons. Keep Blizzard's order and omit only Poised.
        local compact = {}
        for _, icon in ipairs(icons) do
            if not hidden[icon] then
                compact[#compact + 1] = icon
            end
        end
        AuraContainerMixin.UpdateGridLayout(container, compact, doNotAnchorDisabledFrames)
    end)

    hooksecurefunc(frame, "UpdateAuraButtons", function()
        local wasHidden = hidden
        hidden = nil

        -- Blizzard assigns fresh buttonInfo when it reuses a button.
        if PlayerFrame.unit == "player" then
            for _, button in ipairs(frame.auraFrames) do
                if button.hasValidInfo and not button.isExample and button.auraType == "Buff" and IsPoised(button.buttonInfo.auraInstanceID) then
                    button:Hide()
                    hidden = hidden or {}
                    hidden[button] = true
                end
            end
        end

        -- The tooltip lays itself out after updating its buttons. The main frame does not.
        if frame == BuffFrame and (hidden or wasHidden) then
            frame:UpdateGridLayout()
        end
    end)
end

addon.RegisterFeature("hidePoisedBuff", "Hide Poised buff", function(enabled)
    if enabled then
        HookAuraFrame(BuffFrame)
        HookAuraFrame(BuffFrame.ConsolidatedBuffs.Tooltip.Auras)
    end
end)
