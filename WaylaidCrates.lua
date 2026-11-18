local _, addon = ...

local function AddCrateInfo(tooltip, data)
    if data ~= tooltip:GetPrimaryTooltipData() then return end
    local crate = addon.WaylaidCratesData[data.id]
    if not crate then return end

    if crate.unlabeled then
        tooltip:AddDoubleLine("Fill cost / Favor", "Read label first", 1, 0.82, 0, 1, 1, 1)
        return
    end

    local cheapestCost, missing
    if crate.options then
        local cheapest
        for _, option in ipairs(crate.options) do
            -- These fixed trade goods use their plain base variant, not an arbitrary item-ID match.
            -- Lookup keeps its normal suffix/bonus rules. No item data requests or variant search.
            local link = "item:" .. option[1] .. ":0:0:0:0:0:0:0:0:0:0:0:0"
            local price = addon.AuctionPrices.Lookup(link)
            if price then
                local cost = price * option[2]
                if not cheapestCost or cost < cheapestCost then
                    cheapest, cheapestCost = option, cost
                end
            else
                missing = true
            end
        end
        local label, value = "Fill cost (AH)", "Unavailable"
        if cheapest then
            label = (missing and "Lowest known fill (AH): " or "Cheapest fill (AH): ")
                .. cheapest[2] .. " " .. cheapest[3]
            value = C_CurrencyInfo.GetCoinTextureString(math.ceil(cheapestCost))
        end
        tooltip:AddDoubleLine(label, value, 1, 0.82, 0, 1, 1, 1)
    else
        cheapestCost = 0
    end

    local label = crate.options and "Merchant's Favor (filled, base)" or "Merchant's Favor (base)"
    local favor = crate.favor and tostring(crate.favor) or "Unconfirmed"
    tooltip:AddDoubleLine(label, favor, 1, 0.82, 0, 1, 1, 1)

    local _, link = TooltipUtil.GetDisplayedItem(tooltip)
    local cratePrice = addon.AuctionPrices.Lookup(link)
    local ratio = "Unavailable"
    if crate.favor and cratePrice and cheapestCost and cratePrice + cheapestCost > 0 then
        ratio = string.format("%.2f", crate.favor * 10000 / (cratePrice + cheapestCost))
    end
    label = missing and "Favor / gold (known fill)" or "Favor / gold"
    tooltip:AddDoubleLine(label, ratio, 1, 0.82, 0, 1, 1, 1)
end

addon.RegisterFeature("waylaidCrates", "Waylaid crate tooltips", function(enabled)
    if not enabled then return end
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, AddCrateInfo)
end)
