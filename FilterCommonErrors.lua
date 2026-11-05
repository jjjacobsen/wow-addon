local _, addon = ...

addon.RegisterFeature("filterCommonErrors", "Filter common errors", function(enabled)
    if not enabled then
        return
    end

    local messageNames = {
        -- Cooldown
        "ERR_ABILITY_COOLDOWN",
        "ERR_ITEM_COOLDOWN",
        "ERR_SPELL_COOLDOWN",
        "SPELL_FAILED_NOT_READY",

        -- Insufficient resource
        "ERR_OUT_OF_MANA",
        "ERR_OUT_OF_RAGE",
        "ERR_OUT_OF_ENERGY",
        "ERR_OUT_OF_FOCUS",
        "ERR_OUT_OF_COMBO_POINTS",
        "SPELL_FAILED_NO_POWER",
        "SPELL_FAILED_NO_COMBO_POINTS",

        -- Out of range
        "ERR_BADATTACKPOS",
        "ERR_OUT_OF_RANGE",
        "ERR_SPELL_OUT_OF_RANGE",
        "SPELL_FAILED_OUT_OF_RANGE",

        -- Invalid target
        "ERR_INVALID_ATTACK_TARGET",
        "ERR_NO_ATTACK_TARGET",
        "ERR_GENERIC_NO_VALID_TARGETS",
        "SPELL_FAILED_BAD_TARGETS",
    }

    -- Forever 1.60.1 has no SPELL_FAILED_NO_POWER global. Resolve only available strings.
    local filteredMessages = {}
    for _, name in ipairs(messageNames) do
        local message = _G[name]
        if message then
            filteredMessages[message] = true
        end
    end

    local onEvent = UIErrorsFrame:GetScript("OnEvent")
    UIErrorsFrame:SetScript("OnEvent", function(self, event, ...)
        if event == "UI_ERROR_MESSAGE" then
            local _, message = ...
            if filteredMessages[message] then
                return
            end
        end

        -- Native TryDisplayMessage plays the error sound or voice as well as the text
        onEvent(self, event, ...)
    end)
end)
