local _, addon = ...

addon.RegisterFeature("muteBlacksmithingSounds", "Mute Thunder Bluff smithing hammer", function(enabled)
    if not enabled then
        return
    end

    -- Forever 1.60.1.71091: blacksmithing visual 395 uses kit 1143 (MiningHitA-E).
    -- Mining shares these files, so leave them alone outside Thunder Bluff.
    local sounds = { 569801, 569811, 569792, 569794, 569821 }
    local muted = false
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    events:RegisterEvent("PLAYER_LOGOUT")
    events:SetScript("OnEvent", function(_, event)
        local inCity = event ~= "PLAYER_LOGOUT" and GetRealZoneText() == C_Map.GetAreaInfo(1638)
        if inCity == muted then
            return
        end
        muted = inCity
        local apply = muted and MuteSoundFile or UnmuteSoundFile
        for _, sound in ipairs(sounds) do
            apply(sound)
        end
    end)
end, false)
