local _, addon = ...

-- ChatChannels.db2 IDs, not local chat numbers
local tradeChannels = { [2] = true, [42] = true } -- Trade, Trade (Services)
local keywords = {
    pst = true,
    recruiting = true,
    lf = true,
    wts = true,
    lfw = true,
    wtb = true,
    lfg = true,
    summon = true,
    summons = true,
    summoning = true,
    wtt = true,
    lockbox = true,
    enchant = true,
}
local guildLinkTypes = {
    clubFinder = true,
    clubTicket = true,
    community = true,
}

local function FilterMessage(_, event, message, _, _, _, _, _, zoneChannelID)
    if event ~= "CHAT_MSG_YELL" and not tradeChannels[zoneChannelID] then
        return false
    end

    -- Keep link labels, but exclude hidden link data, colors, textures, and atlases
    local text = C_StringUtil.StripHyperlinks(message, false, true)
    if text:find("%a") and text == text:upper() then
        return true
    end

    text = text:lower()
    if text:find("<[^<>]+>") or text:find("%f[%w_]looking%s+for%f[^%w_]") then
        return true
    end
    local words = {}
    for word in text:gmatch("[%w_]+") do
        if keywords[word] or word == "lfm" or word:match("^lf%d+m$") then
            return true
        end
        words[word] = true
    end

    local guildContext = words.guild
    if not guildContext then
        for linkType in message:gmatch("|H([^:]+):") do
            if guildLinkTypes[linkType] then
                guildContext = true
                break
            end
        end
    end

    return guildContext and (words.recruitment or words.recruits or words.seeking) or false
end

addon.RegisterFeature("filterTradeChat", "Filter Trade chat", function(enabled)
    if not enabled then
        return
    end

    -- The native filter registry skips callbacks when chat payloads are secret
    ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", FilterMessage)
    ChatFrame_AddMessageEventFilter("CHAT_MSG_YELL", FilterMessage)
end)
