local addonName, addon = ...
local features = {}
local bagHeaderButtons = {}
local bagHeaderEvents = CreateFrame("Frame")

local function InstallBagHeaderButtons()
    local bags = ContainerFrameCombinedBags
    if not bags then
        bagHeaderEvents:RegisterEvent("ADDON_LOADED")
        return
    end
    for index, entry in ipairs(bagHeaderButtons) do
        if not entry.button then
            local button = CreateFrame("Button", nil, bags, "UIPanelButtonTemplate")
            button:SetSize(entry.width, 22)
            if index == 1 then
                button:SetPoint("TOPRIGHT", -45, -35)
            else
                button:SetPoint("RIGHT", bagHeaderButtons[index - 1].button, "LEFT", -4, 0)
            end
            button:SetText(entry.text)
            button:SetScript("OnClick", entry.onClick)
            entry.button = button
        end
    end
    if not bagHeaderEvents.hooked then
        bagHeaderEvents.hooked = true
        hooksecurefunc(bags, "SetSearchBoxPoint", function(_, searchBox)
            searchBox:ClearAllPoints()
            searchBox:SetPoint("TOPLEFT", bags, "TOPLEFT", 62, -37)
            searchBox:SetPoint("TOPRIGHT", bagHeaderButtons[#bagHeaderButtons].button, "TOPLEFT", -8, -2)
        end)
    end
    if bags:IsShown() then
        bags:UpdateSearchBox()
    end
    bagHeaderEvents:UnregisterEvent("ADDON_LOADED")
end

bagHeaderEvents:SetScript("OnEvent", InstallBagHeaderButtons)

function addon.AddBagHeaderButton(text, width, onClick)
    table.insert(bagHeaderButtons, { text = text, width = width, onClick = onClick })
    InstallBagHeaderButtons()
end

function addon.RegisterFeature(key, label, apply)
    table.insert(features, { key = key, label = label, apply = apply })
end

local function CreateSettings()
    local window = CreateFrame("Frame", "JJSettingsFrame", UIParent, "BasicFrameTemplate")
    window:Hide()
    window:SetSize(300, 84 + (#features + 2) * 32)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:EnableMouse(true)
    window.TitleText:SetText("wow-addon")
    table.insert(UISpecialFrames, "JJSettingsFrame")

    local close = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    close:SetSize(80, 24)
    close:SetPoint("BOTTOMRIGHT", -12, 12)
    close:SetText("Close")
    close:SetScript("OnClick", function()
        window:Hide()
    end)

    local reload = CreateFrame("Button", nil, window, "UIPanelButtonTemplate")
    reload:SetSize(80, 24)
    reload:SetPoint("RIGHT", close, "LEFT", -8, 0)
    reload:SetText("Reload")
    reload:Disable()
    reload:SetScript("OnClick", function()
        ReloadUI()
    end)

    local function UpdateReload()
        for _, feature in ipairs(features) do
            if JJSettings[feature.key] ~= feature.initialEnabled then
                reload:Enable()
                return
            end
        end
        reload:Disable()
    end

    for index, feature in ipairs(features) do
        local checkbox = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
        checkbox:SetPoint("TOPLEFT", 12, -32 - (index - 1) * 32)
        checkbox.Text:SetText(feature.label)
        checkbox:SetChecked(JJSettings[feature.key])
        checkbox:SetScript("OnClick", function(self)
            JJSettings[feature.key] = self:GetChecked()
            UpdateReload()
        end)
    end

    local tank = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
    tank:SetPoint("TOPLEFT", 12, -32 - #features * 32)
    tank.Text:SetText("Tank mode")
    tank:SetChecked(addon.IsTankNameplatesEnabled())

    local function ToggleTankMode()
        addon.ToggleTankNameplates()
        tank:SetChecked(addon.IsTankNameplatesEnabled())
    end

    tank:SetScript("OnClick", ToggleTankMode)

    local damageMeter = CreateFrame("CheckButton", nil, window, "UICheckButtonTemplate")
    damageMeter:SetPoint("TOPLEFT", 12, -32 - (#features + 1) * 32)
    damageMeter.Text:SetText("Enable Damage Meter")
    local function UpdateDamageMeter()
        damageMeter:SetChecked(addon.IsDamageMeterEnabled())
    end
    UpdateDamageMeter()
    damageMeter:SetScript("OnShow", UpdateDamageMeter)
    damageMeter:RegisterEvent("CVAR_UPDATE")
    damageMeter:SetScript("OnEvent", function(_, _, name)
        if name:lower() == "damagemeterenabled" then
            UpdateDamageMeter()
        end
    end)
    local function ToggleDamageMeter()
        addon.ToggleDamageMeter()
        UpdateDamageMeter()
    end
    damageMeter:SetScript("OnClick", ToggleDamageMeter)

    SLASH_JJSETTINGS1 = "/jj"
    SlashCmdList.JJSETTINGS = function(message)
        local command = message:lower():match("^%s*(.-)%s*$")
        if command == "" then
            window:SetShown(not window:IsShown())
        elseif command == "scan" or command == "clear" then
            addon.AuctionHouseCommand(command)
        elseif command == "bank" then
            addon.SavedBankCommand()
        elseif command == "free" then
            addon.FreeSlotCommand()
        elseif command == "lw" then
            addon.LeatherworkingCommand()
        elseif command == "lwscan" then
            addon.LeatherworkingScanCommand()
        elseif command == "cook" then
            addon.CookingCommand()
        elseif command == "cookscan" then
            addon.CookingScanCommand()
        elseif command == "fa" then
            addon.FirstAidCommand()
        elseif command == "fascan" then
            addon.FirstAidScanCommand()
        elseif command == "eng" then
            addon.EngineeringCommand()
        elseif command == "engscan" then
            addon.EngineeringScanCommand()
        elseif command == "tank" then
            ToggleTankMode()
        elseif command == "dmg" then
            ToggleDamageMeter()
        else
            print("wow-addon: /jj, /jj bank, /jj free, /jj scan, /jj clear, /jj tank, /jj dmg, /jj lw, /jj lwscan, /jj cook, /jj cookscan, /jj fa, /jj fascan, /jj eng, /jj engscan")
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, loadedAddon)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent(event)
        addon.InitializeDamageMeter()
        CreateSettings()
        return
    end
    if loadedAddon ~= addonName then
        return
    end
    self:UnregisterEvent(event)

    JJSettings = JJSettings or {}
    for _, feature in ipairs(features) do
        if JJSettings[feature.key] == nil then
            JJSettings[feature.key] = true
        end
    end
    for _, feature in ipairs(features) do
        feature.initialEnabled = JJSettings[feature.key]
        feature.apply(feature.initialEnabled)
    end

    addon.InitializeTankNameplates()
    self:RegisterEvent("PLAYER_LOGIN")
end)
