local _, addon = ...
local ROW_HEIGHT = 36

local function Text(parent, x, y, width, template)
    local text = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    text:SetPoint("TOPLEFT", x, y)
    text:SetSize(width, 20)
    text:SetJustifyH("LEFT")
    return text
end

local function LinkName(link)
    return link and link:match("|h%[(.+)%]|h")
end

local function ItemTooltip(row)
    if not row.entry.link then return end
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip_SuppressAutomaticCompareItem(GameTooltip)
    GameTooltip:SetHyperlink(row.entry.link)
    GameTooltip:Show()
end

function addon.CreateProfessionHiddenView(profession, view)
    local hidden = CreateFrame("Frame", nil, view)
    hidden:SetAllPoints()
    hidden:Hide()
    hidden.rows = {}
    view.hidden = hidden
    local function Settings() return _G[profession.characterName].gold end
    local UpdateRows
    local function MakeRow(index)
        local row = CreateFrame("Button", nil, hidden.content)
        row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
        row:SetSize(830, ROW_HEIGHT)
        row.item = Text(row, 0, -5, 738)
        row:SetScript("OnEnter", ItemTooltip)
        row:SetScript("OnLeave", GameTooltip_Hide)
        row:SetScript("OnHide", function(self)
            if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
        end)
        row:SetScript("OnClick", function(self)
            if self.entry.link then HandleModifiedItemClick(self.entry.link) end
        end)
        row.unhide = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.unhide:SetPoint("TOPRIGHT", 0, 0)
        row.unhide:SetSize(80, 24)
        row.unhide:SetText("Unhide")
        row.unhide:SetScript("OnClick", function()
            Settings().hiddenRecipes[row.entry.recipeID] = nil
            UpdateRows()
        end)
        return row
    end
    UpdateRows = function()
        local entries = {}
        local catalog = _G[profession.catalogName]
        for recipeID in pairs(Settings().hiddenRecipes or {}) do
            local recipe = catalog and catalog.recipes[recipeID]
            local item = recipe and recipe.itemID and catalog.items[recipe.itemID]
            local itemLink, recipeLink = item and item.link, recipe and recipe.link
            local link = LinkName(itemLink) and itemLink or LinkName(recipeLink) and recipeLink
            local name = LinkName(link) or (recipe and recipe.name)
            if not name or name == "" then name = "Recipe #" .. recipeID end
            table.insert(entries, { recipeID = recipeID, name = name, link = link })
        end
        table.sort(entries, function(a, b)
            local left, right = a.name:lower(), b.name:lower()
            if left == right then return a.recipeID < b.recipeID end
            return left < right
        end)
        for index, entry in ipairs(entries) do
            local row = hidden.rows[index]
            if not row then row = MakeRow(index) hidden.rows[index] = row end
            row.entry = entry
            row.item:SetText(entry.link or entry.name)
            row:Show()
        end
        for index = #entries + 1, #hidden.rows do hidden.rows[index]:Hide() end
        hidden.message:SetText(#entries == 0 and "No hidden recipes" or "")
        hidden.content:SetHeight(math.max(1, #entries * ROW_HEIGHT))
        hidden.scroll:SetVerticalScroll(math.min(hidden.scroll:GetVerticalScroll(), hidden.scroll:GetVerticalScrollRange()))
    end
    hidden.back = CreateFrame("Button", nil, hidden, "UIPanelButtonTemplate")
    hidden.back:SetPoint("TOPLEFT", 16, -34)
    hidden.back:SetSize(78, 24)
    hidden.back:SetText("Back")
    hidden.back:SetScript("OnClick", function()
        hidden:Hide()
        view.page:Show()
        profession.UpdateGoldView(view)
    end)
    Text(hidden, 108, -35, 738, "GameFontNormalLarge"):SetText("Hidden recipes")
    hidden.scroll = CreateFrame("ScrollFrame", nil, hidden, "ScrollFrameTemplate")
    hidden.scroll:SetPoint("TOPLEFT", 16, -75)
    hidden.scroll:SetPoint("BOTTOMRIGHT", -40, 40)
    hidden.scroll.ScrollBar:ClearAllPoints()
    hidden.scroll.ScrollBar:SetPoint("TOPLEFT", hidden.scroll, "TOPRIGHT", 6, 0)
    hidden.scroll.ScrollBar:SetPoint("BOTTOMLEFT", hidden.scroll, "BOTTOMRIGHT", 6, 0)
    hidden.scroll.ScrollBar:SetHideIfUnscrollable(true)
    hidden.scroll:SetPanExtent(ROW_HEIGHT)
    hidden.content = CreateFrame("Frame", nil, hidden.scroll)
    hidden.content:SetWidth(830)
    hidden.scroll:SetScrollChild(hidden.content)
    hidden.message = Text(hidden.scroll, 0, -10, 830)
    function view.OpenHidden()
        view.page:Hide()
        view.detail:Hide()
        view.records:Hide()
        hidden:Show()
        hidden.scroll:SetVerticalScroll(0)
        UpdateRows()
    end
end
