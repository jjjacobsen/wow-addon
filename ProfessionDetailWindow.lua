local _, addon = ...
local ROW_HEIGHT = 42

local function Text(parent, x, y, width, template)
    local text = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlightSmall")
    text:SetPoint("TOPLEFT", x, y)
    text:SetSize(width, 20)
    text:SetJustifyH("LEFT")
    return text
end

local function Money(value)
    if value == nil then return "Unavailable" end
    return (value < 0 and "-" or "") .. C_CurrencyInfo.GetCoinTextureString(math.ceil(math.abs(value)))
end

local function Button(parent, x, y, width, label, click)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", x, y)
    button:SetSize(width, 24)
    button:SetText(label)
    button:SetScript("OnClick", click)
    return button
end

local function ItemTooltip(self)
    if not self.link then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SuppressAutomaticCompareItem(GameTooltip)
    GameTooltip:SetHyperlink(self.link)
    for _, issue in ipairs(self.issues or {}) do GameTooltip:AddLine(issue, 1, 0.5, 0.3, true) end
    if self.line then
        if self.line.source then GameTooltip:AddLine(self.line.source, 1, 1, 1, true) end
        GameTooltip:AddDoubleLine("Estimate / unit", Money(self.line.unitPrice), 1, 0.82, 0, 1, 1, 1)
    end
    GameTooltip:Show()
end

local function Bags()
    local counts = {}
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info then
                local key = addon.AuctionPrices.ItemKey(info.hyperlink)
                if key then counts[key] = (counts[key] or 0) + info.stackCount end
            end
        end
    end
    return counts
end

function addon.CreateProfessionDetailView(profession, view)
    local detail = CreateFrame("Frame", nil, view)
    detail:SetAllPoints()
    detail:Hide()
    view.detail = detail
    detail.rows = {}
    local function Settings() return _G[profession.characterName].gold end
    local function MakeRow(index)
        local row = CreateFrame("Button", nil, detail.content)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
        row:SetSize(830, ROW_HEIGHT)
        row.item = Text(row, 0, 0, 360)
        row.source = Text(row, 0, -19, 830, "GameFontDisableSmall")
        row.required = Text(row, 370, 0, 80)
        row.owned = Text(row, 460, 0, 80)
        row.need = Text(row, 550, 0, 90)
        row.price = Text(row, 650, 0, 180)
        row:SetScript("OnEnter", ItemTooltip)
        row:SetScript("OnLeave", GameTooltip_Hide)
        row:SetScript("OnClick", function(self) if self.link then HandleModifiedItemClick(self.link) end end)
        row:SetScript("OnHide", function(self) if GameTooltip:GetOwner() == self then GameTooltip:Hide() end end)
        return row
    end
    local function Recalculate()
        local gold = Settings()
        local basket = profession.DetailBasket(detail.entry.recipeID, detail.count, gold.materials, Bags())
        local mode = gold.materials == "farm" and "raw" or gold.materials
        local full = profession.DetailBasket(detail.entry.recipeID, detail.count, mode, {})
        local fullCost = 0
        local recordable = full.valid and full.recipe and not full.recipe.nonItem and full.link
            and full.quantity and full.quantity > 0 and full.recipe.quantity > 0
            and full.recipe.quantity == math.floor(full.recipe.quantity)
        for _, line in ipairs(full.lines) do
            if line.need > 0 then
                if line.unitPrice == nil then recordable = false
                else fullCost = fullCost + line.need * line.unitPrice end
            end
        end
        detail.recordDraft = recordable and {
            recipeID = full.recipeID, itemID = full.recipe.itemID, link = full.link,
            name = full.link:match("|h%[(.-)%]|h") or detail.entry.name,
            crafts = detail.count, yield = full.recipe.quantity, quantity = full.quantity,
            totalCost = fullCost, unitCost = fullCost / full.quantity,
            materials = mode, selectedMaterials = gold.materials, prices = gold.prices,
        } or nil
        detail.record:SetEnabled(detail.recordDraft ~= nil)
        detail.modeSelect:Update()
        detail.priceSelect:Update()
        if not detail.crafts:HasFocus() then detail.crafts:SetText(detail.count) end
        detail.output.link, detail.output.issues = basket.link, basket.issues
        detail.output.text:SetText(basket.link or detail.entry.name)
        detail.title:SetText("Recipe #" .. detail.entry.recipeID
            .. (detail.entry.requiredSkill and ("  |  " .. profession.shortName .. " " .. detail.entry.requiredSkill) or ""))
        local ah, vendor, known = 0, 0, basket.valid
        for index, line in ipairs(basket.lines) do
            local row = detail.rows[index]
            if not row then row = MakeRow(index) detail.rows[index] = row end
            row.line, row.link = line, line.link
            row.item:SetText(line.link)
            row.required:SetText(line.required)
            row.owned:SetText(line.owned)
            row.need:SetText(line.need)
            local cost = line.unitPrice and line.unitPrice * line.need
            if line.need > 0 then
                if cost == nil then known = false
                elseif line.vendor then vendor = vendor + cost
                else ah = ah + cost end
            end
            row.source:SetText(line.source or "Bags")
            row.price:SetText(line.need > 0 and Money(cost) or "-")
            row:Show()
        end
        for index = #basket.lines + 1, #detail.rows do detail.rows[index]:Hide() end
        detail.content:SetHeight(math.max(1, #basket.lines * ROW_HEIGHT))
        local salePrice = basket.savedPrice
        local cost = known and ah + vendor or nil
        local sale = salePrice and basket.quantity and salePrice * basket.quantity
        detail.yield:SetText(detail.count .. " crafts  |  Produces " .. (basket.quantity or "?") .. " items")
        detail.values[1]:SetText(Money(known and ah or nil))
        detail.values[2]:SetText(Money(vendor))
        detail.values[3]:SetText(Money(cost))
        detail.values[4]:SetText(Money(salePrice))
        detail.values[5]:SetText(Money(sale))
        detail.values[6]:SetText(Money(sale and cost and sale - cost))
        detail.issues:SetText(table.concat(basket.issues, "; "))
        local _, _, scannedAt = addon.AuctionPrices.Lookup()
        detail.scan:SetText(scannedAt and ("Saved scan " .. date("%Y-%m-%d %H:%M", scannedAt)) or "No saved full scan")
        detail.minus:SetEnabled(detail.count > 1)
    end
    Button(detail, 16, -34, 78, "Back", function()
        detail:Hide()
        view.page:Show()
        profession.UpdateGoldView(view)
    end)
    detail.title = Text(detail, 108, -35, 524, "GameFontNormalLarge")
    detail.record = Button(detail, 642, -34, 118, "Record craft", function()
        detail.crafts:ClearFocus()
        local record = detail.recordDraft
        if not record then return end
        record.recordedAt = GetServerTime()
        local gold = Settings()
        gold.craftRecords = gold.craftRecords or {}
        table.insert(gold.craftRecords, record)
        view.OpenRecords()
    end)
    detail.record:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Record craft")
        GameTooltip:AddLine("Saves estimated cost for all materials, including those already in your bags; does not craft items", 1, 1, 1, true)
        if Settings().materials == "farm" then
            GameTooltip:AddLine("Farm mode: record uses raw purchase prices for all materials", 1, 0.82, 0, true)
        end
        GameTooltip:Show()
    end)
    detail.record:SetScript("OnLeave", GameTooltip_Hide)
    detail.record:SetScript("OnHide", function(self) if GameTooltip:GetOwner() == self then GameTooltip:Hide() end end)
    Button(detail, 768, -34, 110, "Hide recipe", function()
        local gold = Settings()
        gold.hiddenRecipes = gold.hiddenRecipes or {}
        gold.hiddenRecipes[detail.entry.recipeID] = true
        view.OpenHidden()
    end)
    detail.output = CreateFrame("Button", nil, detail)
    detail.output:SetPoint("TOPLEFT", 16, -65)
    detail.output:SetSize(830, 25)
    detail.output.text = Text(detail.output, 0, 0, 830, "GameFontHighlightLarge")
    detail.output:SetScript("OnEnter", ItemTooltip)
    detail.output:SetScript("OnLeave", GameTooltip_Hide)
    detail.output:SetScript("OnClick", function(self) if self.link then HandleModifiedItemClick(self.link) end end)
    Text(detail, 16, -95, 150, "GameFontNormal"):SetText("Crafts")
    detail.minus = Button(detail, 16, -118, 24, "-", function() detail.count = detail.count - 1 Recalculate() end)
    detail.crafts = CreateFrame("EditBox", nil, detail, "InputBoxTemplate")
    detail.crafts:SetPoint("TOPLEFT", 50, -118)
    detail.crafts:SetSize(64, 24)
    detail.crafts:SetNumeric(true)
    detail.crafts:SetAutoFocus(false)
    detail.crafts:SetMaxLetters(8)
    detail.crafts:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    detail.crafts:SetScript("OnEscapePressed", function(self) self:SetText(detail.count) self:ClearFocus() end)
    detail.crafts:SetScript("OnEditFocusLost", function(self)
        local count = tonumber(self:GetText())
        if not count or count < 1 or count ~= math.floor(count) then self:SetText(detail.count)
        elseif count ~= detail.count then detail.count = count Recalculate() end
    end)
    detail.plus = Button(detail, 124, -118, 24, "+", function() detail.count = detail.count + 1 Recalculate() end)
    local function Dropdown(x, width, label, option, choices)
        Text(detail, x, -95, width, "GameFontNormal"):SetText(label)
        local dropdown = CreateFrame("DropdownButton", nil, detail, "WowStyle1DropdownTemplate")
        dropdown:SetPoint("TOPLEFT", x, -118)
        dropdown:SetWidth(width)
        dropdown:SetupMenu(function(_, root)
            for _, choice in ipairs(choices) do
                root:CreateRadio(choice[1], function() return Settings()[option] == choice[2] end, function()
                    Settings()[option] = choice[2]
                    Recalculate()
                end)
            end
        end)
        return dropdown
    end
    detail.modeSelect = Dropdown(186, 220, "Materials", "materials", profession.materialChoices)
    detail.priceSelect = Dropdown(430, 190, "Prices", "prices", {
        { "Latest lowest", "lowest" }, { "14-day median", "median" },
    })
    detail.yield = Text(detail, 16, -149, 360)
    Text(detail, 390, -149, 456, "GameFontDisableSmall"):SetText("Owned items excluded. Farm inputs cost zero")
    detail.values = {}
    local labels = { "Buy from AH", "Buy from vendors", "Total new spending",
        "Output price / item", "Expected sale value", "Cash margin before AH fees" }
    for index, label in ipairs(labels) do
        local x = 16 + ((index - 1) % 3) * 288
        local y = index <= 3 and -176 or -222
        Text(detail, x, y, 270, "GameFontNormalSmall"):SetText(label)
        detail.values[index] = Text(detail, x, y - 19, 270, "GameFontHighlight")
    end
    for _, heading in ipairs({ { 16, 360, "Ingredient / source" }, { 386, 80, "Needed" }, { 476, 80, "Bags" },
        { 566, 90, "Remaining" }, { 666, 180, "Est. cost" } }) do
        Text(detail, heading[1], -274, heading[2], "GameFontNormalSmall"):SetText(heading[3])
    end
    detail.scroll = CreateFrame("ScrollFrame", nil, detail, "ScrollFrameTemplate")
    detail.scroll:SetPoint("TOPLEFT", 16, -299)
    detail.scroll:SetPoint("BOTTOMRIGHT", -40, 66)
    detail.scroll.ScrollBar:ClearAllPoints()
    detail.scroll.ScrollBar:SetPoint("TOPLEFT", detail.scroll, "TOPRIGHT", 6, 0)
    detail.scroll.ScrollBar:SetPoint("BOTTOMLEFT", detail.scroll, "BOTTOMRIGHT", 6, 0)
    detail.scroll.ScrollBar:SetHideIfUnscrollable(true)
    detail.scroll:SetPanExtent(ROW_HEIGHT)
    detail.content = CreateFrame("Frame", nil, detail.scroll)
    detail.content:SetWidth(830)
    detail.scroll:SetScrollChild(detail.content)
    detail.issues = Text(detail, 16, -488, 862)
    detail.issues:SetTextColor(1, 0.5, 0.3)
    detail.scan = Text(detail, 16, -519, 862)
    detail:SetScript("OnHide", function()
        if GameTooltip:GetOwner() == detail.output then GameTooltip:Hide() end
    end)
    function view.OpenDetail(entry)
        detail.entry, detail.count = entry, 1
        view.page:Hide()
        view.hidden:Hide()
        view.records:Hide()
        detail:Show()
        detail.scroll:SetVerticalScroll(0)
        Recalculate()
    end
end
