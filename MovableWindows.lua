local _, addon = ...
local enabled
local windows, positions = {}, {}
local events = CreateFrame("Frame")
local nativePanels = {
    "AuctionHouseFrame", "CharacterFrame", "PlayerSpellsFrame", "ProfessionsFrame",
    "ProfessionsBookFrame", "BankFrame", "MerchantFrame", "TradeFrame", "MailFrame",
    "QuestFrame", "GossipFrame", "DressUpFrame", "FriendsFrame",
}

local function PositionKey(frame, kind)
    -- Individual container frames are reused for different bags.
    if kind == "bag" and frame ~= ContainerFrameCombinedBags then
        return frame:GetBagID()
    end
    return frame
end

local function RestorePosition(frame, entry)
    local point = positions[PositionKey(frame, entry.kind)]
    if point and not entry.dragging then
        frame:ClearAllPoints()
        frame:SetPoint(unpack(point, 1, 5))
    end
end

local function RestorePositions()
    if InCombatLockdown() then return end
    for frame, entry in pairs(windows) do
        if frame:IsShown() then
            RestorePosition(frame, entry)
        end
    end
end

local function StopDragging(frame, entry)
    if not entry.dragging or InCombatLockdown() then return end
    frame:StopMovingOrSizing()
    entry.dragging = nil
    positions[PositionKey(frame, entry.kind)] = { frame:GetPoint(1) }
    frame:SetUserPlaced(false)
end

local function ManageWindow(frame, kind)
    if not enabled or windows[frame] then return end
    local entry = { kind = kind }
    windows[frame] = entry
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:SetDontSavePosition(true)
    if kind == "addon" then
        -- Existing addon windows dragged from their whole background.
        frame:RegisterForDrag()
    end

    local title = CreateFrame("Frame", nil, frame)
    title:SetPoint("TOPLEFT", kind == "addon" and 8 or 60, -2)
    title:SetPoint("TOPRIGHT", kind == "addon" and -34 or -78, -2)
    title:SetHeight(24)
    title:SetFrameLevel(frame:GetFrameLevel() + 10)
    title:EnableMouse(true)
    title:RegisterForDrag("LeftButton")
    title:SetScript("OnDragStart", function()
        if InCombatLockdown() then
            print("wow-addon: Cannot move windows in combat")
            return
        end
        entry.dragging = true
        frame:Raise()
        frame:StartMoving()
    end)
    title:SetScript("OnDragStop", function()
        StopDragging(frame, entry)
    end)
    frame:HookScript("OnShow", function()
        if InCombatLockdown() then return end
        RestorePosition(frame, entry)
        frame:Raise()
    end)
end

function addon.ManageWindow(frame)
    ManageWindow(frame, "addon")
end

local function FindNativeWindows()
    if InCombatLockdown() then return end
    for _, name in ipairs(nativePanels) do
        local frame = _G[name]
        if frame then ManageWindow(frame, "panel") end
    end
    if ContainerFrameCombinedBags then
        ManageWindow(ContainerFrameCombinedBags, "bag")
        for index = 1, NUM_CONTAINER_FRAMES do
            ManageWindow(_G["ContainerFrame" .. index], "bag")
        end
    end
end

function addon.ResetWindowPositions()
    if InCombatLockdown() then
        print("wow-addon: Cannot reset windows in combat. Try /jj resetwindows after combat")
        return
    end
    if not enabled then
        print("wow-addon: Enable Movable windows in /jj and reload first")
        return
    end
    FindNativeWindows()
    wipe(positions)
    for frame, entry in pairs(windows) do
        if entry.dragging then
            frame:StopMovingOrSizing()
            entry.dragging = nil
        end
        frame:SetUserPlaced(false)
        if entry.kind == "addon" then
            frame:ClearAllPoints()
            frame:SetPoint("CENTER", UIParent, "CENTER")
        end
    end
    -- Keep native panel occupancy, Escape handling, and layout attributes intact.
    -- Hidden native windows receive their default anchors the next time they open.
    UpdateUIPanelPositions()
    UpdateContainerFrameAnchors()
    print("wow-addon: Window positions reset")
end

addon.RegisterFeature("movableWindows", "Movable windows", function(value)
    enabled = value
    if not enabled then return end
    FindNativeWindows()
    events:RegisterEvent("ADDON_LOADED")
    events:RegisterEvent("PLAYER_LOGIN")
    events:RegisterEvent("PLAYER_REGEN_ENABLED")
    events:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            for frame, entry in pairs(windows) do
                StopDragging(frame, entry)
            end
        end
        FindNativeWindows()
    end)
    -- Native layout ignores SetUserPlaced and reanchors panels and bags on open.
    hooksecurefunc("UpdateUIPanelPositions", RestorePositions)
    hooksecurefunc("UpdateContainerFrameAnchors", RestorePositions)
end)
