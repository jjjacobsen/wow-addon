local _, addon = ...

-- Forever only, checked 2026-11-18, client build 1.60.1.70938.
-- Objectives and base reputation: Data from Efficient Games (https://efficient.games), CC BY 4.0
-- https://github.com/JIVESCORP/eg-link-output-wowf/blob/main/data/wowf/1.60.1.70938/quests.enUS.json
-- All 150 writ IDs, ranks, quest links, requested item names and quantities checked against:
-- https://nether.wowhead.com/forever/tooltip/item/<itemID>
-- https://nether.wowhead.com/forever/tooltip/quest/<questID>
-- Base rewards 75/125/200, Alliance/Horde affiliation, not racial or other bonuses:
-- https://www.wowhead.com/forever/guide/professions/craftsmans-writs-overview-recipes-rewards
-- https://www.wowhead.com/forever/faction=2586/azeroth-commerce-authority
-- https://www.wowhead.com/forever/faction=2587/durotar-supply-and-logistics
-- Each requirements entry is { itemID, quantity }, all required for ONE writ.
-- unpriced: random-enchantment gear has no verified exact variant to price.
-- Never merge its suffix/bonus keys or treat an imaginary unsuffixed item as auctionable.
-- Sealed envelopes choose an unknown order, so they are not included.

addon.CraftsmanWritFactions = {
    Alliance = { id = 2586, name = "Azeroth Commerce Authority" },
    Horde = { id = 2587, name = "Durotar Supply and Logistics" },
}

addon.CraftsmanWritsData = {
    [264011] = { reputation = 75, requirements = { { 3391, 1 } } }, -- Elixir of Ogre's Strength, quest 94004
    [264012] = { reputation = 75, requirements = { { 3383, 1 } } }, -- Elixir of Wisdom, quest 94212
    [264013] = { reputation = 75, requirements = { { 3385, 1 } } }, -- Lesser Mana Potion, quest 94213
    [264014] = { reputation = 75, requirements = { { 6048, 1 } } }, -- Shadow Protection Potion, quest 94214
    [264015] = { reputation = 75, requirements = { { 5634, 1 } } }, -- Free Action Potion, quest 94215
    [264016] = { reputation = 75, requirements = { { 3390, 1 } } }, -- Elixir of Lesser Agility, quest 94216
    [264017] = { reputation = 75, requirements = { { 3388, 1 } } }, -- Lesser Troll's Blood Elixir, quest 94217
    [264018] = { reputation = 75, requirements = { { 8951, 1 } } }, -- Elixir of Defense, quest 94218
    [264019] = { reputation = 75, requirements = { { 5996, 1 } } }, -- Draught of Water Breathing, quest 94219
    [264020] = { reputation = 75, requirements = { { 5540, 1 } } }, -- Pearl-Handled Dagger, quest 94220
    [264021] = { reputation = 75, requirements = { { 11128, 1 } } }, -- Golden Rod, quest 94221
    [264022] = { reputation = 75, requirements = { { 5541, 1 } } }, -- Iridescent Hammer, quest 94222
    [264023] = { reputation = 75, requirements = { { 15869, 1 } } }, -- Silver Skeleton Key, quest 94223
    [264024] = { reputation = 75, requirements = { { 3491, 1 } } }, -- Heavy Bronze Mace, quest 94224
    [264025] = { reputation = 75, requirements = { { 2865, 1 } } }, -- Rough Bronze Leggings, quest 94225
    [264026] = { reputation = 75, requirements = { { 3485, 1 } } }, -- Green Iron Gauntlets, quest 94226
    [264027] = { reputation = 75, requirements = { { 3848, 1 } } }, -- Big Bronze Knife, quest 94227
    [264028] = { reputation = 75, requirements = { { 3484, 1 } } }, -- Green Iron Boots, quest 94228
    [264029] = { reputation = 75, requirements = { { 5507, 1 } } }, -- Ornate Spyglass, quest 94229
    [264030] = { reputation = 75, requirements = { { 4384, 1 } } }, -- Explosive Sheep, quest 94230
    [264031] = { reputation = 75, requirements = { { 4383, 1 } } }, -- Moonsight Rifle, quest 94231
    [264032] = { reputation = 75, requirements = { { 4381, 1 } } }, -- Minor Recombobulator, quest 94232
    [264033] = { reputation = 75, requirements = { { 6712, 1 } } }, -- Practice Lock, quest 94233
    [264034] = { reputation = 75, requirements = { { 4373, 1 } } }, -- Shadow Goggles, quest 94234
    [264035] = { reputation = 75, requirements = { { 7506, 1 } } }, -- Gnomish Universal Remote, quest 94235
    [264036] = { reputation = 75, requirements = { { 4380, 1 } } }, -- Big Bronze Bomb, quest 94236
    [264037] = { reputation = 75, requirements = { { 8069, 200 } } }, -- Crafted Solid Shot, quest 94237
    [264038] = { reputation = 75, requirements = { { 18662, 1 } } }, -- Heavy Leather Ball, quest 94238
    [264039] = { reputation = 75, requirements = { { 5958, 1 } } }, -- Fine Leather Pants, quest 94239
    [264040] = { reputation = 75, requirements = { { 7349, 1 } } }, -- Herbalist's Gloves, quest 94240
    [264041] = { reputation = 75, requirements = { { 2317, 1 } } }, -- Dark Leather Tunic, quest 94241
    [264042] = { reputation = 75, requirements = { { 7358, 1 } } }, -- Pilferer's Gloves, quest 94242
    [264043] = { reputation = 75, requirements = { { 7371, 1 } } }, -- Heavy Quiver, quest 94243
    [264044] = { reputation = 75, requirements = { { 4252, 1 } } }, -- Dark Leather Shoulders, quest 94244
    [264045] = { reputation = 75, requirements = { { 4254, 1 } } }, -- Barbaric Gloves, quest 94245
    [264046] = { reputation = 75, requirements = { { 7284, 1 } } }, -- Red Whelp Gloves, quest 94246
    [264047] = { reputation = 75, requirements = { { 5766, 1 } } }, -- Lesser Wizard's Robe, quest 94247
    [264048] = { reputation = 75, requirements = { { 6263, 1 } } }, -- Blue Overalls, quest 94248
    [264049] = { reputation = 75, requirements = { { 7048, 1 } } }, -- Azure Silk Hood, quest 94249
    [264050] = { reputation = 75, requirements = { { 4245, 1 } } }, -- Small Silk Pack, quest 94250
    [264051] = { reputation = 75, requirements = { { 4317, 1 } } }, -- Phoenix Pants, quest 94251
    [264052] = { reputation = 75, requirements = { { 4313, 1 } } }, -- Red Woolen Boots, quest 94252
    [264053] = { reputation = 75, requirements = { { 10048, 1 } } }, -- Colorful Kilt, quest 94253
    [264054] = { reputation = 75, requirements = { { 6264, 1 } } }, -- Greater Adept's Robe, quest 94254
    [264055] = { reputation = 75, requirements = { { 4321, 1 } } }, -- Spider Silk Slippers, quest 94255
    [264056] = { reputation = 125, requirements = { { 6050, 1 } } }, -- Frost Protection Potion, quest 94256
    [264057] = { reputation = 125, requirements = { { 3823, 1 } } }, -- Lesser Invisibility Potion, quest 94257
    [264058] = { reputation = 125, requirements = { { 4623, 1 } } }, -- Lesser Stoneshield Potion, quest 94258
    [264059] = { reputation = 125, requirements = { { 6052, 1 } } }, -- Nature Protection Potion, quest 94259
    [264060] = { reputation = 125, requirements = { { 10592, 1 } } }, -- Catseye Draught, quest 94260
    [264061] = { reputation = 125, requirements = { { 5633, 1 } } }, -- Great Rage Potion, quest 94261
    [264062] = { reputation = 125, requirements = { { 3827, 1 } } }, -- Mana Potion, quest 94262
    [264063] = { reputation = 125, requirements = { { 6049, 1 } } }, -- Fire Protection Potion, quest 94263
    [264064] = { reputation = 125, requirements = { { 3824, 1 } } }, -- Shadow Oil, quest 94264
    [264065] = { reputation = 125, requirements = { { 9061, 1 } } }, -- Goblin Rocket Fuel, quest 94265
    [264066] = { reputation = 125, requirements = { { 8949, 1 } } }, -- Elixir of Agility, quest 94266
    [264067] = { reputation = 125, requirements = { { 9144, 1 } } }, -- Wildvine Potion, quest 94267
    [264068] = { reputation = 125, requirements = { { 7922, 1 } } }, -- Steel Plate Helm, quest 94268
    [264069] = { reputation = 125, requirements = { { 9060, 1 } } }, -- Inlaid Mithril Cylinder, quest 94269
    [264070] = { reputation = 125, requirements = { { 6041, 1 } } }, -- Steel Weapon Chain, quest 94270
    [264071] = { reputation = 125, requirements = { { 7928, 1 } } }, -- Ornate Mithril Shoulders, quest 94271
    [264072] = { reputation = 125, requirements = { { 7942, 1 } } }, -- Blue Glittering Axe, quest 94272
    [264073] = { reputation = 125, requirements = { { 3853, 1 } } }, -- Moonsteel Broadsword, quest 94273
    [264074] = { reputation = 125, requirements = { { 3837, 1 } } }, -- Golden Scale Coif, quest 94274
    [264075] = { reputation = 125, requirements = { { 7964, 1 } } }, -- Solid Sharpening Stone, quest 94275
    [264076] = { reputation = 125, requirements = { { 7943, 1 } } }, -- Wicked Mithril Blade, quest 94276
    [264077] = { reputation = 125, requirements = { { 11144, 1 } } }, -- Truesilver Rod, quest 94277
    [264078] = { reputation = 125, requirements = { { 9366, 1 } } }, -- Golden Scale Gauntlets, quest 94278
    [264079] = { reputation = 125, requirements = { { 7941, 1 } } }, -- Heavy Mithril Axe, quest 94279
    [264080] = { reputation = 125, requirements = { { 4396, 1 } } }, -- Mechanical Dragonling, quest 94280
    [264081] = { reputation = 125, requirements = { { 4392, 1 } } }, -- Advanced Target Dummy, quest 94281
    [264082] = { reputation = 125, requirements = { { 4393, 1 } } }, -- Craftsman's Monocle, quest 94282
    [264083] = { reputation = 125, requirements = { { 4395, 1 } } }, -- Goblin Land Mine, quest 94283
    [264084] = { reputation = 125, requirements = { { 10501, 1 } } }, -- Catseye Ultra Goggles, quest 94284
    [264085] = { reputation = 125, requirements = { { 10560, 1 } } }, -- Unstable Trigger, quest 94285
    [264086] = { reputation = 125, requirements = { { 4852, 1 } } }, -- Flash Bomb, quest 94286
    [264087] = { reputation = 125, requirements = { { 10500, 1 } } }, -- Fire Goggles, quest 94287
    [264088] = { reputation = 125, requirements = { { 10514, 1 } } }, -- Mithril Frag Bomb, quest 94288
    [264089] = { reputation = 125, requirements = { { 10498, 1 } } }, -- Gyromatic Micro-Adjuster, quest 94289
    [264090] = { reputation = 125, requirements = { { 11590, 1 } } }, -- Mechanical Repair Kit, quest 94290
    [264091] = { reputation = 125, requirements = { { 16005, 1 } } }, -- Dark Iron Bomb, quest 94291
    [264092] = { reputation = 125, requirements = { { 8174, 1 } } }, -- Comfortable Leather Hat, quest 94292
    [264093] = { reputation = 125, requirements = { { 5965, 1 } } }, -- Guardian Cloak, quest 94293
    [264094] = { reputation = 125, requirements = { { 7378, 1 } } }, -- Dusky Bracers, quest 94294
    [264095] = { reputation = 125, requirements = { { 8214, 1 } }, unpriced = true }, -- Wild Leather Helmet, quest 94295
    [264096] = { reputation = 125, requirements = { { 8210, 1 } }, unpriced = true }, -- Wild Leather Shoulders, quest 94296
    [264097] = { reputation = 125, requirements = { { 8217, 1 } } }, -- Quickdraw Quiver, quest 94297
    [264098] = { reputation = 125, requirements = { { 7391, 1 } } }, -- Swift Boots, quest 94298
    [264099] = { reputation = 125, requirements = { { 8192, 1 } } }, -- Nightscape Shoulders, quest 94299
    [264100] = { reputation = 125, requirements = { { 8201, 1 } } }, -- Big Voodoo Mask, quest 94300
    [264101] = { reputation = 125, requirements = { { 8200, 1 } } }, -- Big Voodoo Robe, quest 94301
    [264102] = { reputation = 125, requirements = { { 8189, 1 } } }, -- Turtle Scale Breastplate, quest 94302
    [264103] = { reputation = 125, requirements = { { 8218, 1 } } }, -- Thick Leather Ammo Pouch, quest 94303
    [264104] = { reputation = 125, requirements = { { 10050, 1 } } }, -- Mageweave Bag, quest 94304
    [264105] = { reputation = 125, requirements = { { 10023, 1 } } }, -- Shadoweave Gloves, quest 94305
    [264106] = { reputation = 125, requirements = { { 7063, 1 } } }, -- Crimson Silk Robe, quest 94306
    [264107] = { reputation = 125, requirements = { { 10004, 1 } } }, -- Shadoweave Robe, quest 94307
    [264108] = { reputation = 125, requirements = { { 22246, 1 } } }, -- Enchanted Mageweave Pouch, quest 94308
    [264109] = { reputation = 125, requirements = { { 4329, 1 } } }, -- Star Belt, quest 94309
    [264110] = { reputation = 125, requirements = { { 9998, 1 } } }, -- Black Mageweave Vest, quest 94310
    [264111] = { reputation = 125, requirements = { { 10009, 1 } } }, -- Red Mageweave Pants, quest 94311
    [264112] = { reputation = 125, requirements = { { 10052, 1 } } }, -- Orange Martial Shirt, quest 94312
    [264113] = { reputation = 125, requirements = { { 10008, 1 } } }, -- White Bandit Mask, quest 94313
    [264114] = { reputation = 125, requirements = { { 10042, 1 } } }, -- Cindercloth Robe, quest 94314
    [264115] = { reputation = 125, requirements = { { 7061, 1 } } }, -- Earthen Silk Belt, quest 94315
    [264116] = { reputation = 200, requirements = { { 9224, 1 } } }, -- Potion of Demonslaying, quest 94316
    [264117] = { reputation = 200, requirements = { { 12190, 1 } } }, -- Dreamless Sleep Potion, quest 94317
    [264118] = { reputation = 200, requirements = { { 13457, 1 } } }, -- Greater Fire Protection Potion, quest 94318
    [264119] = { reputation = 200, requirements = { { 9233, 1 } } }, -- Draught of Detect Demon, quest 94319
    [264120] = { reputation = 200, requirements = { { 9088, 1 } } }, -- Gift of Arthas, quest 94320
    [264121] = { reputation = 200, requirements = { { 13513, 1 } } }, -- Flask of Chromatic Resistance, quest 94321
    [264122] = { reputation = 200, requirements = { { 3387, 1 } } }, -- Limited Invulnerability Potion, quest 94322
    [264123] = { reputation = 200, requirements = { { 18253, 1 } } }, -- Major Rejuvenation Potion, quest 94323
    [264124] = { reputation = 200, requirements = { { 246948, 1 } } }, -- Distilled Firewater, quest 94324
    [264125] = { reputation = 200, requirements = { { 12417, 1 } } }, -- Radiant Circlet, quest 94325
    [264126] = { reputation = 200, requirements = { { 12416, 1 } } }, -- Radiant Belt, quest 94326
    [264127] = { reputation = 200, requirements = { { 7929, 1 } } }, -- Orcish War Leggings, quest 94327
    [264128] = { reputation = 200, requirements = { { 7969, 1 } } }, -- Mithril Spurs, quest 94328
    [264129] = { reputation = 200, requirements = { { 12422, 1 } } }, -- Imperial Plate Chest, quest 94329
    [264130] = { reputation = 200, requirements = { { 20549, 1 } } }, -- Darkrune Gauntlets, quest 94330
    [264131] = { reputation = 200, requirements = { { 12775, 1 } } }, -- Huge Thorium Battleaxe, quest 94331
    [264132] = { reputation = 200, requirements = { { 15872, 1 } } }, -- Arcanite Skeleton Key, quest 94332
    [264133] = { reputation = 200, requirements = { { 7947, 1 } } }, -- Ebon Shiv, quest 94333
    [264134] = { reputation = 200, requirements = { { 16023, 1 } } }, -- Masterwork Target Dummy, quest 94334
    [264135] = { reputation = 200, requirements = { { 10504, 1 } }, unpriced = true }, -- Green Lens, quest 94335
    [264136] = { reputation = 200, requirements = { { 15996, 1 } } }, -- Lifelike Mechanical Toad, quest 94336
    [264137] = { reputation = 200, requirements = { { 18645, 1 } } }, -- Gnomish Alarm-O-Bot, quest 94337
    [264138] = { reputation = 200, requirements = { { 18587, 1 } } }, -- Goblin Jumper Cables XL, quest 94338
    [264139] = { reputation = 200, requirements = { { 18232, 1 } } }, -- Field Repair Bot 74A, quest 94339
    [264140] = { reputation = 200, requirements = { { 18631, 1 } } }, -- Truesilver Transformer, quest 94340
    [264141] = { reputation = 200, requirements = { { 10548, 1 } } }, -- Sniper Scope, quest 94341
    [264142] = { reputation = 200, requirements = { { 21277, 1 } } }, -- Tranquil Mechanical Yeti, quest 94342
    [264143] = { reputation = 200, requirements = { { 15087, 1 } } }, -- Wicked Leather Pants, quest 94343
    [264144] = { reputation = 200, requirements = { { 18258, 1 } } }, -- Gordok Ogre Suit, quest 94344
    [264145] = { reputation = 200, requirements = { { 15053, 1 } } }, -- Volcanic Breastplate, quest 94345
    [264146] = { reputation = 200, requirements = { { 15094, 1 } } }, -- Runic Leather Headband, quest 94346
    [264147] = { reputation = 200, requirements = { { 15084, 1 } } }, -- Wicked Leather Bracers, quest 94347
    [264148] = { reputation = 200, requirements = { { 15075, 1 } } }, -- Chimeric Vest, quest 94348
    [264149] = { reputation = 200, requirements = { { 15080, 1 } } }, -- Heavy Scorpid Helm, quest 94349
    [264150] = { reputation = 200, requirements = { { 15092, 1 } } }, -- Runic Leather Bracers, quest 94350
    [264151] = { reputation = 200, requirements = { { 15071, 1 } } }, -- Frostsaber Boots, quest 94351
    [264152] = { reputation = 200, requirements = { { 14130, 1 } } }, -- Wizardweave Turban, quest 94352
    [264153] = { reputation = 200, requirements = { { 14046, 1 } } }, -- Runecloth Bag, quest 94353
    [264154] = { reputation = 200, requirements = { { 13864, 1 } } }, -- Runecloth Boots, quest 94354
    [264155] = { reputation = 200, requirements = { { 10036, 1 } } }, -- Tuxedo Jacket, quest 94355
    [264156] = { reputation = 200, requirements = { { 14108, 1 } } }, -- Felcloth Boots, quest 94356
    [264157] = { reputation = 200, requirements = { { 22251, 1 } } }, -- Cenarion Herb Bag, quest 94357
    [264158] = { reputation = 200, requirements = { { 10025, 1 } } }, -- Shadoweave Mask, quest 94358
    [264159] = { reputation = 200, requirements = { { 14141, 1 } } }, -- Ghostweave Vest, quest 94359
    [264160] = { reputation = 200, requirements = { { 21340, 1 } } }, -- Soul Pouch, quest 94360
}
