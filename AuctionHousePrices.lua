local _, addon = ...
local enabled, auctionOpen, auctionMap, scan
local events = CreateFrame("Frame")
local scanCooldown = 15 * 60
local scanTimeout = 120
local capitals = {
    [1453] = "Alliance", -- Stormwind
    [1455] = "Alliance", -- Ironforge
    [1457] = "Alliance", -- Darnassus
    [1454] = "Horde", -- Orgrimmar
    [1456] = "Horde", -- Thunder Bluff
    [1458] = "Horde", -- Undercity
}

local function Say(message)
    print("wow-addon: " .. message)
end

local function MarketKey()
    local faction = UnitFactionGroup("player")
    if faction ~= "Alliance" and faction ~= "Horde" then
        return
    end
    local function Flag(rule)
        return C_GameRules.IsGameRuleActive(rule) and "1" or "0"
    end
    return table.concat({ GetCurrentRegion(),
        "pvp" .. Flag(Enum.GameRule.PvPRuleset),
        "rp" .. Flag(Enum.GameRule.RPRuleset),
        "hc" .. Flag(Enum.GameRule.HardcoreRuleset), faction }, ":")
end

local function Day()
    return math.floor(GetServerTime() / 86400)
end

local function Prune(history, oldestDay)
    for key, samples in pairs(history) do
        for day in pairs(samples) do
            if day < oldestDay then
                samples[day] = nil
            end
        end
        if not next(samples) then
            history[key] = nil
        end
    end
end

local function ItemKey(link)
    local item = link and link:match("item:([%d:%-]+)")
    if not item then
        return
    end
    local fields = { strsplit(":", item) }
    for index = 1, math.max(10, #fields) do
        if not fields[index] or fields[index] == "" then
            fields[index] = "0"
        end
    end
    -- Ignore player-applied enchants/gems, unique ID, viewer level and spec.
    -- Keep the suffix and all bonus/modifier fields, never just the item ID.
    for index = 2, 6 do
        fields[index] = "0"
    end
    for index = 8, 10 do
        fields[index] = "0"
    end
    while fields[#fields] == "0" do
        table.remove(fields)
    end
    return table.concat(fields, ":")
end

local function StopScan(message)
    scan = nil
    events:SetScript("OnUpdate", nil)
    if message then
        Say(message .. ". Previous prices kept")
    end
end

local function CommitScan()
    local market = JJAuctionPrices.markets[scan.marketKey]
    local history = market and market.history or {}
    local day = Day()
    Prune(history, day - 13)
    for key, price in pairs(scan.lowest) do
        history[key] = history[key] or {}
        history[key][day] = price
    end
    JJAuctionPrices.markets[scan.marketKey] = {
        lowest = scan.lowest,
        history = history,
        scannedAt = GetServerTime(),
    }
    local count = scan.count
    StopScan()
    Say("Scan complete: " .. count .. " auctions")
end

local function ReadAuction(index)
    local _, _, count, _, _, _, _, _, _, buyout, _, _, _, _, _, _, itemID, hasAllInfo =
        C_AuctionHouse.GetReplicateItemInfo(index)
    if not hasAllInfo or count <= 0 or itemID <= 0 then
        return false
    end
    if buyout > 0 then
        local key = ItemKey(C_AuctionHouse.GetReplicateItemLink(index))
        if not key then
            return false
        end
        local price = buyout / count
        if not scan.lowest[key] or price < scan.lowest[key] then
            scan.lowest[key] = price
        end
    end
    return true
end

local function ProcessScan()
    if GetTime() >= scan.deadline then
        StopScan("Scan timed out or was throttled by the server. Wait about 15 minutes before retrying")
        return
    end
    if MarketKey() ~= scan.marketKey or C_Map.GetBestMapForUnit("player") ~= auctionMap then
        StopScan("Scan cancelled because the market or location changed")
        return
    end
    if not scan.count then
        return
    end
    if C_AuctionHouse.GetNumReplicateItems() ~= scan.count then
        StopScan("Auction data changed during the scan")
        return
    end
    for _ = 1, 200 do
        local index
        if scan.index < scan.count then
            index = scan.index
            scan.index = scan.index + 1
        else
            index = next(scan.pending)
            if not index then
                CommitScan()
                return
            end
        end
        if ReadAuction(index) then
            scan.pending[index] = nil
        else
            scan.pending[index] = true
            if scan.index == scan.count then
                return
            end
        end
    end
end

local function StartScan()
    if scan then
        Say("A scan is already running")
        return
    end
    if not auctionOpen then
        Say("Open a faction capital auction house first")
        return
    end
    if capitals[auctionMap] ~= UnitFactionGroup("player")
        or C_Map.GetBestMapForUnit("player") ~= auctionMap then
        Say("Scan only in your faction's capital auction houses. Neutral and other locations are not supported")
        return
    end
    local now = GetServerTime()
    local remaining = scanCooldown - (now - (JJAuctionPrices.lastScanAttempt or 0))
    if remaining > 0 then
        Say("Local scan cooldown: " .. math.ceil(remaining / 60) .. " minutes remaining")
        return
    end
    scan = { marketKey = MarketKey(), lowest = {}, pending = {}, index = 0, deadline = GetTime() + scanTimeout }
    JJAuctionPrices.lastScanAttempt = now
    events:SetScript("OnUpdate", ProcessScan)
    Say("Full scan started. Keep the auction house open")
    C_AuctionHouse.ReplicateItems()
end

StaticPopupDialogs.JJ_CLEAR_AUCTION_PRICES = {
    text = "Clear auction prices and history for %s?",
    button1 = YES,
    button2 = NO,
    OnAccept = function(_, marketKey)
        if scan and scan.marketKey == marketKey then
            StopScan()
        end
        JJAuctionPrices.markets[marketKey] = nil
        Say("Cleared auction prices and history for " .. marketKey)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function addon.AuctionHouseCommand(command)
    if not enabled then
        Say("Enable Auction house prices in /jj, then click Reload")
        return
    end
    if command == "scan" then
        StartScan()
    else
        local key = MarketKey()
        StaticPopup_Show("JJ_CLEAR_AUCTION_PRICES", key, nil, key)
    end
end

local function AddPrices(tooltip, data)
    if data ~= tooltip:GetPrimaryTooltipData() then
        return
    end
    local _, link = TooltipUtil.GetDisplayedItem(tooltip)
    local key = ItemKey(link)
    local market = JJAuctionPrices.markets[MarketKey()]
    local lowest = market and market.lowest[key]
    local samples = market and market.history[key]
    local prices = {}
    local day = Day()
    if samples then
        for sampleDay, price in pairs(samples) do
            if sampleDay >= day - 13 and sampleDay <= day then
                table.insert(prices, price)
            end
        end
    end
    table.sort(prices)
    local median
    local count = #prices
    if count > 0 then
        median = (prices[math.floor((count + 1) / 2)] + prices[math.ceil((count + 1) / 2)]) / 2
    end
    local function Money(price)
        return price and C_CurrencyInfo.GetCoinTextureString(math.ceil(price)) or "Unavailable"
    end
    tooltip:AddDoubleLine("AH lowest / unit", Money(lowest), 1, 0.82, 0, 1, 1, 1)
    tooltip:AddDoubleLine("AH median (14d) / unit", Money(median), 1, 0.82, 0, 1, 1, 1)
end

addon.RegisterFeature("auctionHousePrices", "Auction house prices", function(value)
    enabled = value
    if not enabled then
        return
    end
    JJAuctionPrices = JJAuctionPrices or { markets = {} }
    for _, market in pairs(JJAuctionPrices.markets) do
        Prune(market.history, Day() - 13)
    end
    events:RegisterEvent("AUCTION_HOUSE_SHOW")
    events:RegisterEvent("AUCTION_HOUSE_CLOSED")
    events:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
    events:SetScript("OnEvent", function(_, event)
        if event == "AUCTION_HOUSE_SHOW" then
            auctionOpen = true
            auctionMap = C_Map.GetBestMapForUnit("player")
        elseif event == "AUCTION_HOUSE_CLOSED" then
            auctionOpen = false
            if scan then
                StopScan("Scan cancelled because the auction house closed")
            end
        elseif scan and not scan.count then
            scan.count = C_AuctionHouse.GetNumReplicateItems()
        end
    end)
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AddPrices)
end)
