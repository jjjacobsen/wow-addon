local _, addon = ...

local function AddPlayerLevel(_, decoratedPlayerName, ...)
    local senderGUID = select(12, ...)
    if not canaccessvalue(senderGUID) or not senderGUID or not senderGUID:match("^Player%-") then
        return
    end

    local level = select(8, GetPlayerInfoByGUID(senderGUID))
    if not canaccessvalue(level) or not level or level <= 0 then
        return
    end

    -- Native chat starts each pass from the original sender name
    return decoratedPlayerName .. " - " .. level
end

addon.RegisterFeature("chatPlayerLevels", "Show chat player levels", function(enabled)
    if enabled then
        ChatFrameUtil.AddSenderNameFilter(AddPlayerLevel)
    end
end)
