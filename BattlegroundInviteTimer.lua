local _, addon = ...

local function GetInviteSeconds(dialog)
    local slot = dialog.activeIndex
    if issecretvalue(slot) or not slot then
        return
    end

    local status = GetBattlefieldStatus(slot)
    if issecretvalue(status) or status ~= "confirm" then
        return
    end

    local seconds = GetBattlefieldPortExpiration(slot)
    if not issecretvalue(seconds) and seconds and seconds > 0 then
        return math.ceil(seconds)
    end
end

addon.RegisterFeature("battlegroundInviteTimer", "Battleground invite timer", function(enabled)
    if not enabled then
        return
    end

    local dialog = PVPReadyDialog
    local timer = CreateFrame("Frame", nil, dialog)
    timer:SetAllPoints()
    local text = timer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("BOTTOM", 0, 9)

    local elapsed = 0
    local function Refresh()
        elapsed = 0
        local seconds = GetInviteSeconds(dialog)
        text:SetText(seconds and SECOND_ONELETTER_ABBR:format(seconds) or "")
    end

    timer:SetScript("OnShow", Refresh)
    timer:SetScript("OnHide", function()
        text:SetText("")
    end)
    timer:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed >= 0.1 then
            Refresh()
        end
    end)
    if timer:IsVisible() then
        Refresh()
    end
end)
