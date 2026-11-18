local _, addon = ...

-- Forever only, checked 2026-11-17. Each option is a complete alternative, never additive.
-- Crate IDs, material IDs and quantities: https://wowhandbook.com/professions/merchants-favor/
-- Checked all 30 crate tooltips and all 96 material names against
-- https://nether.wowhead.com/forever/tooltip/item/<itemID>
-- Artisan Fabrics uses Stock Crate 1247455. Its two quantities also match SpellEffect
-- in builds 1.60.1.70888 and 1.60.1.70938: https://wago.tools/db2/SpellEffect
-- Reported base Favor (currency 3402), not the separate Shipping Label or Legacy bonus:
-- https://www.zockify.com/forever/waylaid-crates/
-- https://www.wowhead.com/forever/guide/durotar-supply-and-logistics-reputation-professions
-- Favor rechecked 2026-11-18. Artisan common/uncommon: 20/40, reported in-game
-- by the Waylaid Auction Helper author in release 1.2.2, Favor.lua:
-- https://www.curseforge.com/wow/addons/waylaid-auction-helper/files/9598817
-- Elite and rare payouts remain unverified. Missing favor means unknown.
-- Sealed IDs/qualities checked against the same Forever item tooltip endpoint.

addon.WaylaidCratesData = {
    [248549] = { unlabeled = true }, -- Waylaid Crate: Read Label, not yet a material request
    [248682] = { favor = 5, -- Waylaid Crate: Apprentice Herbs
        options = {
            { 2447, 20, "Peacebloom" },
            { 765, 20, "Silverleaf" },
            { 2449, 10, "Earthroot" },
            { 785, 10, "Mageroyal" },
            { 2450, 10, "Briarthorn" },
        },
    },
    [248683] = { favor = 5, -- Waylaid Crate: Apprentice Ore
        options = {
            { 2770, 20, "Copper Ore" },
            { 2771, 20, "Tin Ore" },
        },
    },
    [248684] = { favor = 5, -- Waylaid Crate: Apprentice Textiles
        options = {
            { 2589, 40, "Linen Cloth" },
            { 2318, 20, "Light Leather" },
        },
    },
    [248685] = { favor = 5, -- Waylaid Crate: Apprentice Curiosities
        options = {
            { 10940, 20, "Strange Dust" },
            { 10939, 4, "Greater Magic Essence" },
            { 10978, 6, "Small Glimmering Shard" },
            { 11084, 2, "Large Glimmering Shard" },
        },
    },
    [248686] = { favor = 10, -- Waylaid Crate: Journeyman Herbs
        options = {
            { 3820, 10, "Stranglekelp" },
            { 2453, 10, "Bruiseweed" },
            { 3355, 10, "Wild Steelbloom" },
            { 3369, 10, "Grave Moss" },
            { 3356, 10, "Kingsblood" },
        },
    },
    [248687] = { favor = 10, -- Waylaid Crate: Journeyman Ore
        options = {
            { 2775, 10, "Silver Ore" },
            { 2772, 20, "Iron Ore" },
        },
    },
    [248688] = { favor = 10, -- Waylaid Crate: Journeyman Textiles
        options = {
            { 2592, 20, "Wool Cloth" },
            { 4306, 40, "Silk Cloth" },
            { 2319, 20, "Medium Leather" },
        },
    },
    [248689] = { favor = 10, -- Waylaid Crate: Journeyman Curiosities
        options = {
            { 11083, 20, "Soul Dust" },
            { 11082, 4, "Greater Astral Essence" },
            { 11138, 6, "Small Glowing Shard" },
            { 11139, 2, "Large Glowing Shard" },
        },
    },
    [248690] = { favor = 15, -- Waylaid Crate: Earthly Expert Herbs
        options = {
            { 3357, 20, "Liferoot" },
            { 3818, 10, "Fadeleaf" },
            { 3821, 10, "Goldthorn" },
            { 3358, 10, "Khadgar's Whisker" },
        },
    },
    [248691] = { favor = 15, -- Waylaid Crate: Flowering Expert Herbs
        options = {
            { 3819, 10, "Wintersbite" },
            { 4625, 10, "Firebloom" },
            { 8831, 20, "Purple Lotus" },
            { 8836, 10, "Arthas' Tears" },
        },
    },
    [248692] = { favor = 15, -- Waylaid Crate: Expert Ore
        options = {
            { 2776, 10, "Gold Ore" },
            { 3858, 20, "Mithril Ore" },
        },
    },
    [248693] = { favor = 15, -- Waylaid Crate: Expert Textiles
        options = {
            { 4338, 40, "Mageweave Cloth" },
            { 4234, 20, "Heavy Leather" },
        },
    },
    [248694] = { favor = 15, -- Waylaid Crate: Expert Curiosities
        options = {
            { 11137, 20, "Vision Dust" },
            { 11135, 4, "Greater Mystic Essence" },
            { 11177, 6, "Small Radiant Shard" },
            { 11178, 2, "Large Radiant Shard" },
        },
    },
    [248695] = { favor = 20, -- Waylaid Crate: Earthly Artisan Herbs
        options = {
            { 13464, 10, "Golden Sansam" },
            { 8838, 20, "Sungrass" },
            { 8839, 10, "Blindweed" },
            { 8845, 10, "Ghost Mushroom" },
            { 8846, 10, "Gromsblood" },
        },
    },
    [248696] = { favor = 20, -- Waylaid Crate: Flowering Artisan Herbs
        options = {
            { 13463, 20, "Dreamfoil" },
            { 13465, 20, "Mountain Silversage" },
            { 13466, 20, "Plaguebloom" },
            { 13467, 20, "Icecap" },
        },
    },
    [248697] = { favor = 20, -- Waylaid Crate: Artisan Ore
        options = {
            { 7911, 10, "Truesilver Ore" },
            { 10620, 20, "Thorium Ore" },
            { 11370, 20, "Dark Iron Ore" },
        },
    },
    [248698] = { favor = 20, -- Waylaid Crate: Artisan Textiles
        options = {
            { 14047, 40, "Runecloth" },
            { 4304, 20, "Thick Leather" },
            { 8170, 20, "Rugged Leather" },
        },
    },
    [248699] = { favor = 20, -- Waylaid Crate: Artisan Curiosities
        options = {
            { 11176, 20, "Dream Dust" },
            { 11175, 4, "Greater Nether Essence" },
            { 14343, 6, "Small Brilliant Shard" },
            { 14344, 2, "Large Brilliant Shard" },
        },
    },
    [248702] = { favor = 10, -- Waylaid Crate: Apprentice Fabrics
        options = {
            { 4231, 2, "Cured Light Hide" },
            { 2996, 20, "Bolt of Linen Cloth" },
        },
    },
    [248703] = { favor = 10, -- Waylaid Crate: Apprentice Ingots
        options = {
            { 2840, 20, "Copper Bar" },
            { 3576, 20, "Tin Bar" },
            { 2841, 10, "Bronze Bar" },
        },
    },
    [248704] = { favor = 10, -- Waylaid Crate: Apprentice Parts
        options = {
            { 4359, 16, "Handful of Copper Bolts" },
            { 4361, 16, "Copper Tube" },
            { 4363, 4, "Copper Modulator" },
        },
    },
    [248705] = { favor = 20, -- Waylaid Crate: Journeyman Fabrics
        options = {
            { 2997, 6, "Bolt of Woolen Cloth" },
            { 4305, 10, "Bolt of Silk Cloth" },
            { 4233, 2, "Cured Medium Hide" },
        },
    },
    [248706] = { favor = 20, -- Waylaid Crate: Journeyman Ingots
        options = {
            { 2842, 10, "Silver Bar" },
            { 3575, 20, "Iron Bar" },
        },
    },
    [248707] = { favor = 20, -- Waylaid Crate: Journeyman Parts
        options = {
            { 4371, 8, "Bronze Tube" },
            { 4375, 7, "Whirring Bronze Gizmo" },
            { 4382, 4, "Bronze Framework" },
            { 10558, 45, "Gold Power Core" },
        },
    },
    [248708] = { favor = 30, -- Waylaid Crate: Expert Fabrics
        options = {
            { 4339, 8, "Bolt of Mageweave" },
            { 4236, 2, "Cured Heavy Hide" },
        },
    },
    [248709] = { favor = 30, -- Waylaid Crate: Expert Ingots
        options = {
            { 3860, 20, "Mithril Bar" },
            { 3859, 15, "Steel Bar" },
            { 3577, 10, "Gold Bar" },
        },
    },
    [248710] = { favor = 30, -- Waylaid Crate: Expert Parts
        options = {
            { 4387, 8, "Iron Strut" },
            { 10559, 5, "Mithril Tube" },
            { 10560, 12, "Unstable Trigger" },
            { 10561, 5, "Mithril Casing" },
        },
    },
    [248711] = { favor = 40, -- Waylaid Crate: Artisan Fabrics
        options = {
            { 14048, 8, "Bolt of Runecloth" },
            { 8172, 2, "Cured Thick Hide" },
        },
    },
    [248712] = { favor = 40, -- Waylaid Crate: Artisan Ingots
        options = {
            { 11371, 2, "Dark Iron Bar" },
            { 6037, 10, "Truesilver Bar" },
            { 12359, 20, "Thorium Bar" },
        },
    },
    [248713] = { favor = 40, -- Waylaid Crate: Artisan Parts
        options = {
            { 15994, 5, "Thorium Widget" },
            { 18631, 5, "Truesilver Transformer" },
            { 16000, 2, "Thorium Tube" },
        },
    },
    [248765] = { favor = 5 }, -- Sealed Apprentice Crate, common
    [248766] = { favor = 10 }, -- Sealed Journeyman Crate, common
    [248767] = { favor = 15 }, -- Sealed Expert Crate, common
    [248768] = { favor = 20 }, -- Sealed Artisan Crate, common
    [248769] = {}, -- Sealed Elite Crate, common
    [248770] = { favor = 10 }, -- Sealed Apprentice Crate, uncommon
    [248771] = { favor = 20 }, -- Sealed Journeyman Crate, uncommon
    [248772] = { favor = 30 }, -- Sealed Expert Crate, uncommon
    [248773] = { favor = 40 }, -- Sealed Artisan Crate, uncommon
    [248774] = {}, -- Sealed Elite Crate, uncommon
    [248775] = {}, -- Sealed Apprentice Crate, rare
    [248776] = {}, -- Sealed Journeyman Crate, rare
    [248777] = {}, -- Sealed Expert Crate, rare
    [248778] = {}, -- Sealed Artisan Crate, rare
    [248779] = {}, -- Sealed Elite Crate, rare
}
