local _, addon = ...
local enabled = false
local hooked = false
local refreshPending = false
local events = CreateFrame("Frame")
local nativeColors = {}

local function ColorTankNameplate(frame, nativeUpdate)
    if frame:IsForbidden() then
        return
    end

    local unit = frame.unit
    if not unit or not unit:match("^nameplate%d+$") or not UnitCanAttack("player", unit) then
        return
    end

    -- Keep Blizzard's result instead of calling its refresh from addon code,
    -- where UnitClass can return a secret key for RAID_CLASS_COLORS
    local color = nativeColors[frame]
    if not color then
        color = {}
        nativeColors[frame] = color
        nativeUpdate = true
    end
    if nativeUpdate then
        color[1], color[2], color[3], color[4] = frame.healthBar:GetStatusBarColor()
    end

    -- Detailed threat values can be secret on nameplates, so use threat state
    if enabled then
        local status = UnitThreatSituation("player", unit)
        if status == 2 or status == 3 then
            frame.healthBar:SetStatusBarColor(0, 0.5, 1)
            return
        end
    end
    frame.healthBar:SetStatusBarColor(unpack(color))
end

local function RefreshNameplates()
    for _, nameplate in ipairs(C_NamePlate.GetNamePlates()) do
        local frame = nameplate.UnitFrame
        if frame and frame.unit then
            ColorTankNameplate(frame)
        end
    end
end

local function RefreshPendingNameplates(self)
    self:SetScript("OnUpdate", nil)
    refreshPending = false
    RefreshNameplates()
end

events:SetScript("OnEvent", function(self, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
        local frame = nameplate and nameplate.UnitFrame
        if frame and frame.unit then
            ColorTankNameplate(frame)
        end
    elseif not refreshPending then
        -- Like native health updates, refresh once before the next frame is drawn
        refreshPending = true
        self:SetScript("OnUpdate", RefreshPendingNameplates)
    end
end)

function addon.IsTankNameplatesEnabled()
    return enabled
end

local function SetTankNameplates(value)
    enabled = value
    JJTankMode = enabled
    if enabled then
        if not hooked then
            hooksecurefunc("CompactUnitFrame_UpdateHealthColor", function(frame)
                if enabled then
                    ColorTankNameplate(frame, true)
                end
            end)
            hooked = true
        end
        events:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        events:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
        events:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
        RefreshNameplates()
    else
        events:UnregisterAllEvents()
        events:SetScript("OnUpdate", nil)
        refreshPending = false
        if hooked then
            RefreshNameplates()
            -- Disabled hooks do not track native changes. Capture fresh colors on enable
            wipe(nativeColors)
        end
    end
end

function addon.InitializeTankNameplates()
    SetTankNameplates(JJTankMode == true)
end

function addon.ToggleTankNameplates()
    SetTankNameplates(not enabled)
    print("wow-addon: Tank mode " .. (enabled and "on" or "off"))
end
