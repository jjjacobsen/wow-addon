local _, addon = ...
local lw = addon.Leatherworking
local ROW_HEIGHT = 36

local function Text(parent, x, y, width, template)
    local text = parent:CreateFontString(nil, "OVERLAY", template or "GameFontHighlight")
    text:SetPoint("TOPLEFT", x, y)
    text:SetSize(width, 20)
    text:SetJustifyH("LEFT")
    return text
end

function lw.CreateExcludedGearView(window, onBack)
    local excluded = CreateFrame("Frame", nil, window)
    excluded:SetAllPoints()
    excluded:Hide()
    excluded.rows = {}
    local entries = {}
    local function MakeRow()
        local row = CreateFrame("Button", nil, excluded.content)
        row:SetSize(830, ROW_HEIGHT)
        row.item = Text(row, 0, -5, 738)
        row:SetScript("OnEnter", function(self)
            if not self.entry.link then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.entry.link)
            GameTooltip:Show()
        end)
        row:SetScript("OnLeave", GameTooltip_Hide)
        row:SetScript("OnHide", function(self)
            if GameTooltip:GetOwner() == self then GameTooltip:Hide() end
        end)
        row:SetScript("OnClick", function(self)
            if self.entry.link then HandleModifiedItemClick(self.entry.link) end
        end)
        row.restore = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
        row.restore:SetPoint("TOPRIGHT", 0, 0)
        row.restore:SetSize(80, 24)
        row.restore:SetText("Restore")
        row.restore:SetScript("OnClick", function()
            JJLWCharacter.excludedGear[row.entry.itemID] = nil
            excluded:UpdateRows()
        end)
        return row
    end
    local function RenderRows()
        local offset = math.floor(excluded.scroll:GetVerticalScroll() / ROW_HEIGHT)
        local count = excluded.scroll:IsVisible() and math.min(#entries - offset,
            math.ceil(excluded.scroll:GetHeight() / ROW_HEIGHT) + 1) or 0
        for index = 1, count do
            local entry = entries[offset + index]
            local row = excluded.rows[index]
            if not row then row = MakeRow() excluded.rows[index] = row end
            row:SetPoint("TOPLEFT", 0, -(offset + index - 1) * ROW_HEIGHT)
            row.entry = entry
            row.item:SetText(entry.link or entry.name)
            row:Show()
            if GameTooltip:GetOwner() == row then
                if row:IsMouseOver() and entry.link then
                    row:GetScript("OnEnter")(row)
                else
                    GameTooltip:Hide()
                end
            end
        end
        for index = math.max(1, count + 1), #excluded.rows do
            local row = excluded.rows[index]
            row:Hide()
            row.entry = nil
        end
    end
    function excluded:UpdateRows()
        entries = {}
        for itemID in pairs(JJLWCharacter.excludedGear) do
            local item = JJLWCatalog and JJLWCatalog.items[itemID]
            local link = item and item.link
            local name = link and link:match("|h%[(.+)%]|h") or "Item #" .. itemID
            table.insert(entries, { itemID = itemID, name = name, link = link })
        end
        table.sort(entries, function(a, b)
            local left, right = a.name:lower(), b.name:lower()
            if left == right then return a.itemID < b.itemID end
            return left < right
        end)
        excluded.message:SetText(#entries == 0 and "No excluded gear" or "")
        excluded.content:SetHeight(math.max(1, #entries * ROW_HEIGHT))
        excluded.scroll:SetVerticalScroll(math.min(excluded.scroll:GetVerticalScroll(),
            math.max(0, excluded.content:GetHeight() - excluded.scroll:GetHeight())))
        RenderRows()
    end
    local back = CreateFrame("Button", nil, excluded, "UIPanelButtonTemplate")
    back:SetPoint("TOPLEFT", 16, -34)
    back:SetSize(78, 24)
    back:SetText("Back")
    back:SetScript("OnClick", onBack)
    Text(excluded, 108, -35, 738, "GameFontNormalLarge"):SetText("Excluded gear")
    excluded.scroll = CreateFrame("ScrollFrame", nil, excluded, "ScrollFrameTemplate")
    excluded.scroll:SetPoint("TOPLEFT", 16, -75)
    excluded.scroll:SetPoint("BOTTOMRIGHT", -40, 40)
    excluded.scroll.ScrollBar:ClearAllPoints()
    excluded.scroll.ScrollBar:SetPoint("TOPLEFT", excluded.scroll, "TOPRIGHT", 6, 0)
    excluded.scroll.ScrollBar:SetPoint("BOTTOMLEFT", excluded.scroll, "BOTTOMRIGHT", 6, 0)
    excluded.scroll.ScrollBar:SetHideIfUnscrollable(true)
    excluded.scroll:SetPanExtent(ROW_HEIGHT)
    excluded.content = CreateFrame("Frame", nil, excluded.scroll)
    excluded.content:SetWidth(830)
    excluded.scroll:SetScrollChild(excluded.content)
    excluded.message = Text(excluded.scroll, 0, -10, 830)
    excluded.scroll:HookScript("OnVerticalScroll", RenderRows)
    excluded.scroll:HookScript("OnSizeChanged", RenderRows)
    excluded.scroll:HookScript("OnShow", RenderRows)
    excluded.scroll:HookScript("OnHide", RenderRows)
    return excluded
end
