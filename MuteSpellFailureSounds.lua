local _, addon = ...

addon.RegisterFeature("muteSpellFailureSounds", "Mute spell failure sounds", function(enabled)
    if not enabled then
        return
    end

    -- IDs: https://github.com/wowdev/wow-listfile/blob/deeca4ac550d28d49f38be5248367a0b2eceb840/parts/sound.csv#L32651-L32655
    local sounds = {
        569772, -- Sound/Spells/Fizzle/FizzleHolyA.ogg
        569773, -- Sound/Spells/Fizzle/FizzleFireA.ogg
        569774, -- Sound/Spells/Fizzle/FizzleNatureA.ogg
        569775, -- Sound/Spells/Fizzle/FizzleFrostA.ogg
        569776, -- Sound/Spells/Fizzle/FizzleShadowA.ogg
    }

    for _, sound in ipairs(sounds) do
        MuteSoundFile(sound)
    end

    -- Mutes survive reloads. Release them before logout or reload so disabling restores sound.
    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_LOGOUT")
    events:SetScript("OnEvent", function()
        for _, sound in ipairs(sounds) do
            UnmuteSoundFile(sound)
        end
    end)
end)
