local _, addon = ...
local lw = addon.Leatherworking
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
    return (value < 0 and "-" or "") .. C_CurrencyInfo.GetCoinTextureString(math.floor(math.abs(value) + 0.5))
end

local function MarketName(key)
    local _, pvp, rp, hardcore, faction = strsplit(":", key)
    local labels = { pvp == "pvp1" and "PvP" or "PvE" }
    if rp == "rp1" then table.insert(labels, "RP") end
    if hardcore == "hc1" then table.insert(labels, "Hardcore") end
    table.insert(labels, faction)
    return table.concat(labels, " · ")
end

local function Tooltip(row)
    local entry = row.entry
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if entry.link then GameTooltip:SetHyperlink(entry.link) else GameTooltip:ClearLines() end
    GameTooltip:AddLine(entry.recipe.name or ("Recipe " .. entry.recipeID), 1, 0.82, 0)
    GameTooltip:AddLine("Estimates per craft, before AH fees", 1, 0.82, 0)
    local recipe = entry.recipe
    if recipe.quantity then
        GameTooltip:AddLine("Output: " .. recipe.quantity
            .. (recipe.quantityMax ~= recipe.quantity and (" minimum (up to " .. recipe.quantityMax .. ")") or ""))
    end
    GameTooltip:AddDoubleLine("Cash materials", Money(entry.cash))
    GameTooltip:AddDoubleLine("Sale value", Money(entry.sale))
    GameTooltip:AddDoubleLine("Margin before AH fees", Money(entry.margin))
    if JJLWCharacter.gold.materials == "farm" then
        GameTooltip:AddDoubleLine("Forgone material sale before AH fees", Money(entry.forgone))
        GameTooltip:AddDoubleLine("Margin after material value, before AH fees", Money(entry.materialMargin))
        GameTooltip:AddLine("Farmed inputs cost zero cash, but can have sale value", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine("Intermediaries round up to full crafts. Leftovers have no credited value", 0.7, 0.7, 0.7, true)
    end
    for _, issue in ipairs(entry.issues) do GameTooltip:AddLine(issue, 1, 0.3, 0.3, true) end
    for _, line in ipairs(entry.lines) do
        local indent = string.rep("  ", line.depth)
        GameTooltip:AddDoubleLine(indent .. line.quantity .. " x " .. (line.link or ("Item " .. line.itemID)),
            line.expanded and "See inputs" or Money(line.cost), 1, 1, 1, 1, 1, 1)
        GameTooltip:AddLine(indent .. line.source
            .. (line.unitPrice and (" | " .. Money(line.unitPrice) .. " / unit") or ""), 0.7, 0.7, 0.7, true)
        if line.source == "Farmed, zero cash" then
            GameTooltip:AddDoubleLine(indent .. "  Forgone sale before AH fees", Money(line.forgone))
        end
    end
    GameTooltip:AddLine("No sale prediction. AH fees, deposits and relists excluded", 0.7, 0.7, 0.7, true)
    GameTooltip:Show()
end

local function MakeRow(view, index)
    local row = CreateFrame("Button", nil, view.content)
    row:SetSize(830, ROW_HEIGHT)
    row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    row.item = Text(row, 0, 0, 296)
    row.recipe = Text(row, 0, -16, 296, "GameFontDisableSmall")
    row.quantity = Text(row, 302, -5, 38)
    row.cost = Text(row, 346, -5, 154)
    row.sale = Text(row, 506, -5, 150)
    row.margin = Text(row, 662, -5, 168)
    row:SetScript("OnEnter", Tooltip)
    row:SetScript("OnLeave", GameTooltip_Hide)
    row:SetScript("OnHide", function(self)
        if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
    end)
    row:SetScript("OnClick", function(self)
        if self.entry.link then HandleModifiedItemClick(self.entry.link) end
    end)
    return row
end

function lw.UpdateGoldView(view)
    view.materials:Update()
    view.prices:Update()
    local rows, hidden, unavailable = lw.GoldRows()
    local missingIngredients = false
    for index, entry in ipairs(rows) do
        if not entry.recipe.ingredients then missingIngredients = true end
        local row = view.rows[index]
        if not row then
            row = MakeRow(view, index)
            view.rows[index] = row
        end
        row.entry = entry
        row.item:SetText(entry.name)
        row.recipe:SetText("#" .. entry.recipeID .. (entry.needsRecipe and " | Unlearned/unknown recipe required" or " | Learned"))
        row.quantity:SetText(entry.recipe.quantity or "-")
        row.cost:SetText(Money(entry.cash))
        row.sale:SetText(Money(entry.sale))
        row.margin:SetText(Money(entry.margin))
        row.margin:SetTextColor(entry.margin and entry.margin > 0 and 0.2 or 1,
            entry.margin and entry.margin < 0 and 0.2 or 1, entry.margin and entry.margin ~= 0 and 0.2 or 1)
        row:Show()
        if row:IsMouseOver() then Tooltip(row) end
    end
    for index = #rows + 1, #view.rows do view.rows[index]:Hide() end
    view.content:SetHeight(math.max(1, #rows * ROW_HEIGHT))
    view.scroll:SetVerticalScroll(math.min(view.scroll:GetVerticalScroll(), view.scroll:GetVerticalScrollRange()))
    view.message:SetText(not JJLWCatalog and "Open your own Leatherworking to save ingredient data"
        or #rows == 0 and "No matching recipes" or "")
    local _, _, scannedAt, market = addon.AuctionPrices.Lookup()
    local scan = "No AH scan for this market"
    if scannedAt then
        local minutes = math.floor((GetServerTime() - scannedAt) / 60)
        scan = "Scan " .. date("%Y-%m-%d %H:%M", scannedAt) .. " | " .. minutes .. " min ago"
    end
    view.scan:SetText((market and MarketName(market) or "Market unavailable") .. " | " .. scan)
    local status = lw.IsRefreshing() and "Loading, keep your own Leatherworking open"
        or missingIngredients and "Open your own Leatherworking for ingredient data"
        or "Hover for ingredients and sources"
    view.status:SetText(("%d recipes | Hidden: %d unlearned/unknown, %d unavailable | %s"):format(#rows, hidden, unavailable, status))
end

function lw.CreateGoldView(window)
    local view = CreateFrame("Frame", nil, window)
    view:SetAllPoints()
    view:Hide()
    window.gold = view
    local function Dropdown(x, width, label, option, choices)
        Text(view, x, -34, width, "GameFontNormal"):SetText(label)
        local dropdown = CreateFrame("DropdownButton", nil, view, "WowStyle1DropdownTemplate")
        dropdown:SetPoint("TOPLEFT", x, -57)
        dropdown:SetWidth(width)
        dropdown:SetupMenu(function(_, root)
            for _, choice in ipairs(choices) do
                root:CreateRadio(choice[1], function() return JJLWCharacter.gold[option] == choice[2] end, function()
                    JJLWCharacter.gold[option] = choice[2]
                    lw.UpdateWindow()
                end)
            end
        end)
        return dropdown
    end
    view.materials = Dropdown(16, 270, "Materials", "materials", {
        { "Buy everything", "buy" }, { "Farm leather and hides", "farm" },
    })
    view.prices = Dropdown(306, 206, "Prices", "prices", {
        { "Latest lowest", "lowest" }, { "14-day median", "median" },
    })
    local unlearned = CreateFrame("CheckButton", nil, view, "UICheckButtonTemplate")
    unlearned:SetPoint("TOPLEFT", 536, -55)
    unlearned.Text:SetText("Include unlearned")
    unlearned:SetChecked(JJLWCharacter.gold.includeUnlearned)
    unlearned:SetScript("OnClick", function(self)
        JJLWCharacter.gold.includeUnlearned = self:GetChecked()
        lw.UpdateWindow()
    end)
    local unavailable = CreateFrame("CheckButton", nil, view, "UICheckButtonTemplate")
    unavailable:SetPoint("TOPLEFT", 720, -55)
    unavailable.Text:SetText("Exclude unavailable")
    unavailable:SetChecked(JJLWCharacter.gold.excludeUnavailable)
    unavailable:SetScript("OnClick", function(self)
        JJLWCharacter.gold.excludeUnavailable = self:GetChecked()
        lw.UpdateWindow()
    end)
    Text(view, 16, -92, 862):SetText("Estimates per craft. Sale value and margins exclude AH fees, deposits and relists")
    Text(view, 16, -119, 296, "GameFontNormal"):SetText("Item / recipe")
    Text(view, 318, -119, 38, "GameFontNormal"):SetText("Qty")
    Text(view, 362, -119, 154, "GameFontNormal"):SetText("Cash materials")
    Text(view, 522, -119, 150, "GameFontNormal"):SetText("Sale value")
    Text(view, 678, -119, 184, "GameFontNormal"):SetText("Margin before AH fees")
    view.scroll = CreateFrame("ScrollFrame", nil, view, "ScrollFrameTemplate")
    view.scroll:SetPoint("TOPLEFT", 16, -146)
    view.scroll:SetPoint("BOTTOMRIGHT", -40, 66)
    view.scroll.ScrollBar:ClearAllPoints()
    view.scroll.ScrollBar:SetPoint("TOPLEFT", view.scroll, "TOPRIGHT", 6, 0)
    view.scroll.ScrollBar:SetPoint("BOTTOMLEFT", view.scroll, "BOTTOMRIGHT", 6, 0)
    view.scroll.ScrollBar:SetHideIfUnscrollable(true)
    view.scroll:SetPanExtent(ROW_HEIGHT)
    view.content = CreateFrame("Frame", nil, view.scroll)
    view.content:SetWidth(830)
    view.scroll:SetScrollChild(view.content)
    view.rows = {}
    view.message = Text(view.scroll, 0, -10, 830, "GameFontHighlight")
    view.scan = Text(view, 16, -493, 862)
    view.status = Text(view, 16, -519, 862)
    view:SetScript("OnShow", function()
        view.ticker = C_Timer.NewTicker(60, function() lw.UpdateWindow() end)
    end)
    view:SetScript("OnHide", function() view.ticker:Cancel() end)
end
