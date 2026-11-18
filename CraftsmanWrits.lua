local _, addon = ...

local function AddWritInfo(tooltip, data)
    if data ~= tooltip:GetPrimaryTooltipData() then return end
    local writ = addon.CraftsmanWritsData[data.id]
    if not writ then return end

    local requestedCost
    if writ.requirements and not writ.unpriced then
        requestedCost = 0
        for _, requirement in ipairs(writ.requirements) do
            -- Fixed requested items use their plain base variant, with the normal AH key rules.
            -- No cheapest-across-suffixes search, item loads, or bag deductions.
            local link = "item:" .. requirement[1] .. ":0:0:0:0:0:0:0:0:0:0:0:0"
            local price = addon.AuctionPrices.Lookup(link)
            if not price then
                requestedCost = nil
                break
            end
            requestedCost = requestedCost + price * requirement[2]
        end
    end

    local _, link = TooltipUtil.GetDisplayedItem(tooltip)
    local writPrice = addon.AuctionPrices.Lookup(link)
    local total = writPrice and requestedCost and writPrice + requestedCost
    local cost = total and C_CurrencyInfo.GetCoinTextureString(math.ceil(total)) or "Unavailable"
    tooltip:AddDoubleLine("Total cost (writ + items, AH)", cost, 1, 0.82, 0, 1, 1, 1)

    local faction = addon.CraftsmanWritFactions[UnitFactionGroup("player")]
    local label = "Reputation (base)" .. (faction and ": " .. faction.name or "")
    local reputation = faction and writ.reputation
    tooltip:AddDoubleLine(label, reputation and tostring(reputation) or "Unavailable", 1, 0.82, 0, 1, 1, 1)

    local ratio = "Unavailable"
    if reputation and total and total > 0 then
        ratio = string.format("%.2f", reputation * 10000 / total)
    end
    tooltip:AddDoubleLine("Base rep / gold (higher is better)", ratio, 1, 0.82, 0, 1, 1, 1)
end

addon.RegisterFeature("craftsmanWrits", "Craftsman's writ tooltips", function(enabled)
    if not enabled then return end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AddWritInfo)
end)
