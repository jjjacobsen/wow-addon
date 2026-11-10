local _, addon = ...
local enabled, auctionOpen, auctionMap, scan, scanButton
local events = CreateFrame("Frame")
local scanCooldown = 15 * 60
local scanTimeout = 300
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
    for index = 1, math.max(12, #fields) do
        if not fields[index] or fields[index] == "" then
            fields[index] = "0"
        end
    end
    -- Ignore player-applied enchants/gems, unique ID, viewer level/spec and source context.
    -- Keep the suffix and all bonus/modifier fields, never just the item ID.
    for index = 2, 6 do
        fields[index] = "0"
    end
    for index = 8, 10 do
        fields[index] = "0"
    end
    fields[12] = "0"
    while fields[#fields] == "0" do
        table.remove(fields)
    end
    return table.concat(fields, ":")
end

-- Index older saved keys without changing the saved scan or history.
local indexedMarket, indexedLowest, indexedHistory
local function IndexMarket(market)
    if market == indexedMarket then return end
    indexedMarket, indexedLowest, indexedHistory = market, {}, {}
    for key, price in pairs(market.lowest) do
        local normalized = ItemKey("item:" .. key)
        indexedLowest[normalized] = math.min(indexedLowest[normalized] or price, price)
    end
    for key, samples in pairs(market.history) do
        local normalized = ItemKey("item:" .. key)
        local history = indexedHistory[normalized] or {}
        indexedHistory[normalized] = history
        for day, price in pairs(samples) do
            history[day] = math.min(history[day] or price, price)
        end
    end
end

-- Read-only access to this character's market, including when scanning/tooltips are disabled.
local function Lookup(link)
    local marketKey = MarketKey()
    local market = JJAuctionPrices and JJAuctionPrices.markets[marketKey]
    if market then IndexMarket(market) end
    local key = ItemKey(link)
    local lowest = market and indexedLowest[key]
    local samples = market and indexedHistory[key]
    local prices, day = {}, Day()
    if samples then
        for sampleDay, price in pairs(samples) do
            if sampleDay >= day - 13 and sampleDay <= day then
                table.insert(prices, price)
            end
        end
    end
    table.sort(prices)
    local count, median = #prices
    if count > 0 then
        median = (prices[math.floor((count + 1) / 2)] + prices[math.ceil((count + 1) / 2)]) / 2
    end
    return lowest, median, market and market.scannedAt, marketKey
end
addon.AuctionPrices = { Lookup = Lookup, ItemKey = ItemKey }

local function StopScan(message)
    scan = nil
    events:SetScript("OnUpdate", nil)
    if scanButton then scanButton:Enable() end
    if message then
        Say(message .. ". Previous prices kept")
    end
end

local function CommitScan()
    local market = JJAuctionPrices.markets[scan.marketKey]
    if market then IndexMarket(market) end
    local history = market and indexedHistory or {}
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
    addon.Leatherworking.UpdateWindow()
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

local function ReportProgress(now)
    if now < scan.nextProgress then return end
    scan.nextProgress = now + 10
    local message = "Scan progress: " .. math.floor(now - scan.startedAt) .. "s elapsed, "
    if not scan.count then
        Say(message .. "waiting for server auction list")
    else
        local stage = scan.index < scan.count and "processing auctions" or "waiting for item data"
        Say(message .. stage .. ", " .. scan.processed .. "/" .. scan.count
            .. " auctions processed, " .. #scan.pending .. " checked rows waiting for item data")
    end
end

local function ProcessScan()
    local now = GetTime()
    if now >= scan.deadline then
        if scan.count then
            StopScan("Scan timed out after " .. scanTimeout .. " seconds: " .. scan.processed .. "/" .. scan.count
                .. " auctions processed, " .. #scan.pending .. " checked rows still waiting for item data")
        else
            StopScan("Scan timed out after " .. scanTimeout .. " seconds without a server auction list"
                .. ". The request may be throttled. Wait for the 15-minute scan cooldown before retrying")
        end
        return
    end
    if MarketKey() ~= scan.marketKey or C_Map.GetBestMapForUnit("player") ~= auctionMap then
        StopScan("Scan cancelled because the market or location changed")
        return
    end
    ReportProgress(now)
    if not scan.count then
        return
    end
    if C_AuctionHouse.GetNumReplicateItems() ~= scan.count then
        StopScan("Auction data changed during the scan")
        return
    end
    local budget = 200
    while scan.index < scan.count and budget > 0 do
        local index = scan.index
        scan.index = index + 1
        budget = budget - 1
        if ReadAuction(index) then
            scan.processed = scan.processed + 1
        else
            table.insert(scan.pending, index)
        end
    end
    -- Rotate through unfinished rows so one missing item cannot block the others.
    for _ = 1, math.min(budget, #scan.pending) do
        if scan.pendingIndex > #scan.pending then scan.pendingIndex = 1 end
        local position = scan.pendingIndex
        if ReadAuction(scan.pending[position]) then
            scan.processed = scan.processed + 1
            scan.pending[position] = scan.pending[#scan.pending]
            scan.pending[#scan.pending] = nil
        else
            scan.pendingIndex = position + 1
        end
    end
    if scan.index == scan.count and #scan.pending == 0 then
        CommitScan()
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
    local startedAt = GetTime()
    scan = {
        marketKey = MarketKey(), lowest = {}, pending = {}, pendingIndex = 1, index = 0, processed = 0,
        startedAt = startedAt, nextProgress = startedAt + 10, deadline = startedAt + scanTimeout,
    }
    JJAuctionPrices.lastScanAttempt = now
    if scanButton then scanButton:Disable() end
    events:SetScript("OnUpdate", ProcessScan)
    Say("Full scan started. Keep the auction house open")
    C_AuctionHouse.ReplicateItems()
end

local function CreateScanButton()
    if scanButton or not AuctionHouseFrame then return end
    local searchBar = AuctionHouseFrame.SearchBar
    scanButton = CreateFrame("Button", nil, searchBar, "UIPanelButtonTemplate")
    scanButton:SetSize(64, 22)
    scanButton:SetPoint("RIGHT", searchBar.FilterButton, "LEFT", -8, 0)
    scanButton:SetText("Scan")
    scanButton:SetScript("OnClick", StartScan)
    scanButton:SetEnabled(not scan)
    events:UnregisterEvent("ADDON_LOADED")
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
        addon.Leatherworking.UpdateWindow()
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
    local location = data.guid and C_Item.GetItemLocation(data.guid)
    if location and C_Item.IsBound(location) then
        return
    end
    for _, line in ipairs(data.lines) do
        if line.type == Enum.TooltipDataLineType.ItemBinding
            and line.bonding == Enum.TooltipDataItemBinding.Soulbound then
            return
        end
    end
    local _, link = TooltipUtil.GetDisplayedItem(tooltip)
    local lowest, median = Lookup(link)
    local function Money(price)
        return price and C_CurrencyInfo.GetCoinTextureString(math.ceil(price)) or "Unavailable"
    end
    tooltip:AddDoubleLine("AH lowest / unit", Money(lowest), 1, 0.82, 0, 1, 1, 1)
    tooltip:AddDoubleLine("AH median (14d) / unit", Money(median), 1, 0.82, 0, 1, 1, 1)
    local quantity = location and C_Item.GetStackCount(location)
    if quantity and quantity > 1 then
        tooltip:AddDoubleLine("AH lowest ×" .. quantity, Money(lowest and lowest * quantity), 1, 0.82, 0, 1, 1, 1)
        tooltip:AddDoubleLine("AH median (14d) ×" .. quantity, Money(median and median * quantity), 1, 0.82, 0, 1, 1, 1)
    end
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
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("AUCTION_HOUSE_SHOW")
    events:RegisterEvent("AUCTION_HOUSE_CLOSED")
    events:RegisterEvent("REPLICATE_ITEM_LIST_UPDATE")
    events:SetScript("OnEvent", function(_, event, loadedAddon)
        if event == "ADDON_LOADED" then
            if loadedAddon == "Blizzard_AuctionHouseUI" then CreateScanButton() end
        elseif event == "AUCTION_HOUSE_SHOW" then
            auctionOpen = true
            auctionMap = C_Map.GetBestMapForUnit("player")
            CreateScanButton()
        elseif event == "AUCTION_HOUSE_CLOSED" then
            auctionOpen = false
            if scan then
                StopScan("Scan cancelled because the auction house closed")
            end
        elseif event == "REPLICATE_ITEM_LIST_UPDATE" and scan and not scan.count then
            scan.count = C_AuctionHouse.GetNumReplicateItems()
        end
    end)
    CreateScanButton()
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AddPrices)
end)
