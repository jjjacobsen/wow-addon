local _, addon = ...

function addon.AttachProfessionProfit(profession)
    local catalog, character
    local function Inputs()
        catalog, character = _G[profession.catalogName], _G[profession.characterName]
    end

    local function ItemLink(itemID)
        local item = catalog.items[itemID]
        return item and item.link
    end

    local function OutputLink(recipe)
        local cachedLink = recipe.itemID and ItemLink(recipe.itemID)
        local link = recipe.link or cachedLink
        -- Recipe previews can keep placeholder quality and empty labels after item data has loaded.
        local color = cachedLink and cachedLink:match("^(|c.-)|H")
        if link and color then
            link = link:gsub("^|c.-|H", function() return color .. "|H" end, 1)
        end
        local label = cachedLink and cachedLink:match("|h(%b[])|h")
        if link and label then
            link = link:gsub("|h%[%]|h", function() return "|h" .. label .. "|h" end, 1)
        end
        return addon.AuctionPrices.NormalizeLink(link)
    end

    local function Price(link)
        local lowest, median = addon.AuctionPrices.Lookup(link)
        if character.gold.prices == "median" then return median end
        return lowest
    end

    local function SaleEligibility(link)
        if not link then return nil, "Output item data unavailable" end
        local name, _, _, _, _, _, _, _, _, _, _, _, _, bindType = C_Item.GetItemInfo(link)
        if not name or name == "" or bindType == nil then return nil, "Output binding unavailable" end
        if (bindType ~= Enum.ItemBind.None and bindType ~= Enum.ItemBind.OnEquip and bindType ~= Enum.ItemBind.OnUse)
            or C_Item.IsItemBindToAccount(link) or C_Item.IsItemBindToAccountUntilEquip(link) then
            return false, "Output cannot be auctioned (binding)"
        end
        return true
    end

    local function SalePrice(link, eligible, reason)
        if eligible == nil and reason == nil then eligible, reason = SaleEligibility(link) end
        if eligible ~= true then return nil, reason end
        local price = Price(link)
        return price, not price and "Output AH price unavailable" or nil
    end

    local function Issue(entry, message)
        table.insert(entry.issues, message)
    end

    local function RequireLearned(entry, recipeID, intermediary)
        local learned = character.learned[recipeID]
        if learned ~= true then
            entry.needsRecipe = true
            local name = catalog.recipes[recipeID].name or tostring(recipeID)
            Issue(entry, (intermediary and "Intermediary " or "Recipe ") .. name
                .. (learned == false and " is unlearned" or " has unknown learned status"))
        end
    end

    local function Producers()
        local producers = {}
        for recipeID, recipe in pairs(catalog.recipes) do
            local key = addon.AuctionPrices.ItemKey(OutputLink(recipe))
            if key and not recipe.nonItem then
                producers[key] = producers[key] or {}
                table.insert(producers[key], recipeID)
            end
        end
        return producers
    end

    local function AddCost(entry, cost, forgone)
        entry.cash = entry.cash and cost and entry.cash + cost or nil
        entry.forgone = entry.forgone and forgone and entry.forgone + forgone or nil
    end

    local function BuyIngredient(line, entry)
        local key = addon.AuctionPrices.ItemKey(line.link)
        local vendor = key and character.goldVendor[key]
        local price = vendor and vendor.price or Price(line.link)
        local source = character.gold.prices == "median" and "AH median (14d)" or "AH latest lowest"
        line.source = vendor and "Vendor observed " .. date("%Y-%m-%d %H:%M", vendor.at)
            or source .. " estimate (no vendor quote)"
        line.unitPrice = price
        line.cost = price and price * line.quantity
        AddCost(entry, line.cost, 0)
    end

    local function Ingredients(recipeID, crafts, entry, producers, path, depth)
        local recipe = catalog.recipes[recipeID]
        if path[recipeID] then
            Issue(entry, "Cyclic " .. profession.name .. " intermediary: " .. (recipe.name or recipeID))
            entry.cash, entry.forgone = nil, nil
            return
        end
        RequireLearned(entry, recipeID, depth > 0)
        if recipe.unavailable or not recipe.ingredients or not recipe.quantity then
            Issue(entry, recipe.unavailable or "Open your own " .. profession.name .. " and use " .. profession.scanCommand .. " for ingredients")
            entry.cash, entry.forgone = nil, nil
            return
        end
        path[recipeID] = true
        for _, ingredient in ipairs(recipe.ingredients) do
            local link = ItemLink(ingredient.itemID)
            local quantity = ingredient.quantity * crafts
            local line = { link = link, itemID = ingredient.itemID, quantity = quantity, depth = depth }
            table.insert(entry.lines, line)
            local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(ingredient.itemID)
            local key = addon.AuctionPrices.ItemKey(link)
            local farm = character.gold.materials == "farm"
            local expanded = farm or character.gold.materials == "raw"
            if expanded and link and profession.farmRaw and profession.farmRaw[ingredient.itemID]
                and classID == Enum.ItemClass.Tradegoods and subclassID == 6 then
                if farm then
                    local price = SalePrice(link)
                    line.source, line.cost = "Farmed, zero cash", 0
                    line.forgone = price and price * quantity
                    AddCost(entry, 0, line.forgone)
                else
                    BuyIngredient(line, entry)
                end
            elseif expanded and profession.saltShaker and ingredient.itemID == 15409 then
                -- Forever 70888: Salt Shaker (19566), not a native LW recipe.
                -- One Deeprock Salt (8150) makes one Refined Deeprock Salt (15409).
                line.expanded = true
                line.source = ("Salt Shaker: %d use(s), %d produced"):format(quantity, quantity)
                Issue(entry, "Salt Shaker and LW 250 required. Shared 71-hour cooldown, availability not checked"
                    .. ". Device and cooldown value excluded")
                local salt = { link = ItemLink(8150), itemID = 8150, quantity = quantity, depth = depth + 1 }
                table.insert(entry.lines, salt)
                BuyIngredient(salt, entry)
            elseif expanded and key and producers[key] then
                local choices = producers[key]
                if #choices ~= 1 then
                    line.source = "Unavailable: multiple " .. profession.shortName .. " producers"
                    AddCost(entry, nil, nil)
                else
                    local subID = choices[1]
                    local sub = catalog.recipes[subID]
                    if not sub.quantity or sub.quantity <= 0 then
                        RequireLearned(entry, subID, true)
                        line.source = "Unavailable: intermediary yield"
                        AddCost(entry, nil, nil)
                    else
                        local batches = math.ceil(quantity / sub.quantity)
                        line.expanded = true
                        line.source = ("%s: %d craft(s), %d produced"):format(profession.shortName, batches, batches * sub.quantity)
                        Ingredients(subID, batches, entry, producers, path, depth + 1)
                    end
                end
            else
                BuyIngredient(line, entry)
            end
        end
        path[recipeID] = nil
    end

    function profession.GoldMaxSkill()
        Inputs()
        if character.gold.maxSkill ~= nil then return character.gold.maxSkill end
        -- The native profession book uses rank separately from rankModifier.
        for _, index in pairs({ GetProfessions() }) do
            local _, _, rank, _, _, _, skillLine = GetProfessionInfo(index)
            if skillLine == profession.id then return rank end
        end
    end

    function profession.GoldRows()
        Inputs()
        local rows, hidden, unavailable, gear = {}, 0, 0, 0
        if not catalog then return rows, hidden, unavailable, gear end
        local producers = Producers()
        local maxSkill = profession.GoldMaxSkill()
        for recipeID, recipe in pairs(catalog.recipes) do
            local requiredSkill = profession.RequiredSkill(recipeID)
            local link = OutputLink(recipe)
            local eligible, reason = SaleEligibility(link)
            if not recipe.nonItem and eligible ~= false then
                local equipLoc
                if recipe.itemID then
                    local _, _, _, location = C_Item.GetItemInfoInstant(recipe.itemID)
                    equipLoc = location
                end
                if profession.excludeGear and character.gold.excludeGear and equipLoc and equipLoc ~= ""
                    and equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" and equipLoc ~= "INVTYPE_BAG" and equipLoc ~= "INVTYPE_QUIVER" then
                    gear = gear + 1
                elseif not character.gold.includeUnlearned and character.learned[recipeID] ~= true then
                    hidden = hidden + 1
                elseif character.learned[recipeID] ~= true and maxSkill and requiredSkill
                    and requiredSkill > maxSkill then
                    hidden = hidden + 1
                else
                    local item = recipe.itemID and catalog.items[recipe.itemID]
                    local name = link and link:match("|h%[(.-)%]|h")
                    local itemAvailable = item and item.loaded and equipLoc ~= nil and name and name ~= ""
                    local entry = {
                        recipeID = recipeID, recipe = recipe, requiredSkill = requiredSkill,
                        link = itemAvailable and link or nil,
                        name = itemAvailable and link or (recipe.name and recipe.name ~= "" and recipe.name)
                            or (recipe.itemID and ("Item " .. recipe.itemID)) or ("Recipe " .. recipeID),
                        cash = 0, forgone = 0, lines = {}, issues = {},
                    }
                    Ingredients(recipeID, 1, entry, producers, {}, 0)
                    local price, reason = SalePrice(link, eligible, reason)
                    entry.sale = price and recipe.quantity and price * recipe.quantity
                    if reason then Issue(entry, reason) end
                    if entry.sale and entry.cash then
                        entry.margin = entry.sale - entry.cash
                        entry.materialMargin = entry.forgone and entry.margin - entry.forgone
                    end
                    if entry.needsRecipe and not character.gold.includeUnlearned then
                        hidden = hidden + 1
                    elseif not itemAvailable or recipe.quantity == nil
                        or entry.cash == nil or entry.sale == nil or entry.margin == nil then
                        unavailable = unavailable + 1
                    else
                        table.insert(rows, entry)
                    end
                end
            end
        end
        table.sort(rows, function(a, b)
            if a.margin ~= b.margin then
                if a.margin == nil then return false end
                if b.margin == nil then return true end
                return a.margin > b.margin
            end
            return a.recipeID < b.recipeID
        end)
        return rows, hidden, unavailable, gear
    end

    function profession.InitializeGold()
        Inputs()
        character.gold = character.gold or { materials = "buy", prices = "lowest", includeUnlearned = false }
        if profession.excludeGear and character.gold.excludeGear == nil then character.gold.excludeGear = false end
        character.goldVendor = character.goldVendor or {}
        local events = CreateFrame("Frame")
        events:RegisterEvent("MERCHANT_SHOW")
        events:RegisterEvent("MERCHANT_UPDATE")
        events:SetScript("OnEvent", function()
            Inputs()
            if not catalog then return end
            for index = 1, GetMerchantNumItems() do
                local itemID = GetMerchantItemID(index)
                local item = itemID and catalog.items[itemID]
                if item and item.ingredient then
                    local name, _, price, stackCount, _, _, _, extendedCost, currencyID = GetMerchantItemInfo(index)
                    local key = addon.AuctionPrices.ItemKey(GetMerchantItemLink(index))
                    if key and name and not extendedCost and not currencyID and stackCount > 0 then
                        character.goldVendor[key] = { price = price / stackCount, at = GetServerTime() }
                    end
                end
            end
        end)
    end
end
