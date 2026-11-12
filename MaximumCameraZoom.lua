local _, addon = ...
local distanceCVar = "cameraDistanceMaxZoomFactor"

addon.RegisterFeature("maximumCameraZoom", "Maximum camera zoom", function(enabled)
    if enabled then
        if JJSettings.previousCameraZoomFactor == nil then
            JJSettings.previousCameraZoomFactor = C_CVar.GetCVar(distanceCVar)
        end
        -- Forever 1.60.1.70888: native ControlsOverrides slider maximum
        assert(C_CVar.SetCVar(distanceCVar, "2.0"), "wow-addon: Could not change maximum camera zoom")
    elseif JJSettings.previousCameraZoomFactor ~= nil then
        assert(C_CVar.SetCVar(distanceCVar, JJSettings.previousCameraZoomFactor), "wow-addon: Could not restore maximum camera zoom")
        JJSettings.previousCameraZoomFactor = nil
    end
end, false)
