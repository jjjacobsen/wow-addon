local _, addon = ...

addon.RegisterFeature("hideBuffCollapseArrow", "Hide buff collapse arrow", function(enabled)
    C_CVar.SetCVar("consolidateBuffs", "0")
    C_CVar.SetCVar("collapseExpandBuffs", enabled and "0" or "1")
end)
