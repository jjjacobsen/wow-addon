local _, addon = ...
local alchemy = {
    id = 171, name = "Alchemy", shortName = "Alchemy", skillLabel = "Alchemy",
    scanCommand = "/jj alchscan", catalogName = "JJAlchemyCatalog", characterName = "JJAlchemyCharacter",
    materialChoices = { { "Buy finished inputs", "buy" }, { "Buy raw materials", "raw" } },
}
addon.Alchemy = alchemy
local enabled, window

addon.AttachProfessionCatalog(alchemy)
addon.AttachProfessionProfit(alchemy)
addon.AttachProfessionProfitWindow(alchemy)

function alchemy.UpdateWindow(refreshGold)
    if not window or not window:IsShown() then return end
    if refreshGold ~= false then
        alchemy.UpdateGoldView(window.gold)
    else
        alchemy.UpdateGoldScanStatus(window.gold)
    end
end

function addon.AlchemyCommand()
    if not enabled then
        print("wow-addon: Enable Alchemy profit in /jj, then click Reload")
        return
    end
    if not window then
        window = addon.CreateProfessionWindow("JJAlchemyFrame", "Alchemy")
        alchemy.CreateGoldView(window)
        window.gold:Show()
        window:SetScript("OnShow", function() alchemy.UpdateWindow() end)
    end
    window:SetShown(not window:IsShown())
end

function addon.AlchemyScanCommand()
    if not enabled then
        print("wow-addon: Enable Alchemy profit in /jj, then click Reload")
        return
    end
    alchemy.ScanRecipes()
end

addon.RegisterFeature("alchemy", "Alchemy profit", function(value)
    enabled = value
    if not enabled then return end
    addon.AddMinimapButton("alchemy", "Alchemy", 2259, 270,
        addon.AlchemyCommand, alchemy.OpenAndScan)
    JJAlchemyCharacter = JJAlchemyCharacter or { learned = {} }
    alchemy.InitializeGold()
    alchemy.InitializeCatalog()
end)
