local _, addon = ...

-- Base coin price per item, without reputation or talent discounts.
-- Forever 1.60.1.70888 ItemSparse: BuyPrice / VendorStackCount, not SellPrice.
-- https://wago.tools/db2/ItemSparse/csv?build=1.60.1.70888
-- Merchant offers: https://github.com/JIVESCORP/eg-link-output-wowf (live and beta).
-- Data from Efficient Games (https://efficient.games), licensed under CC BY 4.0
-- (https://creativecommons.org/licenses/by/4.0/). Selected and converted to unit prices.
-- Additional offers: https://www.wowhead.com/forever/item=4389/gyrochronatom
-- https://www.wowhead.com/forever/item=17194/holiday-spices
-- https://wowseer.gg/items/Holiday_Spirits_17196
-- https://wowdb.wiki/forever/items/snowball
-- Thunder Bluff references: Shadi Mistrunner (8363) and Mahu (3005).
-- Not every item is sold by these suppliers or in Thunder Bluff.
-- Limited stock, faction access, and seasonal availability are not modeled.
addon.VendorPrices = {
    [159] = 5, -- Refreshing Spring Water (25c per 5)
    [785] = 80, -- Mageroyal, limited stock
    [929] = 300, -- Healing Potion, limited stock
    [1179] = 25, -- Ice Cold Milk (125c per 5)
    [1205] = 100, -- Melon Juice (500c per 5)
    [1645] = 400, -- Moonberry Juice (2000c per 5)
    [1708] = 200, -- Sweet Nectar (1000c per 5)
    [2320] = 10, -- Coarse Thread
    [2321] = 100, -- Fine Thread
    [2324] = 25, -- Bleach
    [2325] = 1000, -- Black Dye
    [2447] = 40, -- Peacebloom, limited stock
    [2453] = 100, -- Bruiseweed, limited stock
    [2455] = 40, -- Minor Mana Potion, limited stock
    [2594] = 1500, -- Flagon of Dwarven Honeymead
    [2596] = 120, -- Skin of Dwarven Stout
    [2604] = 50, -- Red Dye
    [2605] = 100, -- Green Dye
    [2678] = 2, -- Mild Spices (10c per 5)
    [2686] = 50, -- Thunder Ale
    [2692] = 40, -- Hot Spices
    [2723] = 50, -- Bottle of Dalaran Noir
    [2880] = 100, -- Weak Flux
    [2894] = 50, -- Rhapsody Malt
    [3030] = 1.5, -- Razor Arrow (300c per 200)
    [3356] = 120, -- Kingsblood, limited stock
    [3357] = 300, -- Liferoot, limited stock
    [3371] = 4, -- Empty Vial (20c per 5)
    [3372] = 40, -- Leaded Vial (200c per 5)
    [3713] = 160, -- Soothing Spices
    [4289] = 50, -- Salt
    [4291] = 500, -- Silken Thread
    [4340] = 350, -- Gray Dye
    [4341] = 500, -- Yellow Dye
    [4342] = 2500, -- Purple Dye
    [4357] = 16, -- Rough Blasting Powder, limited stock
    [4361] = 480, -- Copper Tube, limited stock
    [4363] = 200, -- Copper Modulator, limited stock
    [4364] = 48, -- Coarse Blasting Powder, limited stock
    [4371] = 800, -- Bronze Tube, limited stock
    [4382] = 2400, -- Bronze Framework, limited stock
    [4389] = 3000, -- Gyrochronatom, limited stock
    [4399] = 200, -- Wooden Stock
    [4400] = 2000, -- Heavy Stock
    [4470] = 38, -- Simple Wood
    [4536] = 5, -- Shiny Red Apple (25c per 5)
    [4603] = 80, -- Raw Spotted Yellowtail, limited stock
    [6260] = 50, -- Blue Dye
    [6261] = 1000, -- Orange Dye
    [6289] = 20, -- Raw Longjaw Mud Snapper, limited stock
    [6303] = 20, -- Raw Slitherskin Mackerel, limited stock
    [6308] = 40, -- Raw Bristle Whisker Catfish, limited stock
    [6362] = 80, -- Raw Rockscale Cod, limited stock
    [6530] = 100, -- Nightcrawlers
    [8343] = 2000, -- Heavy Silken Thread
    [8766] = 800, -- Morning Glory Dew (4000c per 5)
    [8925] = 500, -- Crystal Vial (2500c per 5)
    [8959] = 3200, -- Raw Spinefin Halibut, limited stock
    [10284] = 200, -- Simple Flour
    [10290] = 2500, -- Pink Dye
    [10647] = 2000, -- Engineer's Ink
    [10648] = 500, -- Blank Parchment
    [10940] = 800, -- Strange Dust, limited stock
    [11291] = 4500, -- Star Wood
    [14341] = 5000, -- Rune Thread
    [16583] = 10000, -- Demonic Figurine
    [17194] = 2, -- Holiday Spices (10c per 5), Winter Veil
    [17196] = 50, -- Holiday Spirits, Winter Veil
    [17202] = 2, -- Snowball (10c per 5), Winter Veil
    [272941] = 200000, -- Thick Logs
}
