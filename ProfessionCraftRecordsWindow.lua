local _, addon = ...
local ROW_HEIGHT = 36

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

local function ItemTooltip(row)
    local record = row.record
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip_SuppressAutomaticCompareItem(GameTooltip)
    if record.link then GameTooltip:SetHyperlink(record.link) else GameTooltip:SetText(record.name) end
    GameTooltip:AddLine("Recorded " .. date("%Y-%m-%d %H:%M:%S", record.recordedAt), 1, 1, 1)
    GameTooltip:AddLine(("Recorded %d crafts x %d yield; %d items remaining"):format(record.crafts, record.yield, record.quantity), 1, 1, 1)
    local mode = record.materials == "raw" and "Buy raw materials" or "Buy finished inputs"
    if record.selectedMaterials == "farm" then mode = mode .. " (recorded from Farm mode)" end
    GameTooltip:AddLine(mode, 1, 1, 1, true)
    local basis = record.prices == "median" and "14-day median" or "Latest lowest"
    GameTooltip:AddLine("Estimated full replacement cost: vendor base prices, then " .. basis, 1, 0.82, 0, true)
    GameTooltip:AddLine("Includes materials already in your bags. Margin is before AH fees", 1, 1, 1, true)
    GameTooltip:Show()
end

function addon.CreateProfessionCraftRecordsView(profession, view)
    local records = CreateFrame("Frame", nil, view)
    records:SetAllPoints()
    records:Hide()
    records.rows = {}
    view.records = records
    local entries = {}
    local function MakeRow()
        local row = CreateFrame("Button", nil, records.content)
        row:SetSize(830, ROW_HEIGHT)
        row.item = Text(row, 24, -5, 211)
        row.remove = CreateFrame("Button", nil, row)
        row.remove:SetPoint("TOPLEFT", 0, -5)
        row.remove:SetSize(20, 20)
        row.remove:SetNormalTexture("Interface\\Buttons\\UI-MinusButton-UP")
        row.remove:SetPushedTexture("Interface\\Buttons\\UI-MinusButton-DOWN")
        row.remove:SetHighlightTexture("Interface\\Buttons\\UI-PlusButton-Hilight", "ADD")
        row.remove:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Remove one item")
            GameTooltip:Show()
        end)
        row.remove:SetScript("OnLeave", GameTooltip_Hide)
        row.remove:SetScript("OnHide", function(self)
            if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
        end)
        row.remove:SetScript("OnClick", function()
            local saved = _G[profession.characterName].gold.craftRecords
            local record = row.record
            if record.quantity > 1 then
                record.quantity = record.quantity - 1
            else
                table.remove(saved, row.recordIndex)
            end
            view.RefreshRecords()
        end)
        row.quantity = Text(row, 241, -5, 43)
        row.recorded = Text(row, 290, -5, 110)
        row.cost = Text(row, 406, -5, 136)
        row.sale = Text(row, 548, -5, 136)
        row.margin = Text(row, 690, -5, 140)
        row:SetScript("OnEnter", ItemTooltip)
        row:SetScript("OnLeave", GameTooltip_Hide)
        row:SetScript("OnHide", function(self) if GameTooltip:GetOwner() == self then GameTooltip:Hide() end end)
        row:SetScript("OnClick", function(self) if self.record.link then HandleModifiedItemClick(self.record.link) end end)
        return row
    end
    local function RenderRows()
        local offset = math.floor(records.scroll:GetVerticalScroll() / ROW_HEIGHT)
        local count = records.scroll:IsVisible() and math.min(#entries - offset,
            math.ceil(records.scroll:GetHeight() / ROW_HEIGHT) + 1) or 0
        for index = 1, count do
            local entry = entries[offset + index]
            local row = records.rows[index]
            if not row then row = MakeRow() records.rows[index] = row end
            row:SetPoint("TOPLEFT", 0, -(offset + index - 1) * ROW_HEIGHT)
            local record = entry.record
            local lowest = addon.AuctionPrices.LookupLowest(record.link)
            local margin = lowest and lowest - record.unitCost
            row.record, row.recordIndex = record, entry.index
            row.item:SetText(record.link or record.name)
            row.quantity:SetText(record.quantity)
            row.recorded:SetText(date("%m/%d %H:%M", record.recordedAt))
            row.cost:SetText(Money(record.unitCost))
            row.sale:SetText(Money(lowest))
            row.margin:SetText(Money(margin))
            row.margin:SetTextColor(margin and margin > 0 and 0.2 or 1,
                margin and margin < 0 and 0.2 or 1, margin and margin ~= 0 and 0.2 or 1)
            row:Show()
            if GameTooltip:GetOwner() == row then
                if row:IsMouseOver() then ItemTooltip(row) else GameTooltip:Hide() end
            end
        end
        for index = math.max(1, count + 1), #records.rows do
            local row = records.rows[index]
            row:Hide()
            row.record, row.recordIndex = nil, nil
        end
    end
    function view.RefreshRecords()
        entries = {}
        for index, record in ipairs(_G[profession.characterName].gold.craftRecords or {}) do
            table.insert(entries, { record = record, index = index })
        end
        table.sort(entries, function(a, b)
            if a.record.recordedAt ~= b.record.recordedAt then return a.record.recordedAt > b.record.recordedAt end
            return a.index > b.index
        end)
        records.message:SetText(#entries == 0 and "No craft records" or "")
        records.content:SetHeight(math.max(1, #entries * ROW_HEIGHT))
        records.scroll:SetVerticalScroll(math.min(records.scroll:GetVerticalScroll(),
            math.max(0, records.content:GetHeight() - records.scroll:GetHeight())))
        RenderRows()
    end
    local back = CreateFrame("Button", nil, records, "UIPanelButtonTemplate")
    back:SetPoint("TOPLEFT", 16, -34)
    back:SetSize(78, 24)
    back:SetText("Back")
    back:SetScript("OnClick", function()
        records:Hide()
        view.page:Show()
        profession.UpdateGoldView(view)
    end)
    Text(records, 108, -35, 738, "GameFontNormalLarge"):SetText("Craft records")
    for _, heading in ipairs({ { 40, 211, "Item" }, { 257, 43, "Qty" }, { 306, 110, "Recorded" },
        { 422, 136, "Craft cost / unit" }, { 564, 136, "AH lowest / unit" }, { 706, 140, "Margin / unit" } }) do
        Text(records, heading[1], -75, heading[2], "GameFontNormalSmall"):SetText(heading[3])
    end
    records.scroll = CreateFrame("ScrollFrame", nil, records, "ScrollFrameTemplate")
    records.scroll:SetPoint("TOPLEFT", 16, -100)
    records.scroll:SetPoint("BOTTOMRIGHT", -40, 40)
    records.scroll.ScrollBar:ClearAllPoints()
    records.scroll.ScrollBar:SetPoint("TOPLEFT", records.scroll, "TOPRIGHT", 6, 0)
    records.scroll.ScrollBar:SetPoint("BOTTOMLEFT", records.scroll, "BOTTOMRIGHT", 6, 0)
    records.scroll.ScrollBar:SetHideIfUnscrollable(true)
    records.scroll:SetPanExtent(ROW_HEIGHT)
    records.content = CreateFrame("Frame", nil, records.scroll)
    records.content:SetWidth(830)
    records.scroll:SetScrollChild(records.content)
    records.message = Text(records.scroll, 0, -10, 830)
    records.scroll:HookScript("OnVerticalScroll", RenderRows)
    records.scroll:HookScript("OnSizeChanged", RenderRows)
    records.scroll:HookScript("OnShow", RenderRows)
    records.scroll:HookScript("OnHide", RenderRows)
    Text(records, 16, -519, 862):SetText("Current AH lowest from the saved scan. Margin before AH fees")
    function view.OpenRecords()
        view.page:Hide()
        view.detail:Hide()
        view.hidden:Hide()
        records:Show()
        records.scroll:SetVerticalScroll(0)
        view.RefreshRecords()
    end
end
