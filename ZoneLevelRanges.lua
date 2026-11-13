local _, addon = ...

-- Forever 1.60.1.70888, checked 2026-11-12
-- UiMap IDs: https://wago.tools/db2/UiMap/csv?build=1.60.1.70888
-- Ranges: https://wago.tools/db2/GroupFinderActivity/csv?build=1.60.1.70888
-- Category 116 (Quests & Zones), MinLevel through MaxLevelSuggestion
-- Native questing suggestions, not quest requirements, exploration levels or scaling
-- Cross-check: https://forevermastery.com/en/guides/wow-forever-zones
-- Keep the source's 53-63 suggestions and Zephras Isle 1-14, not a level-cap clamp
-- No verified suggestions for Deadwind Pass (1430), Moonglade (1450) or Shen'dralas (2652)
local ranges = {
    [1411] = { 1, 14 }, -- Durotar, GroupFinderActivity 874
    [1412] = { 1, 14 }, -- Mulgore, GroupFinderActivity 875
    [1413] = { 8, 30 }, -- The Barrens, GroupFinderActivity 876
    [1416] = { 28, 44 }, -- Alterac Mountains, GroupFinderActivity 873
    [1417] = { 28, 44 }, -- Arathi Highlands, GroupFinderActivity 866
    [1418] = { 33, 50 }, -- Badlands, GroupFinderActivity 865
    [1419] = { 43, 60 }, -- Blasted Lands, GroupFinderActivity 860
    [1420] = { 1, 14 }, -- Tirisfal Glades, GroupFinderActivity 871
    [1421] = { 8, 24 }, -- Silverpine Forest, GroupFinderActivity 872
    [1422] = { 48, 60 }, -- Western Plaguelands, GroupFinderActivity 869
    [1423] = { 53, 63 }, -- Eastern Plaguelands, GroupFinderActivity 870
    [1424] = { 18, 34 }, -- Hillsbrad Foothills, GroupFinderActivity 867
    [1425] = { 38, 54 }, -- The Hinterlands, GroupFinderActivity 868
    [1426] = { 1, 14 }, -- Dun Morogh, GroupFinderActivity 856
    [1427] = { 43, 60 }, -- Searing Gorge, GroupFinderActivity 864
    [1428] = { 48, 60 }, -- Burning Steppes, GroupFinderActivity 863
    [1429] = { 1, 14 }, -- Elwynn Forest, GroupFinderActivity 853
    [1431] = { 18, 34 }, -- Duskwood, GroupFinderActivity 855
    [1432] = { 8, 24 }, -- Loch Modan, GroupFinderActivity 857
    [1433] = { 13, 30 }, -- Redridge Mountains, GroupFinderActivity 862
    [1434] = { 28, 50 }, -- Stranglethorn Vale, GroupFinderActivity 859
    [1435] = { 33, 50 }, -- Swamp of Sorrows, GroupFinderActivity 861
    [1436] = { 8, 24 }, -- Westfall, GroupFinderActivity 854
    [1437] = { 18, 34 }, -- Wetlands, GroupFinderActivity 858
    [1438] = { 1, 14 }, -- Teldrassil, GroupFinderActivity 885
    [1439] = { 8, 24 }, -- Darkshore, GroupFinderActivity 886
    [1440] = { 18, 34 }, -- Ashenvale, GroupFinderActivity 887
    [1441] = { 23, 40 }, -- Thousand Needles, GroupFinderActivity 878
    [1442] = { 13, 32 }, -- Stonetalon Mountains, GroupFinderActivity 877
    [1443] = { 28, 44 }, -- Desolace, GroupFinderActivity 879
    [1444] = { 38, 54 }, -- Feralas, GroupFinderActivity 880
    [1445] = { 33, 50 }, -- Dustwallow Marsh, GroupFinderActivity 881
    [1446] = { 38, 54 }, -- Tanaris, GroupFinderActivity 882
    [1447] = { 43, 60 }, -- Azshara, GroupFinderActivity 889
    [1448] = { 46, 60 }, -- Felwood, GroupFinderActivity 888
    [1449] = { 45, 60 }, -- Un'Goro Crater, GroupFinderActivity 883
    [1451] = { 53, 60 }, -- Silithus, GroupFinderActivity 884
    [1452] = { 53, 63 }, -- Winterspring, GroupFinderActivity 890
    [2482] = { 55, 60 }, -- Mount Hyjal, GroupFinderActivity 1991
    [2521] = { 1, 14 }, -- Zephras Isle, GroupFinderActivity 1990
    [2548] = { 33, 54 }, -- Riverglades, GroupFinderActivity 1989
}

addon.RegisterFeature("zoneLevelRanges", "Zone level ranges", function(enabled)
    if not enabled then
        return
    end

    EventUtil.ContinueOnAddOnLoaded("Blizzard_WorldMap", function()
        local map = WorldMapFrame
        local navBar = map.NavBar
        local label = navBar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("RIGHT", navBar, "RIGHT", -12, 0)

        local function Update()
            local range = ranges[map:GetMapID()]
            if not map:IsShown() or not range then
                label:Hide()
                return
            end

            label:SetFormattedText("%d-%d", range[1], range[2])
            local lastButton = NavBar_GetButton(navBar, NavBar_GetNumButtons(navBar))
            label:SetShown(lastButton:GetRight() + 24 < label:GetLeft())
        end

        hooksecurefunc(map, "OnMapChanged", Update)
        map:HookScript("OnShow", Update)
        navBar:HookScript("OnSizeChanged", Update)
        Update()
    end)
end)
