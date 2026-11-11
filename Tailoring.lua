local _, addon = ...
local tailoring = {
    id = 197, name = "Tailoring", shortName = "Tailor", skillLabel = "Tailor skill",
    scanCommand = "/jj tailorscan", catalogName = "JJTailoringCatalog", characterName = "JJTailoringCharacter",
    materialChoices = { { "Buy finished inputs", "buy" }, { "Buy raw materials", "raw" } },
    excludeGear = true,
}
addon.Tailoring = tailoring
local enabled, window

addon.AttachProfessionCatalog(tailoring)
addon.AttachProfessionTrainer(tailoring)
addon.AttachProfessionProfit(tailoring)
addon.AttachProfessionProfitWindow(tailoring)

function tailoring.UpdateWindow(refreshGold)
    if not window or not window:IsShown() then return end
    if refreshGold ~= false then
        tailoring.UpdateGoldView(window.gold)
    else
        tailoring.UpdateGoldScanStatus(window.gold)
    end
end

function addon.TailoringCommand()
    if not enabled then
        print("wow-addon: Enable Tailoring profit in /jj, then click Reload")
        return
    end
    if not window then
        window = addon.CreateProfessionWindow("JJTailoringFrame", "Tailoring")
        tailoring.CreateGoldView(window)
        window.gold:Show()
        window:SetScript("OnShow", function() tailoring.UpdateWindow() end)
    end
    window:SetShown(not window:IsShown())
end

function addon.TailoringScanCommand()
    if not enabled then
        print("wow-addon: Enable Tailoring profit in /jj, then click Reload")
        return
    end
    tailoring.ScanRecipes()
end

addon.RegisterFeature("tailoring", "Tailoring profit", function(value)
    enabled = value
    if not enabled then return end
    addon.AddMinimapButton("tailoring", "Tailoring", 3908, 120,
        addon.TailoringCommand, tailoring.OpenAndScan)
    JJTailoringCharacter = JJTailoringCharacter or { learned = {} }
    tailoring.InitializeGold()
    tailoring.InitializeTrainer()
    tailoring.InitializeCatalog()
end)
