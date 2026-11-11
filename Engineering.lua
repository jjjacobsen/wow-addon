local _, addon = ...
local engineering = {
    id = 202, name = "Engineering", shortName = "Eng", skillLabel = "Eng skill",
    scanCommand = "/jj engscan", catalogName = "JJEngineeringCatalog", characterName = "JJEngineeringCharacter",
    materialChoices = { { "Buy finished inputs", "buy" }, { "Buy raw materials", "raw" } },
    excludeGear = true,
}
addon.Engineering = engineering
local enabled, window

addon.AttachProfessionCatalog(engineering)
addon.AttachProfessionProfit(engineering)
addon.AttachProfessionProfitWindow(engineering)

function engineering.UpdateWindow(refreshGold)
    if not window or not window:IsShown() then return end
    if refreshGold ~= false then
        engineering.UpdateGoldView(window.gold)
    else
        engineering.UpdateGoldScanStatus(window.gold)
    end
end

function addon.EngineeringCommand()
    if not enabled then
        print("wow-addon: Enable Engineering profit in /jj, then click Reload")
        return
    end
    if not window then
        window = addon.CreateProfessionWindow("JJEngineeringFrame", "Engineering")
        engineering.CreateGoldView(window)
        window.gold:Show()
        window:SetScript("OnShow", function() engineering.UpdateWindow() end)
    end
    window:SetShown(not window:IsShown())
end

function addon.EngineeringScanCommand()
    if not enabled then
        print("wow-addon: Enable Engineering profit in /jj, then click Reload")
        return
    end
    engineering.ScanRecipes()
end

addon.RegisterFeature("engineering", "Engineering profit", function(value)
    enabled = value
    if not enabled then return end
    addon.AddMinimapButton("engineering", "Engineering", 4036, 150,
        addon.EngineeringCommand, engineering.OpenAndScan)
    JJEngineeringCharacter = JJEngineeringCharacter or { learned = {} }
    engineering.InitializeGold()
    engineering.InitializeCatalog()
end)
