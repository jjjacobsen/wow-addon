local _, addon = ...
local enabled = false
local hooked = false
local events = CreateFrame("Frame")

local function ColorTankNameplate(frame)
    if not enabled or frame:IsForbidden() then
        return
    end

    local unit = frame.unit
    if not unit or not unit:match("^nameplate%d+$") or not UnitCanAttack("player", unit) then
        return
    end

    -- Detailed threat values can be secret on nameplates, so use threat state
    local status = UnitThreatSituation("player", unit)
    if status == 2 or status == 3 then
        frame.healthBar:SetStatusBarColor(0, 0.5, 1)
    end
end

local function RefreshNameplates()
    for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
        local frame = nameplate.UnitFrame
        if frame and frame.unit then
            CompactUnitFrame_UpdateHealthColor(frame)
        end
    end
end

events:SetScript("OnEvent", RefreshNameplates)

function addon.IsTankNameplatesEnabled()
    return enabled
end

local function SetTankNameplates(value)
    enabled = value
    JJTankMode = enabled
    if not hooked then
        hooksecurefunc("CompactUnitFrame_UpdateHealthColor", ColorTankNameplate)
        hooked = true
    end

    if enabled then
        events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        events:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
        events:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
    else
        events:UnregisterAllEvents()
    end

    RefreshNameplates()
end

function addon.InitializeTankNameplates()
    SetTankNameplates(JJTankMode == true)
end

function addon.ToggleTankNameplates()
    SetTankNameplates(not enabled)
    print("wow-addon: Tank mode " .. (enabled and "on" or "off"))
end
