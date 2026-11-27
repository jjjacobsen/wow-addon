local _, addon = ...

local function IsLivePlayer(unit)
    return UnitIsHumanPlayer(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit)
end

local function IsEnemyPlayer(unit)
    return IsLivePlayer(unit) and UnitCanAttack("player", unit)
end

local function SameUnit(first, second)
    if C_Secrets.CanCompareUnitTokens(first, second) then
        local same = UnitIsUnit(first, second)
        if not issecretvalue(same) then
            return same
        end
    end
end

local function TargetInRange()
    -- Interact checks are blocked in combat. Forever also exposes native swing range
    if not InCombatLockdown() and CheckInteractDistance("target", 4) then
        return true
    end
    local melee = C_SwingTimer.IsTargetWithinSwingRange(Enum.PlayerSwingType.MainHand)
    local ranged = C_SwingTimer.IsTargetWithinSwingRange(Enum.PlayerSwingType.Ranged)
    return (not issecretvalue(melee) and melee) or (not issecretvalue(ranged) and ranged)
end

local function PlateUnit(plate)
    if not plate:IsForbidden() then
        local unit = plate:GetUnit()
        if not issecretvalue(unit) then
            return unit
        end
    end
end

local function TargetsPlayerInCombat(unit)
    return UnitAffectingCombat(unit) and SameUnit(unit .. "target", "player")
end

local function HasNearbyHostileTargetingPlayer()
    if IsEnemyPlayer("target") and TargetsPlayerInCombat("target") and TargetInRange() then
        return true
    end
    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local unit = PlateUnit(plate)
        if unit and IsEnemyPlayer(unit) and TargetsPlayerInCombat(unit) then
            return true
        end
    end
end

local function CountNearbyPlayers()
    local allies = IsLivePlayer("player") and 1 or 0
    local enemies = 0
    local ownPlate = C_NamePlate.GetNamePlateForUnit("player")
    local targetPlate = C_NamePlate.GetNamePlateForUnit("target")
    local countedTarget = false
    local friendlyPlates = {}

    for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
        local unit = PlateUnit(plate)
        if unit and plate ~= ownPlate and IsLivePlayer(unit) then
            if UnitCanAttack("player", unit) then
                enemies = enemies + 1
                countedTarget = countedTarget or plate == targetPlate
            elseif UnitIsFriend("player", unit) then
                allies = allies + 1
                friendlyPlates[plate] = true
            end
        end
    end

    local raid = IsInRaid()
    local prefix = raid and "raid" or "party"
    for i = 1, raid and GetNumGroupMembers() or GetNumSubgroupMembers() do
        local unit = prefix .. i
        if IsLivePlayer(unit) and not UnitCanAttack("player", unit) and (not raid or SameUnit(unit, "player") == false) then
            local inRange, checkedRange = UnitInRange(unit)
            if not issecretvalue(inRange) and not issecretvalue(checkedRange) and inRange and checkedRange
                and not friendlyPlates[C_NamePlate.GetNamePlateForUnit(unit)] then
                allies = allies + 1
            end
        end
    end

    if not countedTarget and IsEnemyPlayer("target") and TargetInRange() then
        enemies = enemies + 1
    end
    return allies, enemies
end

-- UNIT_COMBAT identifies the recipient, not the source
local attacks = { WOUND = true, MISS = true, DODGE = true, PARRY = true, BLOCK = true,
    RESIST = true, IMMUNE = true, ABSORB = true, DEFLECT = true, REFLECT = true }

addon.RegisterFeature("pvpBalance", "PvP balance", function(enabled)
    if not enabled then
        return
    end

    local frame = CreateFrame("Frame", nil, UIParent)
    frame:SetSize(80, 24)
    local position = JJSettings.pvpBalancePosition or { "CENTER", "CENTER", 0, -145 }
    frame:SetPoint(position[1], UIParent, position[2], position[3], position[4])
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("RightButton")
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
        self.dragging = true
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        self.dragging = nil
        local point, _, relativePoint, x, y = self:GetPoint()
        JJSettings.pvpBalancePosition = { point, relativePoint, x, y }
    end)
    frame:Hide()

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("CENTER")

    local match, world
    local contactUntil = 0
    local pendingCast

    local function Update()
        local worldCombat = GetTime() < contactUntil and UnitAffectingCombat("player") and IsLivePlayer("player")
        if not match and (not world or not (worldCombat or frame.dragging)) then
            frame:Hide()
            return
        end

        local allies, enemies = CountNearbyPlayers()
        label:SetFormattedText("%d v %d", allies, enemies)
        frame:SetShown(match or frame.dragging == true or enemies > 0)
    end

    local elapsed = 0
    local function OnUpdate(_, delta)
        elapsed = elapsed + delta
        if elapsed >= 0.25 then
            elapsed = 0
            Update()
        end
    end

    local events = CreateFrame("Frame")
    events:RegisterEvent("PLAYER_ENTERING_WORLD")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:RegisterEvent("DUEL_FINISHED")
    events:RegisterEvent("PLAYER_SWING")
    events:RegisterUnitEvent("UNIT_COMBAT", "player")
    events:RegisterUnitEvent("UNIT_SPELLCAST_SENT", "player")
    events:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    events:SetScript("OnEvent", function(self, event, _, value, castGUID, spellID)
        if event == "PLAYER_ENTERING_WORLD" then
            local _, instanceType = IsInInstance()
            match = instanceType == "pvp" or instanceType == "arena"
            world = instanceType == "none"
            contactUntil, pendingCast = 0, nil
            self:SetScript("OnUpdate", (match or world) and OnUpdate or nil)
            Update()
        elseif world then
            if event == "PLAYER_REGEN_ENABLED" or event == "DUEL_FINISHED" then
                contactUntil, pendingCast = 0, nil
                Update()
            elseif event == "UNIT_SPELLCAST_SENT" then
                pendingCast = nil
                if not issecretvalue(value) and not issecretvalue(castGUID) and not issecretvalue(spellID)
                    and IsEnemyPlayer("target") and C_Spell.IsSpellHarmful(spellID) then
                    local name = UnitName("target")
                    if not issecretvalue(name) and name == value then
                        pendingCast = castGUID
                    end
                end
            elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
                if pendingCast and not issecretvalue(value) and pendingCast == value then
                    pendingCast = nil
                    contactUntil = GetTime() + 5
                end
            elseif (event == "PLAYER_SWING" and IsEnemyPlayer("target")) or
                (event == "UNIT_COMBAT" and not issecretvalue(value) and attacks[value] and HasNearbyHostileTargetingPlayer()) then
                contactUntil = GetTime() + 5
            end
        end
    end)
end, false)
