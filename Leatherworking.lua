local _, addon = ...
local lw = {
    id = 165, name = "Leatherworking", shortName = "LW", scanCommand = "/jj lwscan",
    catalogName = "JJLWCatalog", characterName = "JJLWCharacter",
}
addon.Leatherworking = lw
local enabled
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

function lw.ReadItem(item)
    local name, link, _, _, level, _, subType, _, equipLoc = C_Item.GetItemInfo(item.itemID)
    if not name or not link then return false end
    item.link, item.requiredLevel, item.subType = link, level, subType
    item.slot = lw.equipSlots[equipLoc]
    item.loaded = true
    item.stats = item.slot and C_Item.GetItemStats(link) or nil
    return not item.slot or item.stats ~= nil
end

addon.AttachProfessionCatalog(lw)

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
    lw.ScanRecipes()
end

addon.RegisterFeature("leatherworking", "Leatherworking gear", function(value)
    enabled = value
    if not enabled then return end
    addon.AddMinimapButton("leatherworking", "Leatherworking", 2108, 180,
        addon.LeatherworkingCommand, lw.OpenAndScan)
    JJLWCharacter = JJLWCharacter or { stat = "ITEM_MOD_INTELLECT_SHORT", slot = 0, learned = {} }
    if JJLWCharacter.stat == "ITEM_MOD_SPELL_POWER_SHORT" then
        JJLWCharacter.stat = "ITEM_MOD_SPELL_DAMAGE_DONE_SHORT"
    end
    lw.InitializeGold()
    lw.InitializeCatalog()
end)
