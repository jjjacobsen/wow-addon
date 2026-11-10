local _, addon = ...
local lw = {}
addon.Leatherworking = lw
local enabled, active, captured, queued
local QueueRefresh
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

local function Finish()
    active.ticker:Cancel()
    active.timeout:Cancel()
    active = nil
    events:UnregisterEvent("ITEM_DATA_LOAD_RESULT")
    lw.UpdateWindow()
    if not captured then QueueRefresh() end
end

local function Tick()
    local run = active
    for _ = 1, 10 do
        local itemID = run.itemIDs[run.index]
        if not itemID then break end
        run.index = run.index + 1
        local item = JJLWCatalog.items[itemID]
        if not ReadItem(item) then
            run.pending[itemID] = true
            C_Item.RequestLoadItemDataByID(itemID)
        end
    end
    if run.index > #run.itemIDs and not next(run.pending) then Finish() end
end

function lw.Refresh()
    if active then return end
    if not lw.OwnProfessionOpen() or C_TradeSkillUI.IsDataSourceChanging()
        or not C_TradeSkillUI.IsTradeSkillReady() then
        return false
    end
    local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs()
    if #recipeIDs == 0 then return false end
    local recipes, learned, itemIDs, items = {}, {}, {}, {}
    table.sort(recipeIDs)
    for _, recipeID in ipairs(recipeIDs) do
        local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
        local output = C_TradeSkillUI.GetRecipeOutputItemData(recipeID)
        local itemID = output and output.itemID
        if (not itemID or itemID <= 0) and output and output.hyperlink then
            itemID = tonumber(output.hyperlink:match("item:(%d+)"))
        end
        local nonItem
        if not itemID or itemID <= 0 then
            local schematic = C_TradeSkillUI.GetRecipeSchematic(recipeID, false)
            itemID = schematic and schematic.outputItemID
            nonItem = schematic and (schematic.recipeType == Enum.TradeskillRecipeType.Enchant
                or schematic.recipeType == Enum.TradeskillRecipeType.Gathering)
        end
        if itemID and itemID <= 0 then itemID = nil end
        recipes[recipeID] = { itemID = itemID, nonItem = not itemID and nonItem or nil }
        if info then learned[recipeID] = info.learned end
        if itemID and not items[itemID] then
            items[itemID] = { itemID = itemID }
            table.insert(itemIDs, itemID)
        end
    end
    -- Only native shared item data belongs in the account-wide catalog.
    JJLWCatalog = { recipes = recipes, items = items }
    JJLWCharacter.learned = learned
    captured = true
    active = { itemIDs = itemIDs, index = 1, pending = {} }
    events:RegisterEvent("ITEM_DATA_LOAD_RESULT")
    active.ticker = C_Timer.NewTicker(0.2, Tick)
    active.timeout = C_Timer.NewTimer(60, Finish)
    lw.UpdateWindow()
    return true
end

function lw.IsRefreshing()
    return active ~= nil
end

QueueRefresh = function()
    if queued or active or captured then return end
    queued = true
    C_Timer.After(0.3, function()
        queued = false
        if not captured then lw.Refresh() end
    end)
end

function addon.LeatherworkingCommand()
    if not enabled then
        print("wow-addon: Enable Leatherworking gear in /jj, then click Reload")
        return
    end
    lw.ToggleWindow()
end

addon.RegisterFeature("leatherworking", "Leatherworking gear", function(value)
    enabled = value
    if not enabled then return end
    JJLWCharacter = JJLWCharacter or { stat = "ITEM_MOD_INTELLECT_SHORT", slot = 0, learned = {} }
    if JJLWCharacter.stat == "ITEM_MOD_SPELL_POWER_SHORT" then
        JJLWCharacter.stat = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"
    end
    events:RegisterEvent("TRADE_SKILL_SHOW")
    events:RegisterEvent("TRADE_SKILL_CLOSE")
    events:RegisterEvent("TRADE_SKILL_DATA_SOURCE_CHANGED")
    events:RegisterEvent("TRADE_SKILL_LIST_UPDATE")
    events:RegisterEvent("NEW_RECIPE_LEARNED")
    events:SetScript("OnEvent", function(_, event, itemID, success)
        if event == "ITEM_DATA_LOAD_RESULT" then
            if active.pending[itemID] then
                if success then ReadItem(JJLWCatalog.items[itemID]) end
                active.pending[itemID] = nil
            end
        elseif event == "TRADE_SKILL_CLOSE" or event == "TRADE_SKILL_DATA_SOURCE_CHANGED" then
            captured = false
            if event == "TRADE_SKILL_DATA_SOURCE_CHANGED" then QueueRefresh() end
        else
            if event == "NEW_RECIPE_LEARNED" then captured = false end
            QueueRefresh()
        end
    end)
end)
