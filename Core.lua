local addonName, addon = ...
local features = {}

function addon.RegisterFeature(key, label, apply)
    table.insert(features, { key = key, label = label, apply = apply })
end

local function CreateSettings()
    local window = CreateFrame("Frame", "JJSettingsFrame", UIParent, "BasicFrameTemplate")
    window:Hide()
    window:SetSize(300, 84 + (#features + 1) * 32)
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

    SLASH_JJSETTINGS1 = "/jj"
    SlashCmdList.JJSETTINGS = function(message)
        local command = message:lower():match("^%s*(.-)%s*$")
        if command == "" then
            window:SetShown(not window:IsShown())
        elseif command == "scan" or command == "clear" then
            addon.AuctionHouseCommand(command)
        elseif command == "tank" then
            ToggleTankMode()
        else
            print("wow-addon: /jj, /jj scan, /jj clear, /jj tank")
        end
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(self, event, loadedAddon)
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
    CreateSettings()
end)
