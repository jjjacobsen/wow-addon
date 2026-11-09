local _, addon = ...
local events = CreateFrame("Frame")
local routes = {}
local flight, ticker

local function StopRecording()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
    flight = nil
end

local function ObserveFlight()
    if not flight then
        return
    end
    local now = GetTime()
    if UnitOnTaxi("player") then
        flight.started = flight.started or now
    elseif flight.started then
        JJFlightDurations[flight.route] = now - flight.started
        StopRecording()
    elseif now - flight.requested > 5 then
        StopRecording()
    end
end

local function ReadRoutes()
    routes = {}
    local mapID = GetTaxiMapID()
    local nodeIDs = {}
    for _, node in ipairs(C_TaxiMap.GetAllTaxiNodes(mapID)) do
        nodeIDs[node.slotIndex] = node.nodeID
    end

    local origin
    for slot = 1, NumTaxiNodes() do
        if TaxiNodeGetType(slot) == "CURRENT" then
            origin = slot
            break
        end
    end
    if not origin or not nodeIDs[origin] then
        return
    end

    local prefix = table.concat({ GetCurrentRegion(), UnitFactionGroup("player"), mapID }, ":")
    for slot = 1, NumTaxiNodes() do
        if TaxiNodeGetType(slot) == "REACHABLE" then
            local path = { nodeIDs[origin] }
            local previous = origin
            local complete = true
            for hop = 1, GetNumRoutes(slot) do
                local source = TaxiGetNodeSlot(slot, hop, true)
                local destination = TaxiGetNodeSlot(slot, hop, false)
                if source ~= previous or not nodeIDs[destination] then
                    complete = false
                    break
                end
                path[#path + 1] = nodeIDs[destination]
                previous = destination
            end
            -- Never merge unresolved paths or use map-local slots as saved IDs
            if complete and previous == slot and #path > 1 then
                routes[slot] = prefix .. ":" .. table.concat(path, ">")
            end
        end
    end
end

addon.RegisterFeature("flightDurations", "Flight durations", function(enabled)
    if not enabled then
        return
    end
    JJFlightDurations = JJFlightDurations or {}

    hooksecurefunc("TaxiNodeOnButtonEnter", function(button)
        local slot = button:GetID()
        if TaxiNodeGetType(slot) ~= "REACHABLE" then
            return
        end
        local seconds = JJFlightDurations[routes[slot]]
        local duration = "Unknown"
        if seconds then
            seconds = math.floor(seconds + 0.5)
            duration = string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
        end
        GameTooltip:AddDoubleLine("Duration", duration, 1, 1, 1, 1, 1, 1)
        GameTooltip:Show()
    end)

    hooksecurefunc("TakeTaxiNode", function(slot)
        -- The native call can close the map, so capture all paths at map open
        local route = routes[slot]
        routes = {}
        if flight or not route then
            return
        end
        flight = { route = route, requested = GetTime() }
        ticker = C_Timer.NewTicker(0.1, ObserveFlight)
        ObserveFlight()
    end)

    -- Both native leave controls call this global, before the shortened landing
    hooksecurefunc("TaxiRequestEarlyLanding", StopRecording)

    events:RegisterEvent("TAXIMAP_OPENED")
    events:RegisterEvent("PLAYER_CONTROL_LOST")
    events:RegisterEvent("PLAYER_CONTROL_GAINED")
    events:RegisterEvent("PLAYER_LEAVING_WORLD")
    events:RegisterEvent("PLAYER_LOGOUT")
    events:RegisterEvent("PLAYER_DEAD")
    events:SetScript("OnEvent", function(_, event)
        if event == "TAXIMAP_OPENED" then
            ReadRoutes()
        elseif event == "PLAYER_CONTROL_LOST" or event == "PLAYER_CONTROL_GAINED" then
            ObserveFlight()
        else
            -- Loading screens, logout/reload, and death cannot teach a partial flight
            StopRecording()
            routes = {}
        end
    end)
end)
