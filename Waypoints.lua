local _, addon = ...

local function FindZoneMapID(zone)
    local maps = C_Map.GetMapChildrenInfo(C_Map.GetFallbackWorldMapID(), Enum.UIMapType.Zone, true)
    for _, map in ipairs(maps or {}) do
        if strcmputf8i(map.name, zone) == 0 then
            return map.mapID
        end
    end
end

local function SetWaypoint(message)
    local zone, first, separator, second = (" " .. message .. " "):match("^(.-)%s+([%d.]+)([%s,]+)([%d.]+)%s")
    local x, y = tonumber(first), tonumber(second)
    if not x or not y or not separator:match("^%s*,?%s*$") or x < 0 or x > 100 or y < 0 or y > 100 then
        print("wow-addon: Use /way [zone] x y [label] or /way [zone] x,y [label] with coordinates from 0 to 100")
        return
    end

    zone = zone:match("^%s*(.-)%s*$"):gsub("%s+", " ")
    local mapID
    if zone == "" then
        mapID = C_Map.GetBestMapForUnit("player")
    else
        mapID = FindZoneMapID(zone)
        if not mapID then
            print("wow-addon: Unknown zone: " .. zone)
            return
        end
    end

    if not mapID or not C_Map.CanSetUserWaypointOnMap(mapID) then
        print("wow-addon: Waypoints are unavailable on this map")
        return
    end
    if not C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(mapID, x / 100, y / 100)) then
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
