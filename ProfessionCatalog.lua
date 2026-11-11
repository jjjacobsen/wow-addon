local _, addon = ...

-- Native profession capture. Only an explicit scan publishes a new catalog.
function addon.AttachProfessionCatalog(profession)
    local active
    local events = CreateFrame("Frame")
    local function Catalog() return _G[profession.catalogName] end
    local function Character() return _G[profession.characterName] end

    function profession.OwnProfessionOpen()
        if not ProfessionsFrame or not ProfessionsFrame:IsShown()
            or not ProfessionsFrame.CraftingPage:IsShown() then return false end
        local info = C_TradeSkillUI.GetBaseProfessionInfo()
        return info and info.professionID == profession.id
            and not C_TradeSkillUI.IsTradeSkillLinked()
            and not C_TradeSkillUI.IsTradeSkillGuild()
            and not C_TradeSkillUI.IsTradeSkillGuildMember()
            and not C_TradeSkillUI.IsNPCCrafting()
    end

    local function ReadItem(item)
        if profession.ReadItem then return profession.ReadItem(item) end
        local name, link = C_Item.GetItemInfo(item.itemID)
        if not name or not link then return false end
        item.link, item.loaded = link, true
        return true
    end

    local function ScanReady()
        return profession.OwnProfessionOpen() and not C_TradeSkillUI.IsDataSourceChanging()
            and C_TradeSkillUI.IsTradeSkillReady()
    end

    local function Finish(message, complete)
        local run = active
        run.ticker:Cancel()
        run.timeout:Cancel()
        if complete then
            run.catalog.trainerRequirements = Catalog() and Catalog().trainerRequirements
            _G[profession.catalogName] = run.catalog
            Character().learned = run.learned
        end
        active = nil
        events:UnregisterEvent("ITEM_DATA_LOAD_RESULT")
        print("wow-addon: " .. profession.name .. " scan " .. message)
        profession.UpdateWindow(false)
    end

    local function CancelScan()
        if active then Finish("cancelled. Previous catalog kept") end
    end

    local function CaptureSchematic(recipeID, run)
        local recipe = run.catalog.recipes[recipeID]
        local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
        local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
        if not schematic or not info then return false end
        recipe.name = info.name
        recipe.unavailable = (info.supportsQualities or info.isRecraft or info.isSalvageRecipe)
            and "Unsupported output variant" or nil
        run.learned[recipeID] = run.learned[recipeID] or info.learned
        if not recipe.itemID then
            local itemID = schematic.outputItemID
            if itemID and itemID > 0 then
                recipe.itemID = itemID
                if not run.catalog.items[itemID] then
                    run.catalog.items[itemID] = { itemID = itemID }
                    table.insert(run.itemIDs, itemID)
                else
                    run.catalog.items[itemID].ingredientOnly = nil
                end
            else
                recipe.nonItem = schematic.recipeType == Enum.TradeskillRecipeType.Enchant
                    or schematic.recipeType == Enum.TradeskillRecipeType.Gathering
            end
        end
        recipe.quantity = schematic.quantityMin
        recipe.quantityMax = schematic.quantityMax
        if not recipe.quantity or recipe.quantity <= 0 then
            recipe.unavailable = "Output quantity unavailable"
        elseif schematic.recipeType ~= Enum.TradeskillRecipeType.Item then
            recipe.unavailable = "Unsupported recipe output"
        end
        local ingredients = {}
        for _, slot in ipairs(schematic.reagentSlotSchematics) do
            if slot.required then
                local reagent = slot.reagents[1]
                if #slot.reagents ~= 1 or not reagent.itemID or reagent.currencyID
                    or slot.reagentType ~= Enum.CraftingReagentType.Basic
                    or #slot.variableQuantities > 0 or slot.quantityRequired <= 0 then
                    recipe.unavailable = "Unsupported required reagent choice"
                else
                    table.insert(ingredients, { itemID = reagent.itemID, quantity = slot.quantityRequired })
                    if not run.catalog.items[reagent.itemID] then
                        run.catalog.items[reagent.itemID] = { itemID = reagent.itemID, ingredient = true, ingredientOnly = true }
                        table.insert(run.itemIDs, reagent.itemID)
                    else
                        run.catalog.items[reagent.itemID].ingredient = true
                    end
                end
            end
        end
        recipe.ingredients = ingredients
        return true
    end

    local function CaptureRequirement(pattern, run)
        if pattern.failed then return true end
        if not C_Item.IsItemDataCachedByID(pattern.itemID) then
            if not pattern.requestedAt then
                pattern.requestedAt = GetTime()
                run.patternPending[pattern.itemID] = pattern
                C_Item.RequestLoadItemDataByID(pattern.itemID)
            end
            return GetTime() - pattern.requestedAt >= 10
        end
        pattern.attempts = pattern.attempts + 1
        local tooltip = C_TooltipInfo.GetItemByID(pattern.itemID)
        if tooltip then
            for _, line in ipairs(tooltip.lines) do
                if line.type == Enum.TooltipDataLineType.UsageRequirement
                    and line.requirementType == Enum.TooltipDataUsageRequirementType.Skill and line.leftText then
                    local skill = tonumber(line.leftText:match(run.requirementPattern))
                    if skill then
                        run.catalog.recipes[pattern.recipeID].requiredSkill = skill
                        return true
                    end
                end
            end
        end
        return pattern.attempts >= 3
    end

    local function Tick()
        local run = active
        if not ScanReady() or C_TradeSkillUI.GetBaseProfessionInfo().sourceCounter ~= run.sourceCounter then
            CancelScan()
            return
        end
        for _ = 1, 10 do
            local recipeID = run.recipeIDs[run.recipeIndex]
            if not recipeID or not CaptureSchematic(recipeID, run) then break end
            run.recipeIndex = run.recipeIndex + 1
        end
        for _ = 1, 10 do
            local itemID = run.itemIDs[run.index]
            if not itemID then break end
            run.index = run.index + 1
            local item = run.catalog.items[itemID]
            if not ReadItem(item) then
                run.pending[itemID] = true
                C_Item.RequestLoadItemDataByID(itemID)
            end
        end
        for _ = 1, math.min(10, #run.patterns - run.patternIndex + 1) do
            local pattern = run.patterns[run.patternIndex]
            run.patternIndex = run.patternIndex + 1
            if not CaptureRequirement(pattern, run) then table.insert(run.patterns, pattern) end
        end
        if run.recipeIndex > #run.recipeIDs and run.index > #run.itemIDs and not next(run.pending)
            and run.patternIndex > #run.patterns then
            local missing = 0
            for _, item in pairs(run.catalog.items) do
                if not item.loaded or (item.slot and not item.stats) then missing = missing + 1 end
            end
            local unresolved, requirements = 0, 0
            for recipeID, recipe in pairs(run.catalog.recipes) do
                if not recipe.itemID and not recipe.nonItem then unresolved = unresolved + 1 end
                if profession.RequiredSkill(recipeID, recipe) then requirements = requirements + 1 end
            end
            Finish(("complete: %d recipes, %d items unavailable, %d outputs unresolved, %d %s requirements known")
                :format(#run.recipeIDs, missing, unresolved, requirements, profession.shortName), true)
        end
    end

    function profession.ScanRecipes()
        if active then
            print("wow-addon: " .. profession.name .. " scan already active")
            return
        end
        if not ScanReady() then
            print("wow-addon: Open your own " .. profession.name .. " and wait for recipes, then use " .. profession.scanCommand)
            return
        end
        local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs()
        if #recipeIDs == 0 then
            print("wow-addon: " .. profession.name .. " recipes are not ready. Use " .. profession.scanCommand .. " when they load")
            return
        end
        local info = C_TradeSkillUI.GetBaseProfessionInfo()
        local requirementPattern = ITEM_MIN_SKILL:format(info.professionName, 987654321)
            :gsub("(%W)", "%%%1"):gsub("987654321", "(%%d+)")
        local recipes, learned, itemIDs, items, patterns = {}, {}, {}, {}, {}
        table.sort(recipeIDs)
        for _, recipeID in ipairs(recipeIDs) do
            local output = C_TradeSkillUI.GetRecipeOutputItemData(recipeID)
            local itemID = output and output.itemID
            if (not itemID or itemID <= 0) and output and output.hyperlink then
                itemID = tonumber(output.hyperlink:match("item:(%d+)"))
            end
            if itemID and itemID <= 0 then itemID = nil end
            recipes[recipeID] = { itemID = itemID, link = output and output.hyperlink }
            local patternID = profession.patterns[recipeID]
            if patternID then
                table.insert(patterns, { recipeID = recipeID, itemID = patternID, attempts = 0 })
            end
            if itemID and not items[itemID] then
                items[itemID] = { itemID = itemID }
                table.insert(itemIDs, itemID)
            end
        end
        active = {
            catalog = { recipes = recipes, items = items }, learned = learned,
            itemIDs = itemIDs, index = 1, pending = {}, recipeIDs = recipeIDs, recipeIndex = 1,
            sourceCounter = info.sourceCounter,
            patterns = patterns, patternIndex = 1, patternPending = {},
            requirementPattern = "^" .. requirementPattern .. "$",
        }
        events:RegisterEvent("ITEM_DATA_LOAD_RESULT")
        active.ticker = C_Timer.NewTicker(0.2, Tick)
        active.timeout = C_Timer.NewTimer(60, function()
            Finish("timed out after 60 seconds. Previous catalog kept")
        end)
        print("wow-addon: " .. profession.name .. " scan started. Keep your own " .. profession.name .. " open")
        profession.UpdateWindow(false)
    end

    function profession.IsRefreshing() return active ~= nil end

    function profession.InitializeCatalog()
        events:RegisterEvent("TRADE_SKILL_CLOSE")
        events:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGING")
        events:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
        events:RegisterEvent("NEW_RECIPE_LEARNED")
        events:SetScript("OnEvent", function(_, event, itemID, success)
            if event == "ITEM_DATA_LOAD_RESULT" then
                if active.pending[itemID] then
                    if success then ReadItem(active.catalog.items[itemID]) end
                    active.pending[itemID] = nil
                end
                local pattern = active.patternPending[itemID]
                if pattern then
                    pattern.failed = not success
                    active.patternPending[itemID] = nil
                end
            elseif event == "NEW_RECIPE_LEARNED" then
                if not (Catalog() and Catalog().recipes[itemID]) then
                    if not C_TradeSkillUI.GetRecipeInfo(itemID) then return end
                    local info = C_TradeSkillUI.GetProfessionInfoByRecipeID(itemID)
                    if info.professionID ~= profession.id and info.parentProfessionID ~= profession.id then return end
                end
                Character().learned[itemID] = true
                if active then active.learned[itemID] = true end
                profession.UpdateWindow(false)
            else
                CancelScan()
            end
        end)
    end
end
