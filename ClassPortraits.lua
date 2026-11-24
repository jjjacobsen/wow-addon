local _, addon = ...
local ownPortrait = "ReplaceMyPlayerPortrait"
local otherPortraits = "ReplaceOtherPlayerPortraits"

function addon.CreateClassPortraitsCheckbox(parent)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox.Text:SetText("Class icons for portraits")

    if JJSettings.classPortraits == nil then
        JJSettings.classPortraits = true
    end
    local function Apply(enabled)
        Settings.SetValue(ownPortrait, enabled)
        Settings.SetValue(otherPortraits, enabled)
    end
    Apply(JJSettings.classPortraits)

    local function UpdateCheckbox()
        checkbox:SetChecked(Settings.GetValue(ownPortrait) and Settings.GetValue(otherPortraits))
    end

    checkbox:SetScript("OnClick", function(self)
        JJSettings.classPortraits = not not self:GetChecked()
        Apply(JJSettings.classPortraits)
    end)
    Settings.SetOnValueChangedCallback(ownPortrait, UpdateCheckbox)
    Settings.SetOnValueChangedCallback(otherPortraits, UpdateCheckbox)
    UpdateCheckbox()
    return checkbox
end
