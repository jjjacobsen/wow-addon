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

    local function SaleEligibility(record)
        if not record or record.bindType == nil or record.bindToAccount == nil
            or record.bindToAccountUntilEquip == nil then return nil, "Output binding unavailable" end
        local bindType = record.bindType
        if (bindType ~= Enum.ItemBind.None and bindType ~= Enum.ItemBind.OnEquip and bindType ~= Enum.ItemBind.OnUse)
            or record.bindToAccount or record.bindToAccountUntilEquip then
            return false, "Output cannot be auctioned (binding)"
        end
        return true
    end

    local function SalePrice(link, record)
        if not link then return nil, "Output item data unavailable" end
        local eligible, reason = SaleEligibility(record)
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
        local vendor = addon.VendorPrices[line.itemID]
        local price = vendor or Price(line.link)
        local source = character.gold.prices == "median" and "AH median (14d)" or "AH latest lowest"
        line.source = vendor and "Vendor base price" or source .. " estimate"
        line.unitPrice = price
        line.cost = price and price * line.quantity
        AddCost(entry, line.cost, 0)
    end

    local function FarmRaw(itemID)
        local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
        return profession.farmRaw and profession.farmRaw[itemID]
            and classID == Enum.ItemClass.Tradegoods and subclassID == 6
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
            local key = addon.AuctionPrices.ItemKey(link)
            local farm = character.gold.materials == "farm"
            local expanded = farm or character.gold.materials == "raw"
            if expanded and link and FarmRaw(ingredient.itemID) then
                if farm then
                    local price = SalePrice(link, catalog.items[ingredient.itemID])
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
            local eligible = SaleEligibility(recipe)
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
                    entry.supply, entry.listings = addon.AuctionPrices.Supply(link)
                    Ingredients(recipeID, 1, entry, producers, {}, 0)
                    local price, reason = SalePrice(link, recipe)
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

    function profession.DetailBasket(recipeID, crafts, mode, bags)
        Inputs()
        local recipe = catalog and catalog.recipes[recipeID]
        if not recipe then
            return { recipeID = recipeID, crafts = crafts, lines = {}, issues = { "Recipe unavailable" }, valid = false }
        end
        local basket = { recipe = recipe, recipeID = recipeID, link = OutputLink(recipe), crafts = crafts,
            quantity = recipe.quantity and recipe.quantity * crafts, lines = {}, issues = {}, valid = true }
        local producers, lines, remaining, surplus, path = Producers(), {}, {}, {}, {}
        local expanded = mode == "raw" or mode == "farm"
        for key, quantity in pairs(bags) do remaining[key] = quantity end
        local function Problem(message)
            basket.valid = false
            table.insert(basket.issues, message)
        end
        local Expand
        local function Need(itemID, quantity, depth)
            local link = ItemLink(itemID)
            local key = addon.AuctionPrices.ItemKey(link)
            if not key then Problem("Item data unavailable: " .. itemID) return end
            local line = lines[key]
            if not line then
                line = { key = key, link = link, itemID = itemID, required = 0, owned = 0,
                    made = 0, need = 0, depth = depth, vendor = addon.VendorPrices[itemID] }
                lines[key] = line
                table.insert(basket.lines, line)
            end
            line.required = line.required + quantity
            local owned = math.min(quantity, remaining[key] or 0)
            remaining[key] = (remaining[key] or 0) - owned
            line.owned, quantity = line.owned + owned, quantity - owned
            local made = math.min(quantity, surplus[key] or 0)
            surplus[key] = (surplus[key] or 0) - made
            quantity = quantity - made
            if quantity == 0 then return end
            if expanded and profession.farmRaw and profession.farmRaw[itemID]
                and (mode == "raw" or FarmRaw(itemID)) then
                line.need = line.need + quantity
                line.farm = mode == "farm"
                line.source = line.farm and "Farm" or "AH"
            elseif expanded and profession.saltShaker and itemID == 15409 then
                line.expanded = true
                line.made = line.made + quantity
                line.source = "Salt Shaker: " .. line.made .. " use(s), 71-hour cooldown each"
                table.insert(basket.issues, "Salt Shaker and LW 250 required. Shared 71-hour cooldown, availability not checked"
                    .. ". Device and cooldown value excluded")
                Need(8150, quantity, depth + 1)
            elseif expanded and producers[key] then
                local choices = producers[key]
                if #choices ~= 1 then Problem("Multiple producers: " .. link) return end
                local subID = choices[1]
                local sub = catalog.recipes[subID]
                if not sub.quantity or sub.quantity <= 0 then Problem("Intermediary yield unavailable: " .. link) return end
                local batches = math.ceil(quantity / sub.quantity)
                line.expanded = true
                line.made = line.made + batches * sub.quantity
                line.crafts = (line.crafts or 0) + batches
                line.source = ("%s: %d craft(s), %d produced"):format(profession.shortName, line.crafts, line.made)
                Expand(subID, batches, depth + 1)
                surplus[key] = (surplus[key] or 0) + batches * sub.quantity - quantity
            else
                line.need = line.need + quantity
                line.source = line.vendor and "Vendor base price" or "AH"
            end
        end
        Expand = function(id, batches, depth)
            local sub = catalog.recipes[id]
            if path[id] then Problem("Cyclic intermediary: " .. (sub.name or id)) return end
            if sub.unavailable or not sub.ingredients or not sub.quantity then
                Problem(sub.unavailable or "Recipe ingredients unavailable")
                return
            end
            RequireLearned(basket, id, depth > 0)
            path[id] = true
            for _, ingredient in ipairs(sub.ingredients) do Need(ingredient.itemID, ingredient.quantity * batches, depth) end
            path[id] = nil
        end
        Expand(recipeID, crafts, 0)
        for _, line in ipairs(basket.lines) do
            line.unitPrice = line.farm and 0 or line.vendor or Price(line.link)
        end
        local reason
        basket.savedPrice, reason = SalePrice(basket.link, recipe)
        if reason then Issue(basket, reason) end
        return basket
    end

    function profession.InitializeGold()
        Inputs()
        character.gold = character.gold or { materials = "buy", prices = "lowest", includeUnlearned = false }
        if profession.excludeGear and character.gold.excludeGear == nil then character.gold.excludeGear = false end
        character.goldVendor = nil
    end
end
