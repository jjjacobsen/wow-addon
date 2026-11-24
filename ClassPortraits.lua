local _, addon = ...

addon.RegisterFeature("classPortraits", "Class icons for portraits", function(enabled)
    -- Forever registers these settings after PLAYER_LOGIN, before SETTINGS_LOADED.
    EventUtil.RegisterOnceFrameEventAndCallback("SETTINGS_LOADED", function()
        Settings.SetValue("ReplaceMyPlayerPortrait", enabled)
        Settings.SetValue("ReplaceOtherPlayerPortraits", enabled)
    end)
end)
