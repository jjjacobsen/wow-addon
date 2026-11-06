local _, addon = ...
local enabledCVar = "damageMeterEnabled"
local events = CreateFrame("Frame")

function addon.IsDamageMeterEnabled()
    return C_CVar.GetCVarBool(enabledCVar)
end

local function SaveDamageMeter()
    JJDamageMeterEnabled = addon.IsDamageMeterEnabled()
end

local function SetDamageMeter(enabled)
    if not C_CVar.SetCVar(enabledCVar, enabled and "1" or "0") then
        print("wow-addon: Could not change Enable Damage Meter")
        return false
    end
    SaveDamageMeter()
    return true
end

function addon.InitializeDamageMeter()
    if JJDamageMeterEnabled == nil then
        SaveDamageMeter()
    elseif JJDamageMeterEnabled ~= addon.IsDamageMeterEnabled() then
        SetDamageMeter(JJDamageMeterEnabled)
    end
    events:RegisterEvent("CVAR_UPDATE")
end

function addon.ToggleDamageMeter()
    if SetDamageMeter(not addon.IsDamageMeterEnabled()) then
        print("wow-addon: Damage meter " .. (addon.IsDamageMeterEnabled() and "on" or "off"))
    end
end

events:SetScript("OnEvent", function(_, _, name)
    if name:lower() == enabledCVar:lower() then
        SaveDamageMeter()
    end
end)
