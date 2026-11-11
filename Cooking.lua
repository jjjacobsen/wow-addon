local _, addon = ...
local cooking = {
    id = 185, name = "Cooking", shortName = "Cooking", skillLabel = "Cooking",
    scanCommand = "/jj cookscan", catalogName = "JJCookingCatalog", characterName = "JJCookingCharacter",
    materialChoices = { { "Buy finished inputs", "buy" }, { "Buy raw materials", "raw" } },
}
addon.Cooking = cooking
local enabled, window

addon.AttachProfessionCatalog(cooking)
addon.AttachProfessionTrainer(cooking)
addon.AttachProfessionProfit(cooking)
addon.AttachProfessionProfitWindow(cooking)

function cooking.UpdateWindow(refreshGold)
    if not window or not window:IsShown() then return end
    if refreshGold ~= false then
        cooking.UpdateGoldView(window.gold)
    else
        cooking.UpdateGoldScanStatus(window.gold)
    end
end

function addon.CookingCommand()
    if not enabled then
        print("wow-addon: Enable Cooking profit in /jj, then click Reload")
        return
    end
    if not window then
        window = addon.CreateProfessionWindow("JJCookingFrame", "Cooking")
        cooking.CreateGoldView(window)
        window.gold:Show()
        window:SetScript("OnShow", function() cooking.UpdateWindow() end)
    end
    window:SetShown(not window:IsShown())
end

function addon.CookingScanCommand()
    if not enabled then
        print("wow-addon: Enable Cooking profit in /jj, then click Reload")
        return
    end
    cooking.ScanRecipes()
end

addon.RegisterFeature("cooking", "Cooking profit", function(value)
    enabled = value
    if not enabled then return end
    addon.AddMinimapButton("cooking", "Cooking", 2550, 210,
        addon.CookingCommand, cooking.OpenAndScan)
    JJCookingCharacter = JJCookingCharacter or { learned = {} }
    cooking.InitializeGold()
    cooking.InitializeTrainer()
    cooking.InitializeCatalog()
end)
