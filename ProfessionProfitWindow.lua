local _, addon = ...
local ROW_HEIGHT = 36

function addon.CreateProfessionWindow(name, title)
    local window = CreateFrame("Frame", name, UIParent, "BasicFrameTemplate")
    window:Hide()
    window:SetSize(902, 548)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window.TitleText:SetText(title)
    table.insert(UISpecialFrames, name)
    return window
end

function addon.AttachProfessionProfitWindow(profession)
    local function Character() return _G[profession.characterName] end

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
        GameTooltip_SuppressAutomaticCompareItem(GameTooltip)
        if entry.link then GameTooltip:SetHyperlink(entry.link) else GameTooltip:ClearLines() end
        for _, issue in ipairs(entry.issues) do GameTooltip:AddLine(issue, 1, 0.3, 0.3, true) end
        for _, line in ipairs(entry.lines) do
            local indent = string.rep("  ", line.depth)
            GameTooltip:AddDoubleLine(indent .. line.quantity .. " x " .. (line.link or ("Item " .. line.itemID)),
                line.expanded and "" or Money(line.cost), 1, 1, 1, 1, 1, 1)
        end
        GameTooltip:Show()
    end

    local function MakeRow(view, index)
        local row = CreateFrame("Button", nil, view.content)
        row:SetSize(830, ROW_HEIGHT)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        row.item = Text(row, 0, 0, 240)
        row.recipe = Text(row, 0, -16, 240, "GameFontDisableSmall")
        row.skill = Text(row, 246, -5, 62)
        row.quantity = Text(row, 314, -5, 32)
        row.cost = Text(row, 352, -5, 148)
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

    function profession.UpdateGoldScanStatus(view)
        if not _G[profession.catalogName] then
            view.message:SetText(profession.IsRefreshing() and ("Scanning recipes, keep your own " .. profession.name .. " open")
                or ("Open your own " .. profession.name .. " and use " .. profession.scanCommand))
        end
    end

    function profession.UpdateGoldView(view)
        if not view:IsShown() then return end
        view.materials:Update()
        view.prices:Update()
        if not view.skill:HasFocus() then view.skill:SetText(profession.GoldMaxSkill() or "") end
        local rows = {}
        local query = view.search:GetText():lower()
        for _, entry in ipairs(profession.GoldRows()) do
            local name = entry.name:match("|h%[(.-)%]|h") or entry.name
            if query == "" or name:lower():find(query, 1, true)
                or (entry.recipe.name or ""):lower():find(query, 1, true) then
                table.insert(rows, entry)
            end
        end
        for index, entry in ipairs(rows) do
            local row = view.rows[index]
            if not row then
                row = MakeRow(view, index)
                view.rows[index] = row
            end
            row.entry = entry
            row.item:SetText(entry.name)
            row.recipe:SetText("#" .. entry.recipeID .. (entry.needsRecipe and " | Unlearned/unknown recipe required" or " | Learned"))
            row.skill:SetText(entry.requiredSkill or "-")
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
        view.message:SetText(#rows == 0 and "No matching recipes" or "")
        profession.UpdateGoldScanStatus(view)
        local _, _, scannedAt, market = addon.AuctionPrices.Lookup()
        local scan = "No AH scan for this market"
        if scannedAt then
            local minutes = math.floor((GetServerTime() - scannedAt) / 60)
            scan = "Scan " .. date("%Y-%m-%d %H:%M", scannedAt) .. " | " .. minutes .. " min ago"
        end
        view.scan:SetText((market and MarketName(market) or "Market unavailable") .. " | " .. scan)
    end

    function profession.CreateGoldView(window)
        local view = CreateFrame("Frame", nil, window)
        view:SetAllPoints()
        view:Hide()
        window.gold = view
        view.search = CreateFrame("EditBox", nil, view, "SearchBoxTemplate")
        view.search:SetPoint("TOPLEFT", 21, -59)
        view.search:SetSize(105, 20)
        view.search:SetAutoFocus(false)
        local function Dropdown(x, width, label, option, choices)
            Text(view, x, -34, width, "GameFontNormal"):SetText(label)
            local dropdown = CreateFrame("DropdownButton", nil, view, "WowStyle1DropdownTemplate")
            dropdown:SetPoint("TOPLEFT", x, -57)
            dropdown:SetWidth(width)
            dropdown:SetupMenu(function(_, root)
                for _, choice in ipairs(choices) do
                    root:CreateRadio(choice[1], function() return Character().gold[option] == choice[2] end, function()
                        Character().gold[option] = choice[2]
                        profession.UpdateWindow()
                    end)
                end
            end)
            return dropdown
        end
        view.materials = Dropdown(139, 160, "Materials", "materials", profession.materialChoices)
        view.prices = Dropdown(311, 135, "Prices", "prices", {
            { "Latest lowest", "lowest" }, { "14-day median", "median" },
        })
        local unlearned = CreateFrame("CheckButton", nil, view, "UICheckButtonTemplate")
        unlearned:SetPoint("TOPLEFT", 458, -55)
        unlearned.Text:SetText("Include unlearned")
        unlearned:SetChecked(Character().gold.includeUnlearned)
        unlearned:SetScript("OnClick", function(self)
            Character().gold.includeUnlearned = self:GetChecked()
            profession.UpdateWindow()
        end)
        if profession.excludeGear then
            local gear = CreateFrame("CheckButton", nil, view, "UICheckButtonTemplate")
            gear:SetPoint("TOPLEFT", 608, -55)
            gear.Text:SetText("Exclude gear")
            gear:SetChecked(Character().gold.excludeGear)
            gear:SetScript("OnClick", function(self)
                Character().gold.excludeGear = self:GetChecked()
                profession.UpdateWindow()
            end)
        end
        local skillX = profession.excludeGear and 752 or 650
        Text(view, skillX, -34, 878 - skillX, "GameFontNormal"):SetText("Max " .. profession.shortName .. " skill")
        view.skill = CreateFrame("EditBox", nil, view, "InputBoxTemplate")
        view.skill:SetPoint("TOPLEFT", skillX + 6, -58)
        view.skill:SetSize(54, 24)
        view.skill:SetAutoFocus(false)
        view.skill:SetNumeric(true)
        view.skill:SetMaxLetters(3)
        view.skill:SetScript("OnTextChanged", function(self, userInput)
            if userInput then self.edited = true end
        end)
        view.skill:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        view.skill:SetScript("OnEscapePressed", function(self)
            self.edited = false
            self:ClearFocus()
        end)
        view.skill:SetScript("OnEditFocusLost", function(self)
            local value = tonumber(self:GetText())
            if self.edited and value then Character().gold.maxSkill = value end
            self.edited = false
            profession.UpdateWindow()
        end)
        local auto = CreateFrame("Button", nil, view, "UIPanelButtonTemplate")
        auto:SetPoint("LEFT", view.skill, "RIGHT", 6, 0)
        auto:SetSize(48, 24)
        auto:SetText("Auto")
        auto:SetScript("OnClick", function()
            view.skill:ClearFocus()
            Character().gold.maxSkill = nil
            profession.UpdateWindow()
        end)
        Text(view, 16, -93, 240, "GameFontNormal"):SetText("Item / recipe")
        Text(view, 262, -93, 62, "GameFontNormal"):SetText(profession.skillLabel)
        Text(view, 330, -93, 32, "GameFontNormal"):SetText("Qty")
        Text(view, 368, -93, 148, "GameFontNormal"):SetText("Cash materials")
        Text(view, 522, -93, 150, "GameFontNormal"):SetText("Sale value")
        Text(view, 678, -93, 184, "GameFontNormal"):SetText("Margin before AH fees")
        view.scroll = CreateFrame("ScrollFrame", nil, view, "ScrollFrameTemplate")
        view.scroll:SetPoint("TOPLEFT", 16, -120)
        view.scroll:SetPoint("BOTTOMRIGHT", -40, 40)
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
        view.scan = Text(view, 16, -519, 862)
        view.search:HookScript("OnTextChanged", function() profession.UpdateWindow() end)
    end
end
