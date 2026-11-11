local _, addon = ...
local lw = {}
addon.Leatherworking = lw
local enabled, active
local events = CreateFrame("Frame")
local armorProficiencies = {
    [Enum.ItemArmorSubclass.Cloth] = 9078,
    [Enum.ItemArmorSubclass.Leather] = 9077,
    [Enum.ItemArmorSubclass.Mail] = 8737,
    [Enum.ItemArmorSubclass.Plate] = 750,
}

function lw.CanWearArmor(itemID)
    local _, _, _, equipLoc, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
    if classID == nil or subclassID == nil then return nil end
    if equipLoc == "INVTYPE_CLOAK" or classID ~= Enum.ItemClass.Armor then return true end
    local spellID = armorProficiencies[subclassID]
    return not spellID or C_SpellBook.IsSpellKnown(spellID)
end

lw.slots = {
    { "All slots", 0 }, { "Head", 1 }, { "Shoulder", 3 }, { "Chest", 5 },
    { "Wrist", 9 }, { "Hands", 10 }, { "Waist", 6 }, { "Legs", 7 },
    { "Feet", 8 }, { "Back", 15 },
}
lw.equipSlots = {
    INVTYPE_HEAD = 1, INVTYPE_SHOULDER = 3, INVTYPE_CHEST = 5, INVTYPE_ROBE = 5,
    INVTYPE_WRIST = 9, INVTYPE_HAND = 10, INVTYPE_WAIST = 6, INVTYPE_LEGS = 7,
    INVTYPE_FEET = 8, INVTYPE_CLOAK = 15,
}
lw.stats = {
    { "Intellect", "ITEM_MOD_INTELLECT_SHORT" },
    { "Agility", "ITEM_MOD_AGILITY_SHORT" },
    { "Strength", "ITEM_MOD_STRENGTH_SHORT" },
    { "Stamina", "ITEM_MOD_STAMINA_SHORT" },
    { "Spirit", "ITEM_MOD_SPIRIT_SHORT" },
    { "Armor", "RESISTANCE0_NAME" },
    { "Spell damage", "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT" },
    { "Spell healing", "ITEM_MOD_SPELL_HEALING_DONE_SHORT" },
    { "Nature damage", "ITEM_MOD_NATURE_DAMAGE_DONE_SHORT" },
    { "Frost damage", "ITEM_MOD_FROST_DAMAGE_DONE_SHORT" },
    { "Attack power", "ITEM_MOD_ATTACK_POWER_SHORT" },
    { "Ranged attack power", "ITEM_MOD_RANGED_ATTACK_POWER_SHORT" },
    { "Critical strike", "ITEM_MOD_CRIT_RATING_SHORT" },
    { "Hit", "ITEM_MOD_HIT_RATING_SHORT" },
    { "Dodge", "ITEM_MOD_DODGE_RATING_SHORT" },
    { "Parry", "ITEM_MOD_PARRY_RATING_SHORT" },
    { "Mana regeneration", "ITEM_MOD_MANA_REGENERATION_SHORT" },
    { "Fire resistance", "ITEM_MOD_FIRE_RESISTANCE_SHORT" },
    { "Frost resistance", "ITEM_MOD_FROST_RESISTANCE_SHORT" },
    { "Nature resistance", "ITEM_MOD_NATURE_RESISTANCE_SHORT" },
    { "Shadow resistance", "ITEM_MOD_SHADOW_RESISTANCE_SHORT" },
    { "Arcane resistance", "ITEM_MOD_ARCANE_RESISTANCE_SHORT" },
}

function lw.OwnProfessionOpen()
    if not ProfessionsFrame or not ProfessionsFrame:IsShown()
        or not ProfessionsFrame.CraftingPage:IsShown() then return false end
    local info = C_TradeSkillUI.GetBaseProfessionInfo()
    return info and info.professionID == 165
        and not C_TradeSkillUI.IsTradeSkillLinked()
        and not C_TradeSkillUI.IsTradeSkillGuild()
        and not C_TradeSkillUI.IsTradeSkillGuildMember()
        and not C_TradeSkillUI.IsNPCCrafting()
end

local function ReadItem(item)
    local name, link, _, _, level, _, subType, _, equipLoc = C_Item.GetItemInfo(item.itemID)
    if not name or not link then return false end
    item.link, item.requiredLevel, item.subType = link, level, subType
    item.slot = lw.equipSlots[equipLoc]
    item.loaded = true
    item.stats = item.slot and C_Item.GetItemStats(link) or nil
    return not item.slot or item.stats ~= nil
end

local function ScanReady()
    return lw.OwnProfessionOpen() and not C_TradeSkillUI.IsDataSourceChanging()
        and C_TradeSkillUI.IsTradeSkillReady()
end

local function Finish(message, complete)
    local run = active
    run.ticker:Cancel()
    run.timeout:Cancel()
    if complete then
        -- Keep trainer observations made before or during this manual scan.
        run.catalog.trainerRequirements = JJLWCatalog and JJLWCatalog.trainerRequirements
        -- Publish only a finished run. Browsers keep using the saved catalog until now.
        JJLWCatalog = run.catalog
        JJLWCharacter.learned = run.learned
    end
    active = nil
    events:UnregisterEvent("ITEM_DATA_LOAD_RESULT")
    print("wow-addon: Leatherworking scan " .. message)
    lw.UpdateWindow(false)
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
        -- Missing pattern metadata must not prevent the catalog from being published.
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
            if lw.RequiredSkill(recipeID, recipe) then requirements = requirements + 1 end
        end
        Finish(("complete: %d recipes, %d items unavailable, %d outputs unresolved, %d LW requirements known")
            :format(#run.recipeIDs, missing, unresolved, requirements), true)
    end
end

local function ScanRecipes()
    if active then
        print("wow-addon: Leatherworking scan already active")
        return
    end
    if not ScanReady() then
        print("wow-addon: Open your own Leatherworking and wait for recipes, then use /jj lwscan")
        return
    end
    local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs()
    if #recipeIDs == 0 then
        print("wow-addon: Leatherworking recipes are not ready. Use /jj lwscan when they load")
        return
    end
    local profession = C_TradeSkillUI.GetBaseProfessionInfo()
    -- Match the localized native skill requirement, with only its rank captured.
    local requirementPattern = ITEM_MIN_SKILL:format(profession.professionName, 987654321)
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
        local patternID = lw.patterns[recipeID]
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
        sourceCounter = profession.sourceCounter,
        patterns = patterns, patternIndex = 1, patternPending = {},
        requirementPattern = "^" .. requirementPattern .. "$",
    }
    events:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    active.ticker = C_Timer.NewTicker(0.2, Tick)
    active.timeout = C_Timer.NewTimer(60, function()
        Finish("timed out after 60 seconds. Previous catalog kept")
    end)
    print("wow-addon: Leatherworking scan started. Keep your own Leatherworking open")
    lw.UpdateWindow(false)
end

function lw.IsRefreshing()
    return active ~= nil
end

local function RecipeLearned(recipeID)
    if not (JJLWCatalog and JJLWCatalog.recipes[recipeID]) then
        if not C_TradeSkillUI.GetRecipeInfo(recipeID) then return end
        local info = C_TradeSkillUI.GetProfessionInfoByRecipeID(recipeID)
        if info.professionID ~= 165 and info.parentProfessionID ~= 165 then return end
    end
    JJLWCharacter.learned[recipeID] = true
    if active then active.learned[recipeID] = true end
    lw.UpdateWindow(false)
end

function addon.LeatherworkingCommand()
    if not enabled then
        print("wow-addon: Enable Leatherworking gear in /jj, then click Reload")
        return
    end
    lw.ToggleWindow()
end

function addon.LeatherworkingScanCommand()
    if not enabled then
        print("wow-addon: Enable Leatherworking gear in /jj, then click Reload")
        return
    end
    ScanRecipes()
end

addon.RegisterFeature("leatherworking", "Leatherworking gear", function(value)
    enabled = value
    if not enabled then return end
    JJLWCharacter = JJLWCharacter or { stat = "ITEM_MOD_INTELLECT_SHORT", slot = 0, learned = {} }
    if JJLWCharacter.stat == "ITEM_MOD_SPELL_POWER_SHORT" then
        JJLWCharacter.stat = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"
    end
    lw.InitializeGold()
    lw.InitializeTrainer()
    events:RegisterEvent("TRADE_SKILL_CLOSE")
    events:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGING")
    events:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
    events:RegisterEvent("NEW_RECIPE_LEARNED")
    events:SetScript("OnEvent", function(_, event, itemID, success)
        if event == "ITEM_DATA_LOAD_RESULT" then
            if active.pending[itemID] then
                if success then ReadItem(active.catalog.items[itemID]) end
                -- Failed item loads are terminal too. Keep their recipe metadata.
                active.pending[itemID] = nil
            end
            local pattern = active.patternPending[itemID]
            if pattern then
                pattern.failed = not success
                active.patternPending[itemID] = nil
            end
        elseif event == "NEW_RECIPE_LEARNED" then
            RecipeLearned(itemID)
        elseif event == "TRADE_SKILL_CLOSE" or event == "TRADE_SKILL_DATA_SOURCE_CHANGING"
            or event == "TRADE_SKILL_DATA_SOURCE_CHANGED" then
            CancelScan()
        end
    end)
end)
