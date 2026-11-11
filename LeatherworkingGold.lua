local _, addon = ...
local lw = addon.Leatherworking

-- Explicit raw materials only. Cured hides expand through native LW recipes.
-- Native item data must also identify each as Tradegoods / Leather (subclass 6).
lw.farmRaw = {
    [2934] = true, -- Ruined Leather Scraps
    [2318] = true, -- Light Leather
    [2319] = true, -- Medium Leather
    [4234] = true, -- Heavy Leather
    [4304] = true, -- Thick Leather
    [8170] = true, -- Rugged Leather
    [15417] = true, -- Devilsaur Leather
    [783] = true, -- Light Hide
    [4232] = true, -- Medium Hide
    [4235] = true, -- Heavy Hide
    [8169] = true, -- Thick Hide
    [8171] = true, -- Rugged Hide
}
lw.saltShaker = true
lw.excludeGear = true
lw.materialChoices = {
    { "Buy finished inputs", "buy" }, { "Buy raw materials", "raw" }, { "Farm leather and hides", "farm" },
}
addon.AttachProfessionProfit(lw)
