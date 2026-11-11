local _, addon = ...
local firstAid = {
    id = 129, name = "First Aid", shortName = "First Aid", skillLabel = "First Aid",
    scanCommand = "/jj fascan", catalogName = "JJFirstAidCatalog", characterName = "JJFirstAidCharacter",
    materialChoices = { { "Buy finished inputs", "buy" }, { "Buy raw materials", "raw" } },
}
addon.FirstAid = firstAid
local enabled, window

addon.AttachProfessionCatalog(firstAid)
addon.AttachProfessionProfit(firstAid)
addon.AttachProfessionProfitWindow(firstAid)

function firstAid.UpdateWindow(refreshGold)
    if not window or not window:IsShown() then return end
    if refreshGold ~= false then
        firstAid.UpdateGoldView(window.gold)
    else
        firstAid.UpdateGoldScanStatus(window.gold)
    end
end

function addon.FirstAidCommand()
    if not enabled then
        print("wow-addon: Enable First Aid profit in /jj, then click Reload")
        return
    end
    if not window then
        window = addon.CreateProfessionWindow("JJFirstAidFrame", "First Aid")
        firstAid.CreateGoldView(window)
        window.gold:Show()
        window:SetScript("OnShow", function() firstAid.UpdateWindow() end)
    end
    window:SetShown(not window:IsShown())
end

function addon.FirstAidScanCommand()
    if not enabled then
        print("wow-addon: Enable First Aid profit in /jj, then click Reload")
        return
    end
    firstAid.ScanRecipes()
end

addon.RegisterFeature("firstAid", "First Aid profit", function(value)
    enabled = value
    if not enabled then return end
    addon.AddMinimapButton("firstAid", "First Aid", 3273, 240,
        addon.FirstAidCommand, firstAid.OpenAndScan)
    JJFirstAidCharacter = JJFirstAidCharacter or { learned = {} }
    firstAid.InitializeGold()
    firstAid.InitializeCatalog()
end)
