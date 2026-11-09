local _, addon = ...
local enabled, bankOpen, captureQueued, window, bankButton
local events = CreateFrame("Frame")
local columns, slotSize, spacing = 8, 37, 5
local stride = slotSize + spacing
local gridWidth = columns * stride - spacing

local function ShowItemTooltip(button)
    if button.hyperlink then
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(button.hyperlink)
        GameTooltip:Show()
    end
end

local function CreateWindow()
    window = CreateFrame("Frame", "JJSavedBankFrame", UIParent, "BasicFrameTemplate")
    window:Hide()
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:EnableMouse(true)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window.TitleText:SetText("Saved Bank")
    table.insert(UISpecialFrames, "JJSavedBankFrame")

    window.character = window:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    window.character:SetPoint("TOPLEFT", 16, -36)
    window.updated = window:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    window.updated:SetPoint("TOPLEFT", 16, -56)

    window.scroll = CreateFrame("ScrollFrame", nil, window, "ScrollFrameTemplate")
    window.scroll:SetPoint("TOPLEFT", 16, -88)
    window.scroll:SetPoint("BOTTOMRIGHT", -36, 16)
    window.scroll.ScrollBar:ClearAllPoints()
    window.scroll.ScrollBar:SetPoint("TOPLEFT", window.scroll, "TOPRIGHT", 6, 0)
    window.scroll.ScrollBar:SetPoint("BOTTOMLEFT", window.scroll, "BOTTOMRIGHT", 6, 0)
    window.scroll.ScrollBar:SetHideIfUnscrollable(true)
    window.scroll:SetPanExtent(stride)
    window.content = CreateFrame("Frame", nil, window.scroll)
    window.content:SetWidth(gridWidth)
    window.scroll:SetScrollChild(window.content)
    window.buttons = {}

    window.message = window:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    window.message:SetPoint("CENTER", window.scroll, "CENTER")
    window.message:SetText("Visit a bank to save its contents")
end

local function RefreshWindow()
    local snapshot = JJSavedBank
    window.character:SetText(UnitName("player"))
    window.updated:SetText(snapshot and "Last updated: " .. date("%Y-%m-%d %H:%M:%S", snapshot.updatedAt) or "Not yet saved")
    window.message:SetShown(not snapshot)

    local index = 0
    if snapshot then
        for _, container in ipairs(snapshot.containers) do
            for _, item in ipairs(container.slots) do
                index = index + 1
                local button = window.buttons[index]
                if not button then
                    -- Bare ItemButtons have no bank click, drag, or purchase handlers.
                    button = CreateFrame("ItemButton", nil, window.content)
                    button:SetSize(slotSize, slotSize)
                    button.icon:SetAllPoints()
                    button:SetPoint("TOPLEFT", (index - 1) % columns * stride, -math.floor((index - 1) / columns) * stride)
                    button:SetScript("OnEnter", ShowItemTooltip)
                    button:SetScript("OnLeave", GameTooltip_Hide)
                    button:SetScript("OnHide", function(self)
                        if GameTooltip:GetOwner() == self then
                            GameTooltip:Hide()
                        end
                    end)
                    window.buttons[index] = button
                end
                button.hyperlink = item and item.hyperlink or nil
                button:SetItemButtonTexture(item and item.iconFileID or nil)
                button:SetItemButtonCount(item and item.stackCount or 0)
                button:SetItemButtonQuality(item and item.quality or nil, button.hyperlink)
                button:Show()
                if button:IsMouseOver() then
                    if GameTooltip:GetOwner() == button then
                        GameTooltip:Hide()
                    end
                    ShowItemTooltip(button)
                end
            end
        end
    end
    for unused = index + 1, #window.buttons do
        window.buttons[unused]:Hide()
    end
    local rows = math.max(1, math.ceil(index / columns))
    local visibleRows = snapshot and math.min(10, rows) or 3
    window:SetSize(gridWidth + 52, visibleRows * stride - spacing + 104)
    window.content:SetHeight(rows * stride - spacing)
    window.scroll:SetVerticalScroll(math.min(window.scroll:GetVerticalScroll(), window.scroll:GetVerticalScrollRange()))
end

function addon.SavedBankCommand()
    if not enabled then
        print("wow-addon: Enable Saved Bank in /jj, then click Reload")
        return
    end
    if not window then
        CreateWindow()
    end
    if window:IsShown() then
        window:Hide()
    else
        RefreshWindow()
        window:Show()
    end
end

local function CaptureBank()
    local bankType = Enum.BankType.Character
    if not bankOpen or not C_Bank.CanViewBank(bankType) then
        return
    end
    -- Camelot includes the base bank and extra bags in this list, not container -1 (keyring).
    local tabs = C_Bank.FetchPurchasedBankTabData(bankType)
    if not tabs or #tabs == 0 or #tabs ~= C_Bank.FetchNumPurchasedBankTabs(bankType) then
        return
    end
    local containers = {}
    for index, tab in ipairs(tabs) do
        local size = C_Container.GetContainerNumSlots(tab.ID)
        if index == 1 and size == 0 then
            return
        end
        local container = { id = tab.ID, slots = {} }
        local emptySlots = 0
        for slot = 1, size do
            local info = C_Container.GetContainerItemInfo(tab.ID, slot)
            if info then
                if not info.hyperlink or info.hyperlink == "" or info.stackCount == 0 then
                    return
                end
                container.slots[slot] = {
                    hyperlink = info.hyperlink,
                    iconFileID = info.iconFileID,
                    stackCount = info.stackCount,
                    quality = info.quality,
                }
            else
                emptySlots = emptySlots + 1
                container.slots[slot] = false
            end
        end
        -- Missing item data must not replace a saved bank with apparent empty slots.
        if emptySlots ~= C_Container.GetContainerNumFreeSlots(tab.ID) then
            return
        end
        containers[index] = container
    end
    JJSavedBank = {
        updatedAt = GetServerTime(),
        containers = containers,
    }
    if window and window:IsShown() then
        RefreshWindow()
    end
end

local function QueueCapture()
    if not bankOpen or captureQueued then
        return
    end
    captureQueued = true
    RunNextFrame(function()
        captureQueued = false
        CaptureBank()
    end)
end

local function InstallBankButton()
    local bags = ContainerFrameCombinedBags
    if bankButton or not bags then
        return
    end
    bankButton = CreateFrame("Button", nil, bags, "UIPanelButtonTemplate")
    bankButton:SetSize(58, 22)
    bankButton:SetPoint("TOPRIGHT", -45, -35)
    bankButton:SetText("Bank")
    bankButton:SetScript("OnClick", addon.SavedBankCommand)
    -- Reserve space on the search row, to the left of the native sort button.
    hooksecurefunc(bags, "SetSearchBoxPoint", function(_, searchBox)
        searchBox:ClearAllPoints()
        searchBox:SetPoint("TOPLEFT", bags, "TOPLEFT", 62, -37)
        searchBox:SetPoint("TOPRIGHT", bankButton, "TOPLEFT", -8, -2)
    end)
    if bags:IsShown() then
        bags:UpdateSearchBox()
    end
    events:UnregisterEvent("ADDON_LOADED")
end

addon.RegisterFeature("savedBank", "Saved Bank", function(value)
    enabled = value
    if not enabled then
        return
    end
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("BANKFRAME_OPENED")
    events:RegisterEvent("BANKFRAME_CLOSED")
    events:RegisterEvent("BAG_UPDATE_DELAYED")
    events:RegisterEvent("BAG_CONTAINER_UPDATE")
    events:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    events:RegisterEvent("BANK_TABS_CHANGED")
    events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
    events:SetScript("OnEvent", function(_, event, bankType)
        if event == "ADDON_LOADED" then
            InstallBankButton()
        elseif event == "BANKFRAME_CLOSED" then
            bankOpen = false
        else
            if event == "BANKFRAME_OPENED" then
                bankOpen = true
            elseif event == "BANK_TABS_CHANGED" and bankType ~= Enum.BankType.Character then
                return
            end
            QueueCapture()
        end
    end)
    InstallBankButton()
end)
