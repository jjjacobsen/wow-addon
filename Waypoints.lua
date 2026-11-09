local _, addon = ...

local function SetWaypoint(message)
    message = message:match("^%s*(.-)%s*$")
    local first, second = message:match("^([%d%.]+)%s*,%s*([%d%.]+)$")
    if not first then
        first, second = message:match("^([%d%.]+)%s+([%d%.]+)$")
    end
    local x, y = tonumber(first), tonumber(second)
    if not x or not y or x < 0 or x > 100 or y < 0 or y > 100 then
        print("wow-addon: Use /way x y or /way x,y with both coordinates from 0 to 100")
        return
    end
    x, y = x / 100, y / 100
    local mapID = C_Map.GetBestMapForUnit("player")

    if not mapID or not C_Map.CanSetUserWaypointOnMap(mapID) then
        print("wow-addon: Waypoints are unavailable on this map")
        return
    end
    if not C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x, y)) then
        print("wow-addon: Could not set waypoint")
    end
end

addon.RegisterFeature("waypoints", "Waypoints", function(enabled)
    if not enabled then
        return
    end
    SLASH_JJWAYPOINT1 = "/way"
    SlashCmdList.JJWAYPOINT = SetWaypoint
end)
