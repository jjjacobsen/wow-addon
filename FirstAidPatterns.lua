local _, addon = ...

-- Forever 1.60.1.70888, recipe spell -> First Aid learning item
-- https://wago.tools/db2/SkillLineAbility/csv?build=1.60.1.70888
-- https://wago.tools/db2/ItemSparse/csv?build=1.60.1.70888
-- https://wago.tools/db2/ItemXItemEffect/csv?build=1.60.1.70888
-- https://wago.tools/db2/ItemEffect/csv?build=1.60.1.70888
-- SkillLineAbility.SkillLine = 129, ItemSparse.RequiredSkill = 129 or child 2942
-- ItemSparse.ID -> ItemXItemEffect.ItemID -> ItemEffect.ID, TriggerType = 6
-- ItemEffect.SpellID must match SkillLineAbility.Spell
-- All 40 First Aid skill entries considered, with 16 verified learning items
-- Conflicting RequiredSkillRank values omitted, never choose the minimum
-- Equal-rank duplicates use the lowest item ID. Requirements come from native tooltips
-- Crystal Infused Bandage (30021) omitted: item 23689 absent from ItemSparse
addon.FirstAid.patterns = {
    [7929] = 16112,
    [7935] = 6454,
    [10840] = 16113,
    [23787] = 19442,
    [470349] = 232434,
    [1244434] = 255723,
    [1244435] = 255725,
    [1244436] = 255729,
    [1259341] = 255728,
    [1259343] = 255724,
    [1259344] = 255727,
    [1259345] = 255731,
    [1259348] = 255726,
    [1259349] = 255730,
    [1262996] = 273105,
    [1263001] = 273118,
}
