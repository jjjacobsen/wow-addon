local _, addon = ...
local enabled, window, candidate, border, highlightedButton, refreshQueued
local skipped = {}
local events = CreateFrame("Frame")

local function ScanBags()
    local cheapest
    -- Use the native carried-bag limit, including profession bags and any supported reagent bag.
    for bag = Enum.BagIndex.Backpack, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local size = C_Container.GetContainerNumSlots(bag)
        if size == 0 and (bag == Enum.BagIndex.Backpack or GetInventoryItemID("player", C_Container.ContainerIDToInventoryID(bag))) then
            return nil, "Waiting for bag data"
        end
        local emptySlots = 0
        for slot = 1, size do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if not info then
                emptySlots = emptySlots + 1
            elseif not info.itemID or info.itemID == 0 then
                return nil, "Waiting for item data"
            elseif not JJFreeSlotKeep[info.itemID] and not skipped[info.itemID] then
                if info.isLocked then
                    return nil, "Waiting for unlocked items"
                end
                if not info.hyperlink or info.hyperlink == "" or not info.stackCount or info.stackCount < 1 then
                    return nil, "Waiting for item data"
                end
                local price, classID = select(11, C_Item.GetItemInfo(info.hyperlink))
                local guid = C_Item.GetItemGUID(ItemLocation:CreateFromBagAndSlot(bag, slot))
                if price == nil or classID == nil or not guid or guid == "" then
                    return nil, "Waiting for item data"
                end
                local questInfo = C_Container.GetContainerItemQuestInfo(bag, slot)
                -- A questID marks a quest starter, whether or not its quest is active.
                if not questInfo.isQuestItem and not questInfo.questID and classID ~= Enum.ItemClass.Questitem then
                    local total = price * info.stackCount
                    if not cheapest or total < cheapest.total then
                        cheapest = {
                            bag = bag, slot = slot, guid = guid, itemID = info.itemID,
                            link = info.hyperlink, icon = info.iconFileID,
                            count = info.stackCount, price = price, total = total,
                        }
                    end
                end
            end
        end
        if emptySlots ~= C_Container.GetContainerNumFreeSlots(bag) then
            return nil, "Waiting for bag data"
        end
    end
    return cheapest, cheapest and "" or "No remaining items"
end

local function SameStack(first, second)
    return first and second and first.bag == second.bag and first.slot == second.slot
        and first.guid == second.guid and first.itemID == second.itemID
        and first.count == second.count and first.price == second.price and first.link == second.link
end

local function UpdateHighlight()
    border:Hide()
    if not candidate or InCombatLockdown() or GetCursorInfo() then
        return
    end
    local info = C_Container.GetContainerItemInfo(candidate.bag, candidate.slot)
    if not info or info.isLocked or info.itemID ~= candidate.itemID or info.stackCount ~= candidate.count
        or C_Item.GetItemGUID(ItemLocation:CreateFromBagAndSlot(candidate.bag, candidate.slot)) ~= candidate.guid then
        return
    end
    local button = ContainerFrameUtil_GetItemButtonAndContainer(candidate.bag, candidate.slot)
    if button and button:IsShown() then
        if highlightedButton ~= button then
            highlightedButton = button
            border:SetParent(button)
            border:SetFrameLevel(button:GetFrameLevel() + 5)
            border:ClearAllPoints()
            border:SetPoint("TOPLEFT", button, "TOPLEFT", -2, 2)
            border:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 2, -2)
        end
        border:Show()
    end
end

local function RefreshKeepList()
    local ids = {}
    for itemID in pairs(JJFreeSlotKeep) do
        table.insert(ids, itemID)
    end
    table.sort(ids)
    for index, itemID in ipairs(ids) do
        local row = window.keepRows[index]
        if not row then
            row = CreateFrame("Frame", nil, window.keepContent)
            row:SetSize(296, 26)
            row:SetPoint("TOPLEFT", 0, -(index - 1) * 26)
            row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.label:SetPoint("LEFT")
            row.label:SetWidth(220)
            row.label:SetJustifyH("LEFT")
            row.remove = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
            row.remove:SetSize(70, 22)
            row.remove:SetPoint("RIGHT")
            row.remove:SetText("Remove")
            row.remove:SetScript("OnClick", function()
                JJFreeSlotKeep[row.itemID] = nil
                window:Refresh()
            end)
            window.keepRows[index] = row
        end
        row.itemID = itemID
        local name, link = C_Item.GetItemInfo(itemID)
        row.label:SetText(link or name or ("Item " .. itemID))
        row:Show()
    end
    for index = #ids + 1, #window.keepRows do
        window.keepRows[index]:Hide()
    end
    window.keepContent:SetHeight(math.max(1, #ids * 26))
    window.keepScroll:SetVerticalScroll(math.min(window.keepScroll:GetVerticalScroll(), window.keepScroll:GetVerticalScrollRange()))
end

local function Refresh()
    if not window or not window:IsShown() then
        return
    end
    local message
    if InCombatLockdown() then
        candidate, message = nil, "Unavailable in combat"
    elseif GetCursorInfo() then
        candidate, message = nil, "Empty the cursor first"
    else
        candidate, message = ScanBags()
    end
    window.icon:SetTexture(candidate and candidate.icon or nil)
    window.itemLink = candidate and candidate.link or nil
    window.link:SetText(candidate and candidate.link or "")
    window.count:SetText(candidate and ("Count: " .. candidate.count) or "")
    window.value:SetText(candidate and ("Vendor: " .. GetMoneyString(candidate.total, true)) or "")
    window.status:SetText(message)
    window.destroy:SetEnabled(candidate ~= nil)
    window.next:SetEnabled(candidate ~= nil)
    window.keep:SetEnabled(candidate ~= nil)
    if GameTooltip:GetOwner() == window.item then
        GameTooltip:Hide()
    end
    if window.keepScroll:IsShown() then
        RefreshKeepList()
    end
    if candidate then
        OpenBag(candidate.bag)
    end
    UpdateHighlight()
end

local function Destroy()
    local selected = candidate
    if not selected or InCombatLockdown() or GetCursorInfo() then
        Refresh()
        return
    end
    -- Recheck the complete ranking as well as this exact stack before touching the cursor.
    local current = ScanBags()
    if not SameStack(selected, current) then
        Refresh()
        window.status:SetText("Bags changed. Review and click again")
        return
    end
    C_Container.PickupContainerItem(selected.bag, selected.slot)
    local cursorItem = C_Cursor.GetCursorItem()
    if not cursorItem or C_Item.GetItemGUID(cursorItem) ~= selected.guid then
        ClearCursor()
        Refresh()
        window.status:SetText("Item changed. Review and click again")
        return
    end
    -- Keep this native handoff in the hardware click. Mouse dialogs require an item on the cursor.
    -- Blizzard chooses the normal or typed DELETE dialog and owns all acceptance/deletion.
    C_Item.ConfirmDeleteItem(selected.guid)
    Refresh()
end

local function CreateWindow()
    window = CreateFrame("Frame", "JJFreeSlotFrame", UIParent, "BasicFrameTemplate")
    window:Hide()
    window:SetSize(360, 218)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:EnableMouse(true)
    window:SetClampedToScreen(true)
    window.TitleText:SetText("Free Slot")
    window.Refresh = Refresh
    table.insert(UISpecialFrames, "JJFreeSlotFrame")

    border = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    border:EnableMouse(false)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2 })
    border:SetBackdropBorderColor(1, 0.82, 0)
    border:Hide()

    window.item = CreateFrame("Button", nil, window)
    window.item:SetSize(40, 40)
    window.item:SetPoint("TOPLEFT", 16, -40)
    window.icon = window.item:CreateTexture(nil, "ARTWORK")
    window.icon:SetAllPoints()
    window.item:SetScript("OnEnter", function(self)
        if window.itemLink then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(window.itemLink)
            GameTooltip:Show()
        end
    end)
    window.item:SetScript("OnLeave", GameTooltip_Hide)
    window.link = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    window.link:SetPoint("TOPLEFT", 66, -40)
    window.link:SetSize(278, 40)
    window.link:SetJustifyH("LEFT")
    window.link:SetJustifyV("TOP")
    window.count = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    window.count:SetPoint("TOPLEFT", 16, -90)
    window.value = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    window.value:SetPoint("TOPLEFT", 16, -112)
    window.status = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    window.status:SetPoint("TOPLEFT", 16, -137)

    local function Button(text, width, x, onClick)
        local button = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
        button:SetSize(width, 24)
        button:SetPoint("TOPLEFT", x, -159)
        button:SetText(text)
        button:SetScript("OnClick", onClick)
        return button
    end
    window.destroy = Button("Destroy…", 90, 16, Destroy)
    window.next = Button("Next", 60, 110, function()
        if candidate then
            skipped[candidate.itemID] = true
            Refresh()
        end
    end)
    window.keep = Button("Keep", 60, 174, function()
        if candidate then
            JJFreeSlotKeep[candidate.itemID] = true
            Refresh()
        end
    end)
    Button("Close", 80, 238, function() window:Hide() end)

    window.keepScroll = CreateFrame("ScrollFrame", nil, window, "ScrollFrameTemplate")
    window.keepScroll:SetPoint("TOPLEFT", 16, -220)
    window.keepScroll:SetSize(296, 104)
    window.keepScroll.ScrollBar:SetHideIfUnscrollable(true)
    window.keepScroll:SetPanExtent(26)
    window.keepContent = CreateFrame("Frame", nil, window.keepScroll)
    window.keepContent:SetWidth(296)
    window.keepScroll:SetScrollChild(window.keepContent)
    window.keepRows = {}
    window.keepScroll:Hide()
    local keepList = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    keepList:SetSize(90, 22)
    keepList:SetPoint("TOPLEFT", 16, -188)
    keepList:SetText("Keep list")
    keepList:SetScript("OnClick", function()
        local show = not window.keepScroll:IsShown()
        window.keepScroll:SetShown(show)
        window:SetHeight(show and 340 or 218)
        if show then
            RefreshKeepList()
        end
    end)
    window:SetScript("OnShow", Refresh)
    window:SetScript("OnHide", function()
        skipped = {}
        candidate = nil
        border:Hide()
        if GameTooltip:GetOwner() == window.item then
            GameTooltip:Hide()
        end
    end)
    window:SetScript("OnUpdate", UpdateHighlight)
end

function addon.FreeSlotCommand()
    if not enabled then
        print("wow-addon: Enable Free Slot in /jj, then click Reload")
        return
    end
    if InCombatLockdown() then
        print("wow-addon: Free Slot is unavailable in combat")
        return
    end
    if not window then
        CreateWindow()
    end
    window:SetShown(not window:IsShown())
end

addon.RegisterFeature("freeSlot", "Free Slot", function(value)
    enabled = value
    if not enabled then
        return
    end
    JJFreeSlotKeep = JJFreeSlotKeep or {}
    addon.AddBagHeaderButton("Free Slot", 76, addon.FreeSlotCommand)
    events:RegisterEvent("BAG_UPDATE_DELAYED")
    events:RegisterEvent("BAG_CONTAINER_UPDATE")
    events:RegisterEvent("ITEM_LOCK_CHANGED")
    events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    events:RegisterEvent("CURSOR_CHANGED")
    events:RegisterEvent("PLAYER_REGEN_DISABLED")
    events:SetScript("OnEvent", function(_, event)
        if not window or not window:IsShown() then
            return
        end
        if event == "PLAYER_REGEN_DISABLED" then
            window:Hide()
        elseif not refreshQueued then
            refreshQueued = true
            RunNextFrame(function()
                refreshQueued = false
                Refresh()
            end)
        end
    end)
end)
