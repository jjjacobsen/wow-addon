local _, addon = ...
local lw = addon.Leatherworking
local window, currentLevel
local requested = {}
local ROW_HEIGHT = 26
local UpdateWindow

local function StatValue(stats)
    if stats then return stats[JJLWCharacter.stat] or 0 end
end

local function EquippedValue(slot)
    local link = GetInventoryItemLink("player", slot)
    if issecretvalue(link) then return nil end
    local itemID = GetInventoryItemID("player", slot)
    if not link and not itemID and not GetInventoryItemTexture("player", slot) then return 0 end
    local stats = link and C_Item.GetItemStats(link)
    if stats then return StatValue(stats) end
    if itemID and not requested[itemID] then
        requested[itemID] = true
        C_Item.RequestLoadItemDataByID(itemID)
    end
end

local function ShowTooltip(row)
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:SetHyperlink(row.link)
    GameTooltip:Show()
    if not InCombatLockdown() then GameTooltip_ShowCompareItem(GameTooltip) end
end

local function Text(parent, x, y, width, template)
    local text = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", x, y)
    text:SetSize(width, 20)
    text:SetJustifyH("LEFT")
    return text
end

local function ShowEquippedTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    ItemUtil.DisplayEquipSlotTooltip(button, GameTooltip, button.slot, true)
    GameTooltip:Show()
end

local function RefreshModel()
    window.model:SetUnit("player", false, true)
    window.model:Dress()
end

local function CreateCharacterView()
    local character = CreateFrame("Frame", nil, window)
    character:SetPoint("TOPLEFT", 16, -34)
    character:SetSize(284, 480)
    window.character = character
    Text(character, 0, 0, 284, "GameFontNormalLarge"):SetText(UnitName("player"))

    window.model = CreateFrame("DressUpModel", nil, character)
    window.model:SetPoint("TOPLEFT", 32, -24)
    window.model:SetSize(220, 440)
    window.model:SetAutoDress(true)
    window.model:EnableMouse(false)
    window.model:SetScript("OnShow", RefreshModel)

    local slots = {
        { "HeadSlot", 0, -48 }, { "ShoulderSlot", 0, -112 },
        { "BackSlot", 0, -176 }, { "ChestSlot", 0, -240 },
        { "WristSlot", 0, -304 }, { "HandsSlot", 248, -48 },
        { "WaistSlot", 248, -112 }, { "LegsSlot", 248, -176 },
        { "FeetSlot", 248, -240 },
    }
    window.equipment = {}
    for _, slot in ipairs(slots) do
        local button = CreateFrame("CheckButton", nil, character)
        button:SetSize(36, 36)
        button:SetPoint("TOPLEFT", slot[2], slot[3])
        button.slot, button.emptyTexture = C_PaperDollInfo.GetInventorySlotInfo(slot[1])
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetAllPoints()
        local border = button:CreateTexture(nil, "OVERLAY")
        border:SetTexture("Interface\\Buttons\\UI-Quickslot2")
        border:SetPoint("CENTER")
        border:SetSize(64, 64)
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        button:SetCheckedTexture("Interface\\Buttons\\CheckButtonHilight")
        button:GetCheckedTexture():SetBlendMode("ADD")
        button:SetScript("OnEnter", ShowEquippedTooltip)
        button:SetScript("OnLeave", GameTooltip_Hide)
        button:SetScript("OnHide", function(self)
            if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
        end)
        button:SetScript("OnClick", function(self)
            JJLWCharacter.slot = JJLWCharacter.slot == self.slot and 0 or self.slot
            UpdateWindow()
        end)
        table.insert(window.equipment, button)
    end
end

local function SelectView(index)
    PanelTemplates_SetTab(window, index)
    window.character:SetShown(index == 1)
    window:SetWidth(index == 1 and 1130 or 830)
    UpdateWindow()
end

local function MakeRow(index)
    local row = CreateFrame("Button", nil, window.content)
    row:SetSize(770, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row.item = Text(row, 0, -3, 290)
    row.armor = Text(row, 296, -3, 85)
    row.level = Text(row, 387, -3, 52)
    row.value = Text(row, 445, -3, 95)
    row.delta = Text(row, 546, -3, 100)
    row.learned = Text(row, 652, -3, 110)
    row:SetScript("OnEnter", ShowTooltip)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnHide", function(self)
        if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
    end)
    row:SetScript("OnClick", function(self)
        HandleModifiedItemClick(self.link)
    end)
    return row
end

UpdateWindow = function()
    if not window or not window:IsShown() then return end
    local options, catalog = JJLWCharacter, JJLWCatalog
    if not window.level:HasFocus() then window.level:SetText(options.maxLevel or currentLevel) end
    window.slot:Update()
    for _, button in ipairs(window.equipment) do
        button.icon:SetTexture(GetInventoryItemTexture("player", button.slot) or button.emptyTexture)
        button:SetChecked(options.slot == button.slot)
        if button:IsShown() and button:IsMouseOver() then ShowEquippedTooltip(button) end
    end
    local rows, baselines = {}, {}
    for _, slot in ipairs(lw.slots) do
        if slot[2] ~= 0 then baselines[slot[2]] = EquippedValue(slot[2]) end
    end
    local missing, unresolved, recipeCount = 0, 0, 0
    if catalog then
        for _, item in pairs(catalog.items) do
            if not item.loaded or (item.slot and (not item.stats or item.requiredLevel == nil)) then
                missing = missing + 1
            end
        end
        for recipeID, recipe in pairs(catalog.recipes) do
            recipeCount = recipeCount + 1
            if not recipe.itemID and not recipe.nonItem then unresolved = unresolved + 1 end
            local item = recipe.itemID and catalog.items[recipe.itemID]
            if item and item.slot and item.requiredLevel
                and (options.slot == 0 or options.slot == item.slot)
                and item.requiredLevel <= (options.maxLevel or currentLevel) then
                local value = StatValue(item.stats)
                local baseline = baselines[item.slot]
                local delta
                if value ~= nil and baseline ~= nil then delta = value - baseline end
                if not options.upgradesOnly or (delta and delta > 0) then
                    table.insert(rows, { item = item, recipeID = recipeID, value = value, delta = delta })
                end
            end
        end
    end
    table.sort(rows, function(a, b)
        if a.value ~= b.value then
            if a.value == nil then return false end
            if b.value == nil then return true end
            return a.value > b.value
        end
        if a.item.itemID ~= b.item.itemID then return a.item.itemID < b.item.itemID end
        return a.recipeID < b.recipeID
    end)
    for index, entry in ipairs(rows) do
        local row = window.rows[index]
        if not row then
            row = MakeRow(index)
            window.rows[index] = row
        end
        row.link = entry.item.link
        row.item:SetText(row.link)
        row.armor:SetText(entry.item.subType)
        row.level:SetText(entry.item.requiredLevel)
        row.value:SetText(entry.value == nil and "-" or tostring(entry.value))
        local delta = entry.delta
        row.delta:SetText(delta == nil and "-" or (delta > 0 and "+" or "") .. tostring(delta))
        row.delta:SetTextColor(delta and delta > 0 and 0.2 or 1, delta and delta < 0 and 0.2 or 1, delta and delta ~= 0 and 0.2 or 1)
        local learned = options.learned[entry.recipeID]
        row.learned:SetText(learned == nil and "Unknown" or learned and "Learned" or "Unlearned")
        row:Show()
        if row:IsMouseOver() then ShowTooltip(row) end
    end
    for index = #rows + 1, #window.rows do window.rows[index]:Hide() end
    window.content:SetHeight(math.max(1, #rows * ROW_HEIGHT))
    window.scroll:SetVerticalScroll(math.min(window.scroll:GetVerticalScroll(), window.scroll:GetVerticalScrollRange()))
    window.status:SetText(("%d shown | %d recipes | %d items unavailable | %d outputs unresolved%s")
        :format(#rows, recipeCount, missing, unresolved, lw.IsRefreshing() and " | Loading" or ""))
    window.message:SetText(not catalog and "Open your own Leatherworking to save the catalog"
        or #rows == 0 and "No matching equipment" or "")
end
lw.UpdateWindow = UpdateWindow

local function CreateWindow()
    window = CreateFrame("Frame", "JJLeatherworkingFrame", UIParent, "BasicFrameTemplate")
    window:Hide()
    window:SetSize(1130, 570)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window.TitleText:SetText("Leatherworking gear")
    table.insert(UISpecialFrames, "JJLeatherworkingFrame")

    for index, label in ipairs({ "Character", "Table" }) do
        local tab = CreateFrame("Button", nil, window, "PanelTabButtonTemplate")
        tab:SetID(index)
        tab:SetText(label)
        if index == 1 then
            tab:SetPoint("TOPLEFT", window, "BOTTOMLEFT", 12, 0)
        else
            tab:SetPoint("TOPLEFT", window.Tabs[index - 1], "TOPRIGHT", 5, 0)
        end
        tab:SetScript("OnClick", function(self) SelectView(self:GetID()) end)
    end
    window.numTabs = 2
    CreateCharacterView()
    local panel = CreateFrame("Frame", nil, window)
    panel:SetPoint("TOPRIGHT")
    panel:SetPoint("BOTTOMRIGHT")
    panel:SetWidth(830)

    Text(panel, 16, -34, 220, "GameFontNormal"):SetText("Stat")
    local stat = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
    stat:SetPoint("TOPLEFT", 16, -57)
    stat:SetWidth(220)
    stat:SetupMenu(function(_, root)
        root:SetScrollMode(320)
        for _, choice in ipairs(lw.stats) do
            root:CreateRadio(choice[1], function() return JJLWCharacter.stat == choice[2] end, function()
                JJLWCharacter.stat = choice[2]
                UpdateWindow()
            end)
        end
    end)
    Text(panel, 252, -34, 150, "GameFontNormal"):SetText("Slot")
    local slot = CreateFrame("DropdownButton", nil, panel, "WowStyle1DropdownTemplate")
    window.slot = slot
    slot:SetPoint("TOPLEFT", 252, -57)
    slot:SetWidth(150)
    slot:SetupMenu(function(_, root)
        for _, choice in ipairs(lw.slots) do
            root:CreateRadio(choice[1], function() return JJLWCharacter.slot == choice[2] end, function()
                JJLWCharacter.slot = choice[2]
                UpdateWindow()
            end)
        end
    end)

    Text(panel, 420, -34, 160, "GameFontNormal"):SetText("Max equip level")
    window.level = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    window.level:SetPoint("TOPLEFT", 426, -58)
    window.level:SetSize(54, 24)
    window.level:SetAutoFocus(false)
    window.level:SetNumeric(true)
    window.level:SetMaxLetters(3)
    window.level:SetScript("OnTextChanged", function(self, userInput)
        if userInput then self.edited = true end
    end)
    window.level:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    window.level:SetScript("OnEscapePressed", function(self)
        self.edited = false
        self:ClearFocus()
    end)
    window.level:SetScript("OnEditFocusLost", function(self)
        local value = tonumber(self:GetText())
        if self.edited and value then JJLWCharacter.maxLevel = value end
        self.edited = false
        UpdateWindow()
    end)
    local auto = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    auto:SetPoint("LEFT", window.level, "RIGHT", 6, 0)
    auto:SetSize(48, 24)
    auto:SetText("Auto")
    auto:SetScript("OnClick", function()
        window.level:ClearFocus()
        JJLWCharacter.maxLevel = nil
        UpdateWindow()
    end)

    local upgrades = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    upgrades:SetPoint("TOPLEFT", 12, -92)
    upgrades.Text:SetText("Upgrades only (selected stat)")
    upgrades:SetChecked(JJLWCharacter.upgradesOnly)
    upgrades:SetScript("OnClick", function(self)
        JJLWCharacter.upgradesOnly = self:GetChecked()
        UpdateWindow()
    end)
    Text(panel, 16, -129, 290, "GameFontNormal"):SetText("Item")
    Text(panel, 312, -129, 85, "GameFontNormal"):SetText("Armor type")
    Text(panel, 403, -129, 52, "GameFontNormal"):SetText("Level")
    Text(panel, 461, -129, 95, "GameFontNormal"):SetText("Stat value")
    Text(panel, 562, -129, 100, "GameFontNormal"):SetText("vs equipped")
    Text(panel, 668, -129, 110, "GameFontNormal"):SetText("Recipe")

    window.scroll = CreateFrame("ScrollFrame", nil, panel, "ScrollFrameTemplate")
    window.scroll:SetPoint("TOPLEFT", 16, -154)
    window.scroll:SetPoint("BOTTOMRIGHT", -40, 58)
    window.scroll.ScrollBar:ClearAllPoints()
    window.scroll.ScrollBar:SetPoint("TOPLEFT", window.scroll, "TOPRIGHT", 6, 0)
    window.scroll.ScrollBar:SetPoint("BOTTOMLEFT", window.scroll, "BOTTOMRIGHT", 6, 0)
    window.scroll.ScrollBar:SetHideIfUnscrollable(true)
    window.scroll:SetPanExtent(ROW_HEIGHT)
    window.content = CreateFrame("Frame", nil, window.scroll)
    window.content:SetWidth(770)
    window.scroll:SetScrollChild(window.content)
    window.rows = {}
    window.message = Text(window.scroll, 0, -10, 760, "GameFontHighlight")
    window.status = Text(panel, 16, -520, 795)
    Text(panel, 16, -542, 795):SetText("Delta compares this stat only, not overall gear quality. Missing data: -")
    window:SetScript("OnShow", function(self)
        requested = {}
        currentLevel = UnitLevel("player")
        self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        self:RegisterEvent("PLAYER_LEVEL_UP")
        self:RegisterEvent("ITEM_DATA_LOAD_RESULT")
        SelectView(1)
    end)
    window:SetScript("OnHide", function(self) self:UnregisterAllEvents() end)
    window:SetScript("OnEvent", function(_, event, level)
        if event == "PLAYER_EQUIPMENT_CHANGED" then
            requested = {}
            if window.model:IsShown() then RefreshModel() end
        end
        if event == "PLAYER_LEVEL_UP" then currentLevel = level end
        if not window.updateQueued then
            window.updateQueued = true
            RunNextFrame(function()
                window.updateQueued = false
                UpdateWindow()
            end)
        end
    end)
end

function lw.ToggleWindow()
    if not window then CreateWindow() end
    window:SetShown(not window:IsShown())
end
